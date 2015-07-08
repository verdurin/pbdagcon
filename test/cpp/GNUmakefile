.PHONY: all check test_target_hit test_alngraph test_alignment test_simple_aligner
all:

override PBDAGCON_ROOT:=../..
SRCDIR := ${PBDAGCON_ROOT}/src/cpp

include ../../defines.mk


INCDIRS := . \
	${SRCDIR} \
	${LIBBLASR_INCLUDE} \
	${LIBPBDATA_INCLUDE} \
	${LIBPBIHDF_INCLUDE} \
	${PBBAM_INCLUDE} \
	${HDF5_INCLUDE} \
	${HTSLIB_INCLUDE} \
	${BOOST_INCLUDE} \
    ${GTEST_DIR}/include \
	third-party

LIBDIRS := \
	${LIBBLASR_LIB} \
	${LIBPBDATA_LIB} \
	${LIBPBIHDF_LIB} \
	${PBBAM_LIB} \
	${HDF5_LIB} \
	${HTSLIB_LIB} \
	${ZLIB_LIB}

PTHREAD_LIBFLAGS:=-lpthread
LDLIBS+= \
	${LIBBLASR_LIBFLAGS} \
	${LIBPBDATA_LIBFLAGS} \
	${LIBPBIHDF_LIBFLAGS} \
	${PBBAM_LIBFLAGS} \
	${HDF5_LIBFLAGS} \
	${HTSLIB_LIBFLAGS} \
	${ZLIB_LIBFLAGS} \
	${PTHREAD_LIBFLAGS} \
	${DL_LIBFLAGS}
CPPFLAGS+=$(patsubst %,-I%,${INCDIRS})
LDFLAGS+=$(patsubst %,-L %,${LIBDIRS})

GTEST_CPPFLAGS += -isystem $(GTEST_DIR)/include -isystem ${GTEST_DIR}
GTEST_CXXFLAGS += -g -Wall -Wextra -pthread

CXXFLAGS := -O3 -std=c++11

GTEST_OBJECTS := gtest-all.o gtest_main.o
DAZCON_OBJECTS := $(SRCDIR)/DB.o $(SRCDIR)/align.o $(SRCDIR)/Alignment.o \
			      $(SRCDIR)/DazAlnProvider.o

PBDAGCON_OBJECTS := $(SRCDIR)/AlnGraphBoost.o $(SRCDIR)/Alignment.o \
					$(SRCDIR)/SimpleAligner.o 
vpath %.cc $(GTEST_DIR)/src

BUILDMSG = "=== Building $@ ==="

all:
	$(MAKE) check

check: test_target_hit test_alngraph test_alignment test_simple_aligner

# XXX: need to mock out db_ in order to run test_target

test_target_hit: $(GTEST_OBJECTS) $(DAZCON_OBJECTS) TargetHitTest.o 
	@echo $(BUILDMSG)
	$(CXX) $^ -o $@ -lpthread
	./$@

test_target: $(GTEST_OBJECTS) $(DAZCON_OBJECTS) TargetTest.o
	@echo $(BUILDMSG)
	$(CXX) $^ -o $@ -lpthread
	./$@

test_alngraph: $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) AlnGraphBoostTest.o
	@echo $(BUILDMSG)
	$(CXX) $^ -static -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

test_alignment: $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) AlignmentTest.o
	@echo $(BUILDMSG)
	$(CXX) $^ -static -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

test_simple_aligner: $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) SimpleAlignerTest.o
	@echo $(BUILDMSG)
	$(CXX) $^ -static -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

$(SRCDIR)/AlnGraphBoost.o:

$(GTEST_OBJECTS):
	$(CXX) $(GTEST_CPPFLAGS) $(GTEST_CXXFLAGS) -c ${GTEST_DIR}/src/$(@:.o=.cc)

clean:
	$(RM) $(SRCDIR)/*.o
	$(RM) *.o
	$(RM) test_*
