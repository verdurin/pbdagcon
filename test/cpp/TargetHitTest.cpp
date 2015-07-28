#include <gtest/gtest.h>
#include <DazAlnProvider.hpp>

TEST(TargetHitTest, single_overlap_perfect) {
    Record rec;
    Overlap ovl;
    rec.ovl = ovl;

    Path path;
    path.abpos = 27;
    path.aepos = 7013;
    path.bbpos = 1231;
    path.bepos = 8217;
    path.diffs = 0;

    rec.ovl.path = path;

    TargetHit th;
    th.add(rec);
    th.computeOvlScore();
    EXPECT_FLOAT_EQ(6986, th.ovlScore);
}

TEST(TargetHitTest, single_overlap_inaccurate) {
    Record rec;
    Overlap ovl;
    rec.ovl = ovl;

    Path path;
    path.abpos = 10;
    path.aepos = 5000;
    path.bbpos = 2000;
    path.bepos = 6000;
    path.diffs = 230;

    rec.ovl.path = path;

    TargetHit th;
    th.add(rec);
    th.computeOvlScore();
    EXPECT_FLOAT_EQ(3770, th.ovlScore);
}

TEST(TargetHitTest, multi_overlap_inaccurate) {
    Record r1;
    Overlap o1;
    r1.ovl = o1;

    Path p1;
    p1.abpos = 10;
    p1.aepos = 5000;
    p1.bbpos = 2000;
    p1.bepos = 6000;
    p1.diffs = 230;
    r1.ovl.path = p1;

    Record r2;
    Overlap o2;
    r2.ovl = o2;

    Path p2;
    p2.abpos = 5005;
    p2.aepos = 7005;
    p2.bbpos = 6001;
    p2.bepos = 7995;
    p2.diffs = 53;
    r2.ovl.path = p2;

    TargetHit th;

    th.add(r1);
    th.computeOvlScore();
    EXPECT_FLOAT_EQ(3770, th.ovlScore);
    th.add(r2);
    th.computeOvlScore();
    EXPECT_FLOAT_EQ(4721, th.ovlScore);
}
