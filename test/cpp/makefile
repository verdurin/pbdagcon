.PHONY: all check test_target_hit test_alngraph test_alignment test_simple_aligner
all:

THISDIR:=$(dir $(lastword ${MAKEFILE_LIST}))
-include ${CURDIR}/../../defines.mk
SRCDIR := ${THISDIR}

INCDIRS := . \
	${SRCDIR} \
	${SRCDIR}/../../src/cpp \
	${DAZZ_DB_INCLUDE} \
	${DALIGNER_INCLUDE} \
	${LIBBLASR_INCLUDE} \
	${LIBPBDATA_INCLUDE} \
	${LIBPBIHDF_INCLUDE} \
	${PBBAM_INCLUDE} \
	${HDF5_INCLUDE} \
	${BOOST_INCLUDE} \
	${GTEST_INCLUDE} \
	third-party

LIBDIRS := \
	${LIBBLASR_LIB} \
	${LIBPBDATA_LIB} \
	${LIBPBIHDF_LIB} \
	${PBBAM_LIB} \
	${HDF5_LIB} \
	${GCC_LIB} \
	${ZLIB_LIB}

PTHREAD_LIBFLAGS:=-lpthread
LDLIBS+= \
	${LIBBLASR_LIBFLAGS} \
	${LIBPBDATA_LIBFLAGS} \
	${LIBPBIHDF_LIBFLAGS} \
	${PBBAM_LIBFLAGS} \
	${HDF5_LIBFLAGS} \
	${HTSLIB_LIBS} \
	${ZLIB_LIBFLAGS} \
	${PTHREAD_LIBFLAGS} \
	${DL_LIBFLAGS}
CPPFLAGS+=$(patsubst %,-I%,${INCDIRS}) $(HTSLIB_CFLAGS)
LDFLAGS+=$(patsubst %,-L %,${LIBDIRS})

# For fused-src, gtest-all.cc includes gtest/*.
# For non-fused, gtest-all.cc includes src/gtest-*.
# So we add -I ${GTEST_SRC}/.. for the latter case.
GTEST_CPPFLAGS += -isystem $(GTEST_INCLUDE) -isystem ${GTEST_SRC}/..
GTEST_CXXFLAGS += -g -Wall -Wextra -pthread

CXXFLAGS := -O3 -std=c++14

GTEST_OBJECTS := gtest-all.o gtest_main.o
DAZCON_OBJECTS := DB.o QV.o align.o Alignment.o \
			      DazAlnProvider.o

PBDAGCON_OBJECTS := AlnGraphBoost.o Alignment.o \
					SimpleAligner.o
pbdagcon_testexes :=    test-alngraph \
                        test-alignment \
                        test-simple_aligner \
                        ${null}
dazcon_testexes :=    test-target_hit \
                      test-target \
                      ${null}
# Remove the test from the broken_testexes variable, once fixed.
broken_testexes := test-target \
                   ${null}
testexes := ${pbdagcon_testexes} ${dazcon_testexes}
# Remove broken tests exes from the testexes list
testexes   := $(filter-out ${broken_testexes},${testexes})

empty:=
space:=${empty} ${empty}
ldp+=$(subst ${space},:,${LIBDIRS}):${LD_LIBRARY_PATH}
#export LD_LIBRARY_PATH

vpath %.c ${THISDIR}/../../src/cpp
vpath %.cpp ${THISDIR}/../../src/cpp
vpath %.cc ${GTEST_SRC}
vpath align.c ${DALIGNER_SRC}
vpath DB.c ${DAZZ_DB_SRC}
vpath QV.c ${DAZZ_DB_SRC}

#VALGRIND?=/mnt/software/v/valgrind/3.10.1/bin/valgrind --leak-check=full
BUILDMSG = "=== Building $@ ==="

${GTEST_OBJECTS}: CXXFLAGS+=${GTEST_CXXFLAGS}
${GTEST_OBJECTS}: CPPFLAGS+=${GTEST_CPPFLAGS}

all: check
check: gtest-run
gtest-run: $(testexes:%=%-gtestrun)
gtest-build: ${testexes}
xml:
	mkdir xml

%-gtestrun: % | xml
	LD_LIBRARY_PATH=${ldp} PBDAGCON_TEST_DATA_DIR=${THISDIR} ${VALGRIND} ./$< --gtest_output=xml:xml/${<F}.xml
test-%:
	${CXX} -o $@ $^ ${LDFLAGS} ${LDLIBS}

# dazcon  test executables:
test-target_hit: ${GTEST_OBJECTS} ${DAZCON_OBJECTS} TargetHitTest.o
test-target: ${GTEST_OBJECTS} ${DAZCON_OBJECTS} TargetTest.o

# pbdagcon test executables:
test-alngraph: ${GTEST_OBJECTS} ${PBDAGCON_OBJECTS} AlnGraphBoostTest.o
test-alignment: ${GTEST_OBJECTS} ${PBDAGCON_OBJECTS} AlignmentTest.o
test-simple_aligner: ${GTEST_OBJECTS} ${PBDAGCON_OBJECTS} SimpleAlignerTest.o

clean:
	${RM} ${SRCDIR}/*.o
	${RM} *.o
	${RM} test_*
