#include <gtest/gtest.h>
#include <DazAlnProvider.hpp>

TEST(TargetHitTest, add_record) {
    Record r1, r2, r3;
    Overlap o1, o2, o3;

    o1.aread = 1; o1.bread = 3; o1.flags = 0;
    o2.aread = 1; o2.bread = 3; o2.flags = 0;
    o3.aread = 2; o3.bread = 3; o3.flags = 1;
     
    r1.ovl = o1;
    r2.ovl = o2;
    r3.ovl = o3;
    
    Target t;
    t.addRecord(r1);
    t.addRecord(r2);
    t.addRecord(r3);

    EXPECT_EQ(2, t.hits.size());
}
