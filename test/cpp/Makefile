# project source code
SRCDIR := ../../src/cpp

include $(SRCDIR)/pbi.mk

CXXFLAGS := -O3 -std=c++11 $(INCDIRS) -I $(SRCDIR) \
		    -I $(SRCDIR)/third-party/boost_1_57_0 \
			-I third-party/gtest-1.7.0/include \
			-I third-party/gtest-1.7.0

GTEST_OBJECTS := gtest-all.o gtest_main.o
DAZCON_OBJECTS := $(SRCDIR)/DB.o $(SRCDIR)/align.o $(SRCDIR)/Alignment.o \
			      $(SRCDIR)/DazAlnProvider.o

PBDAGCON_OBJECTS := $(SRCDIR)/AlnGraphBoost.o $(SRCDIR)/Alignment.o \
					$(SRCDIR)/SimpleAligner.o 
vpath %.cc third-party/gtest-1.7.0/src

# Special case, accomodate migration to BAM
ifeq ($(wildcard $(PBBAM)/*),)
LDLIBS = -lpbdata -lblasr -lpthread
else
LDLIBS = -lpbdata -lblasr -lpbbam -lhts -lz -lpthread
endif

BUILDMSG = "=== Building $@ ==="

all : check

check : test_target_hit test_target test_alngraph test_alignment test_simple_aligner

test_target_hit : $(GTEST_OBJECTS) $(DAZCON_OBJECTS) TargetHitTest.o 
	@echo $(BUILDMSG)
	@$(CXX) $^ -o $@ -lpthread
	./$@

test_target : $(GTEST_OBJECTS) $(DAZCON_OBJECTS) TargetTest.o
	@echo $(BUILDMSG)
	@$(CXX) $^ -o $@ -lpthread
	./$@

test_alngraph : $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) AlnGraphBoostTest.o
	@echo $(BUILDMSG)
	@$(CXX) $^ -static -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

test_alignment : $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) AlignmentTest.o
	@echo $(BUILDMSG)
	@$(CXX) $^ -static -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

test_simple_aligner : $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) SimpleAlignerTest.o
	@echo $(BUILDMSG)
	@$(CXX) $^ -static -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

clean :
	$(RM) *.o
	$(RM) test_*
	$(RM) *.log

