.PHONY: all check test_target_hit test_alngraph test_alignment test_simple_aligner
all:

THISDIR:=$(dir $(lastword ${MAKEFILE_LIST}))
-include ${CURDIR}/../../defines.mk
SRCDIR := ${THISDIR}
VPATH:=${VPATH}:${THISDIR}/../../src/cpp
foo:
	echo ${VPATH}

INCDIRS := . \
	${SRCDIR} \
	${SRCDIR}/../../src/cpp \
	${LIBBLASR_INCLUDE} \
	${LIBPBDATA_INCLUDE} \
	${LIBPBIHDF_INCLUDE} \
	${PBBAM_INCLUDE} \
	${HDF5_INCLUDE} \
	${HTSLIB_INCLUDE} \
	${BOOST_INCLUDE} \
    ${GTEST_INCLUDE} \
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

# For fused-src, gtest-all.cc includes gtest/*.
# For non-fused, gtest-all.cc includes src/gtest-*.
# So we add -I ${GTEST_SRC}/.. for the latter case.
GTEST_CPPFLAGS += -isystem $(GTEST_INCLUDE) -isystem ${GTEST_SRC}/..
GTEST_CXXFLAGS += -g -Wall -Wextra -pthread

CXXFLAGS := -O3 -std=c++11

GTEST_OBJECTS := gtest-all.o gtest_main.o
DAZCON_OBJECTS := DB.o align.o Alignment.o \
			      DazAlnProvider.o

PBDAGCON_OBJECTS := AlnGraphBoost.o Alignment.o \
					SimpleAligner.o 
LD_LIBRARY_PATH+=${LIBBLASR_LIB}:${LIBPBDATA_LIB}:${LIBPBIHDF_LIB}:${PBBAM_LIB}:${HDF5_LIB}:${HTSLIB_LIB}:${ZLIB_LIB}
export LD_LIBRARY_PATH

vpath %.cc $(GTEST_SRC)

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
	$(CXX) $^ -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

test_alignment: $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) AlignmentTest.o
	@echo $(BUILDMSG)
	$(CXX) $^ -o $@ $(LDFLAGS) $(LDLIBS)
	# This needs basic.m5 from this directory.
	cd ${THISDIR} && ./$@

test_simple_aligner: $(GTEST_OBJECTS) $(PBDAGCON_OBJECTS) SimpleAlignerTest.o
	@echo $(BUILDMSG)
	$(CXX) $^ -o $@ $(LDFLAGS) $(LDLIBS)
	./$@

$(SRCDIR)/AlnGraphBoost.o:

$(GTEST_OBJECTS):
	$(CXX) $(GTEST_CPPFLAGS) $(GTEST_CXXFLAGS) -c ${GTEST_SRC}/$(@:.o=.cc)

clean:
	$(RM) $(SRCDIR)/*.o
	$(RM) *.o
	$(RM) test_*
