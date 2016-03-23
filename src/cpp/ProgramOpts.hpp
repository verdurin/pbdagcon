#pragma once

#include <string>
#include <set>

// Normalizing *slightly* difference cmd line interfaces between pbdagcon and
// dazcon.  May unify someday ...
struct ProgramOpts {
    // Common to both pbdagcon and dazcon
    /// Minimum alignment coverage for consensus
    size_t minCov;
    /// Minimum consensus length to output
    size_t minLen;
    /// Amount to trim alignments by on either side.
    unsigned int trim;
    /// Number of threads to use
    int threads;

    // Specific to pbdagcon
    bool align;
    std::string input;

    // Specific to dazcon
    /// Path to the alignment file
    std::string alnFile;
    /// Path to the sequence file
    std::string seqFile;
    /// Maximimum number of hits to include in correction
    unsigned int maxHits;
    /// Sort hits by coverage score
    bool sortCov;
    /// Use only proper overlaps for correction
    bool properOvls;
    /// Limit correction to these targets
    std::set<int> targets;
};
