// Copyright (c) 2011-2015, Pacific Biosciences of California, Inc.
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted (subject to the limitations in the
// disclaimer below) provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following
// disclaimer in the documentation and/or other materials provided
// with the distribution.
//
// * Neither the name of Pacific Biosciences nor the names of its
// contributors may be used to endorse or promote products derived
// from this software without specific prior written permission.
//
// NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
// GRANTED BY THIS LICENSE. THIS SOFTWARE IS PROVIDED BY PACIFIC
// BIOSCIENCES AND ITS CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL PACIFIC BIOSCIENCES OR ITS
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
// USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.


#include <cstdint>
#include <cassert>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <boost/format.hpp>
#include <thread>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graphviz.hpp>

#define ELPP_CUSTOM_COUT std::cerr
#define ELPP_THREAD_SAFE 1
#include "easylogging++.h"
#include "tclap/CmdLine.h"
#include "Alignment.hpp"
#include "AlnGraphBoost.hpp"
#include "BlasrM5AlnProvider.hpp"
#include "BoundedBuffer.hpp"
#include "tuples/TupleMetrics.hpp"
#include "SimpleAligner.hpp"
#include "ProgramOpts.hpp"

INITIALIZE_EASYLOGGINGPP

ProgramOpts popts;

bool AlignFirst = false;

typedef std::vector<dagcon::Alignment> AlnVec;
typedef BoundedBuffer<AlnVec> AlnBuf;
typedef BoundedBuffer<std::string> CnsBuf;

class Reader {
    AlnBuf* alnBuf_;
    const std::string fpath_;
    size_t minCov_;
    int nCnsThreads_;
public:
    Reader(AlnBuf* b, const std::string fpath, size_t minCov) : 
        alnBuf_(b), 
        fpath_(fpath),
        minCov_(minCov)
    { }

    void setNumCnsThreads(int n) {
        nCnsThreads_ = n;
    }

    void operator()() {
        el::Logger* logger = el::Loggers::getLogger("Reader");
        try {
            AlnProvider* ap;
            if (fpath_ == "-") { 
                ap = new BlasrM5AlnProvider(&std::cin);
            } else {
                ap = new BlasrM5AlnProvider(fpath_);
            }
            AlnVec alns;
            bool hasNext = true;
            while (hasNext) {
                hasNext = ap->nextTarget(alns);
                size_t cov = alns.size();
                if (cov == 0) continue;
                if (cov < minCov_) {
                    logger->debug("Coverage requirement not met for %v, coverage: %v", 
                        alns[0].id, alns.size());
                    continue;
                }
                boost::format msg("Consensus candidate: %s");
                msg % alns[0].id;
                logger->debug(msg.str());
                alnBuf_->push(alns);
            }
        } 
        catch (M5Exception::FileOpenError) {
            logger->error("Error opening file: %s", fpath_);
        }
        catch (M5Exception::FormatError err) {
            logger->error("Format error. Input: %s, Error: %s", 
                fpath_, err.msg);
        }
        catch (M5Exception::SortError err) {
            logger->error("Input file is not sorted by either target or query.");
        }

        // write out sentinals, one per consensus thread
        AlnVec sentinel;
        for (int i=0; i < nCnsThreads_; i++)
            alnBuf_->push(sentinel);
    }
};

class Consensus {
    AlnBuf* alnBuf_;
    CnsBuf* cnsBuf_;
    size_t minLen_;
    int minWeight_;
    SimpleAligner aligner;
public:
    Consensus(AlnBuf* ab, CnsBuf* cb, size_t minLen, int minWeight) : 
        alnBuf_(ab), 
        cnsBuf_(cb),
        minLen_(minLen),
        minWeight_(minWeight)
    { }

    void operator()() {
        el::Logger* logger = el::Loggers::getLogger("Consensus");
        AlnVec alns;
        alnBuf_->pop(&alns);
        std::vector<CnsResult> seqs;

        while (alns.size() > 0) {
            if (alns.size() < popts.minCov) {
                alnBuf_->pop(&alns);
                continue;
            }
            boost::format msg("Consensus calling: %s Alignments: %d");
            msg % alns[0].id;
            msg % alns.size();
            logger->info(msg.str());

            if (AlignFirst) 
                for_each(alns.begin(), alns.end(), aligner); 

            AlnGraphBoost ag(alns[0].tlen);
            for (auto it = alns.begin(); it != alns.end(); ++it) {
                if (it->qstr.length() < minLen_) continue;
                dagcon::Alignment aln = normalizeGaps(*it);
                trimAln(aln, popts.trim);
                ag.addAln(aln);
            }
            ag.mergeNodes();
            ag.consensus(seqs, minWeight_, minLen_);
            for (auto it = seqs.begin(); it != seqs.end(); ++it) {
                CnsResult result = *it;
                boost::format fasta(">%s/%d_%d\n%s\n");
                fasta % alns[0].id % result.range[0] % result.range[1];
                fasta % result.seq;
                cnsBuf_->push(fasta.str()); 
            }

            alnBuf_->pop(&alns);
        }
        // write out a sentinal
        cnsBuf_->push("");
    }
};

class Writer {
    CnsBuf* cnsBuf_;
    int nCnsThreads_;
public:
    Writer(CnsBuf* cb) : cnsBuf_(cb) {}
    
    void setNumCnsThreads(int n) {
        nCnsThreads_ = n;
    }

    void operator()() {
        std::string cns;
        cnsBuf_->pop(&cns);
        int sentinelCount = 0;
        while (true) {
            std::cout << cns;
            if (cns == "" && ++sentinelCount == nCnsThreads_) 
                break;

            cnsBuf_->pop(&cns);
        }
    }
};

void parseArgs(int argc, char **argv) {

    try {
        TCLAP::CmdLine cmd("PBI consensus module", ' ', "0.3");
        TCLAP::ValueArg<int> threadArg(
            "j","threads",                 // short, long name
            "Number of consensus threads", // description
             false, 4,                     // required, default
             "int", cmd);

        TCLAP::ValueArg<unsigned int> minCovArg(
            "c","min-coverage",
            "Minimum coverage for correction",
            false, 6, "uint", cmd);

        TCLAP::ValueArg<unsigned int> minLenArg(
            "m","min-length",
            "Minimum length for correction",
            false, 500, "uint", cmd);

        TCLAP::ValueArg<unsigned int> trimArg(
            "t","trim",
            "Trim alignments on either size",
            false, 50, "uint", cmd);

        TCLAP::SwitchArg alignArg("a","align",
            "Align sequences before adding to consensus", cmd, false);

        TCLAP::SwitchArg verboseArg("v","verbose",
            "Turns on verbose logging", cmd, false);

        TCLAP::UnlabeledValueArg<std::string> inputArg(
            "input", "Input data", 
            true, "-","either file path or stdin", cmd);

        cmd.parse(argc, argv);
    
        popts.minCov  = minCovArg.getValue();
        popts.minLen  = minLenArg.getValue();
        popts.trim    = trimArg.getValue();
        popts.threads = threadArg.getValue();
        popts.align   = alignArg.getValue();
        popts.input   = inputArg.getValue();
    } catch (TCLAP::ArgException& e) {
        std::cerr << "Error " << e.argId() << ": " << e.error() << std::endl;
        exit(1);
    }
}

int main(int argc, char* argv[]) {
    START_EASYLOGGINGPP(argc, argv);
    parseArgs(argc, argv);

    el::Logger* logger = el::Loggers::getLogger("default");

    if (popts.align) {
        dagcon::Alignment::parse = parsePre;
        AlignFirst = true;
    }

    AlnBuf alnBuf(30);
    CnsBuf cnsBuf(30);

    if (popts.threads > 1) {
        logger->info("Multi-threaded. Input: %v, Threads: %v", 
            popts.input, popts.threads);
    
        Writer writer(&cnsBuf);
        writer.setNumCnsThreads(popts.threads);
        std::thread writerThread(writer);

        std::vector<std::thread> cnsThreads;
        for (int i=0; i < popts.threads; i++) {
            Consensus c(&alnBuf, &cnsBuf, popts.minLen, popts.minCov);
            cnsThreads.push_back(std::thread(c));
        }

        Reader reader(&alnBuf, popts.input, popts.minCov);
        reader.setNumCnsThreads(popts.threads);
        std::thread readerThread(reader);

        writerThread.join();
        std::vector<std::thread>::iterator it;
        for (it = cnsThreads.begin(); it != cnsThreads.end(); ++it)
            it->join();
    
        readerThread.join();
    } else {
        logger->info("Single-threaded. Input: %v", popts.input);
        Reader reader(&alnBuf, popts.input, popts.minCov);
        reader.setNumCnsThreads(1);
        Consensus cns(&alnBuf, &cnsBuf, popts.minLen, popts.minCov);
        Writer writer(&cnsBuf);
        writer.setNumCnsThreads(1);
        reader();
        cns();
        writer();
    }
        
    return 0;
}
