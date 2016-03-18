#include <cstdlib>
#include <iostream>
#include <fstream>
#include <string>
#include <gtest/gtest.h>
#include <boost/graph/adjacency_list.hpp>
#include "Alignment.hpp"

using namespace dagcon;

std::string dataDir() {
    char const* val = getenv("PBDAGCON_TEST_DATA_DIR");
    if (!val || !*val) {
        return ".";
    }
    return val;
}

TEST(Alignment, Normalize) {
    Alignment a, b;
    a.start = 1;

    // test mismatch
    b.qstr = "CAC";
    b.tstr = "CGC";
    b = normalizeGaps(b);
    EXPECT_EQ("C-AC", b.qstr);
    EXPECT_EQ("CG-C", b.tstr);

    // test shifting gaps on read
    b.qstr = "-C--CGT";
    b.tstr = "CCGAC-T";
    b = normalizeGaps(b);
    EXPECT_EQ("CCG--T", b.qstr);
    EXPECT_EQ("CCGACT", b.tstr);

    // another gap reference push
    a.tstr = "ATATTA---GGC";
    a.qstr = "ATAT-AGCCGGC";

    b = a;
    b = normalizeGaps(b);
    // query remains unchanged
    EXPECT_EQ(a.qstr, b.qstr);
    // target shifts the G bases to the left
    EXPECT_EQ("ATATTAG--G-C", b.tstr);
}

TEST(Alignment, ParseBasic) {
    std::string fn = dataDir() + "basic.m5";
    std::ifstream file(fn.c_str());
    ASSERT_TRUE(file.good());
    Alignment aln;
    file >> aln;
    EXPECT_EQ(1, aln.start);
    EXPECT_EQ("CAC", aln.qstr);
    EXPECT_EQ("CGC", aln.tstr);

    file >> aln;
    EXPECT_EQ(1, aln.start);
    EXPECT_EQ("AATTGGCC", aln.qstr);
    EXPECT_EQ("GGCCAATT", aln.tstr);
}

TEST(Alignment, ParseQuery) {
    std::string fn = dataDir() + "parsequery.m5";
    std::ifstream file(fn.c_str());
    ASSERT_TRUE(file.good());
    Alignment aln;
    Alignment::groupByTarget = false;
    file >> aln;
    EXPECT_EQ("m130110_062238_00114_c100480560100000001823075906281381_s1_p0/311/1102_3151",
              aln.id);
    EXPECT_EQ(2049, aln.tlen);
    EXPECT_EQ(8, aln.start);
    EXPECT_EQ("CTGCATGCT", aln.tstr.substr(0,9));
    EXPECT_EQ("CTGCA--CT", aln.qstr.substr(0,9));
}

TEST(Alignment, Trim) {
  std::string const t = "ACG-TCA-GCA";
  std::string const q = "AC-C-C-T---";
  {
    dagcon::Alignment aln;
    aln.tstr = t;
    aln.qstr = q;
    aln.start = 1;
    aln.strand = '-';

    trimAln(aln, 0);
    EXPECT_EQ(1, aln.start);
    EXPECT_EQ(t, aln.tstr);
    EXPECT_EQ(q, aln.qstr);
  }
  {
    dagcon::Alignment aln;
    aln.tstr = t;
    aln.qstr = q;
    aln.start = 1;
    aln.strand = '-';

    trimAln(aln, 3);
    EXPECT_EQ(4, aln.start);
    EXPECT_EQ("-TCA-", aln.tstr);
    EXPECT_EQ("C-C-T", aln.qstr);
  }
  {
    dagcon::Alignment aln;
    aln.tstr = t;
    aln.qstr = q;
    aln.start = 1;
    aln.strand = '-';

    trimAln(aln, 4);
    EXPECT_EQ(5, aln.start);
    EXPECT_EQ("C", aln.tstr);
    EXPECT_EQ("C", aln.qstr);
  }
  {
    dagcon::Alignment aln;
    aln.tstr = t;
    aln.qstr = q;
    aln.start = 1;
    aln.strand = '-';

    trimAln(aln, 5);
    EXPECT_EQ(6, aln.start);
    EXPECT_EQ("", aln.tstr);
    EXPECT_EQ("", aln.qstr);
  }
  {
    dagcon::Alignment aln;
    aln.tstr = t;
    aln.qstr = q;
    aln.start = 1;
    aln.strand = '-';

    trimAln(aln, 500);
    // EXPECT_EQ(1 + 9, aln.start); // start could be anything, really
    EXPECT_EQ("", aln.tstr);
    EXPECT_EQ("", aln.qstr);
  }
}
