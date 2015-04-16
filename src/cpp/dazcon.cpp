
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
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <thread>
#include <boost/format.hpp>
#include <boost/graph/graph_traits.hpp>
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/graphviz.hpp>

#define ELPP_CUSTOM_COUT std::cerr
#define ELPP_THREAD_SAFE 1
#include "easylogging++.h"
#include "tclap/CmdLine.h"
#include "ProgramOpts.hpp"
#include "Alignment.hpp"
#include "AlnGraphBoost.hpp"
#include "DazAlnProvider.hpp"
#include "BoundedBuffer.hpp"

INITIALIZE_EASYLOGGINGPP

ProgramOpts popts;

typedef std::vector<dagcon::Alignment> AlnVec;

struct TargetData {
    std::string targSeq;
    AlnVec alns;
};

typedef BoundedBuffer<TargetData> TrgBuf;
typedef BoundedBuffer<std::string> CnsBuf;

void Reader(TrgBuf& trgBuf, AlnProvider* ap) {
    try {
        TargetData td;
        bool hasNext = true;
        do {
            hasNext = ap->nextTarget(td.targSeq, td.alns);
            //for (auto& aln : td.alns)
            //    std::cerr << aln;
            if (! td.alns.empty())
                trgBuf.push(td);
        } while (hasNext);
    } 
    catch (PacBio::DagCon::IOException& e) {
        std::cerr << e.what();
        exit(1);
    }

    // write out sentinals, one per consensus thread
    TargetData sentinel;
    for (int i=0; i < popts.threads; i++)
        trgBuf.push(sentinel);
}

void Consensus(int id, TrgBuf& trgBuf, CnsBuf& cnsBuf) {
    TargetData td;
    trgBuf.pop(&td);
    std::vector<CnsResult> seqs;
    el::Loggers::getLogger("Consensus");

    while (td.alns.size() > 0) {
        if (td.alns.size() < popts.minCov) {
            trgBuf.pop(&td);
            continue;
        }
        boost::format msg("(%d) calling: %s Alignments: %d");
        CLOG(INFO, "Consensus") << msg % id % td.alns[0].id % td.alns.size();

        AlnGraphBoost ag(td.targSeq);
        AlnVec alns = td.alns; 
        for (auto it = alns.begin(); it != alns.end(); ++it) {
            if (it->qstr.length() < popts.minLen) continue;
            dagcon::Alignment aln = normalizeGaps(*it);
            // XXX: Shouldn't be needed for dazcon, but causes some infinite 
            // loops in the current consensus code.
            trimAln(aln, popts.trim);
            ag.addAln(aln);
        }
        CVLOG(3, "Consensus") << "Merging nodes";
        ag.mergeNodes();
        CVLOG(3, "Consensus") << "Generating consensus";
        ag.consensus(seqs, popts.minCov, popts.minLen);
        for (auto it = seqs.begin(); it != seqs.end(); ++it) {
            CnsResult result = *it;
            boost::format fasta(">%s/%d_%d\n%s\n");
            fasta % alns[0].id % result.range[0] % result.range[1];
            fasta % result.seq;
            cnsBuf.push(fasta.str()); 
        }
        trgBuf.pop(&td);
    }
    boost::format msg("(%d) ending ...");
    CLOG(INFO, "Consensus") << msg % id;
    // write out a sentinal
    cnsBuf.push("");
}

void Writer(CnsBuf& cnsBuf) {
    std::string cns;
    cnsBuf.pop(&cns);
    int sentinelCount = 0;
    while (true) {
        std::cout << cns;
        if (cns == "" && ++sentinelCount == popts.threads) 
            break;

        cnsBuf.pop(&cns);
    }
}

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
            "l","min-len",
            "Minimum length for correction",
            false, 500, "uint", cmd);

        TCLAP::ValueArg<unsigned int> trimArg(
            "t","trim",
            "Trim alignments on either size",
            false, 10, "uint", cmd);

        TCLAP::ValueArg<std::string> alnFileArg(
            "a","align-file",
            "Path to the alignments file",
            true,"","string", cmd);

        TCLAP::ValueArg<std::string> seqFileArg(
            "s","seq-file",
            "Path to the sequences file",
            true,"","string", cmd);

        TCLAP::ValueArg<unsigned int> maxHitArg(
            "m","max-hit",
            "Maximum number of hits to pass to consensus",
            false,85,"uint", cmd);

        TCLAP::SwitchArg sortCovArg("x","coverage-sort",
            "Sort hits by coverage", cmd, false);

        TCLAP::SwitchArg properOvlArg("o","only-proper-overlaps",
            "Use only 'proper overlaps', i.e., align to the ends", cmd, false);

        TCLAP::SwitchArg verboseArg("v","verbose",
            "Turns on verbose logging", cmd, false);

        TCLAP::UnlabeledMultiArg<int> targetArgs(
            "targets", "Limit consensus to list of target ids", 
            false, "list of ints", cmd);

        cmd.parse(argc, argv);
    
        popts.minCov     = minCovArg.getValue();
        popts.minLen     = minLenArg.getValue();
        popts.trim       = trimArg.getValue();
        popts.alnFile    = alnFileArg.getValue();
        popts.seqFile    = seqFileArg.getValue();
        popts.threads    = threadArg.getValue();
        popts.maxHits    = maxHitArg.getValue();
        popts.sortCov    = sortCovArg.getValue();
        popts.properOvls = properOvlArg.getValue();
        std::vector<int> tgs = targetArgs.getValue();
        popts.targets.insert(tgs.begin(), tgs.end());
    } catch (TCLAP::ArgException& e) {
        std::cerr << "Error " << e.argId() << ": " << e.error() << std::endl;
        exit(1);
    }
}

int main(int argc, char* argv[]) {

    START_EASYLOGGINGPP(argc, argv);
    parseArgs(argc, argv);

    LOG(INFO) << "Initializing alignment provider";
    DazAlnProvider* ap;
    ap = new DazAlnProvider(popts);
    TrgBuf trgBuf(20);
    CnsBuf cnsBuf(10);

    std::thread writerThread(Writer, std::ref(cnsBuf));

    std::vector<std::thread> cnsThreads;
    for (int i=0; i < popts.threads; i++) {
        std::thread ct(Consensus, i, std::ref(trgBuf), std::ref(cnsBuf));
        cnsThreads.push_back(std::move(ct));
    }
   
    std::thread readerThread(Reader, std::ref(trgBuf), ap);

    writerThread.join();

    std::vector<std::thread>::iterator it;
    for (it = cnsThreads.begin(); it != cnsThreads.end(); ++it)
        it->join();

    readerThread.join();

    delete ap;

    return 0;
}
