all:

THISDIR:=$(dir $(lastword ${MAKEFILE_LIST}))
-include ${CURDIR}/../../defines.mk

COMMON_OBJECTS := Alignment.o AlnGraphBoost.o
PBDAGCON_OBJECTS := BlasrM5AlnProvider.o main.o SimpleAligner.o
DAZCON_OBJECTS := DB.o align.o DazAlnProvider.o dazcon.o

CXXFLAGS = -O3 -std=c++11 -Wall -Wuninitialized -pedantic
CFLAGS = -O3 -Wall -Wextra -fno-strict-aliasing

INCDIRS := \
	${LIBBLASR_INCLUDE} \
	${LIBPBDATA_INCLUDE} \
	${LIBPBIHDF_INCLUDE} \
	${PBBAM_INCLUDE} \
	${HDF5_INCLUDE} \
	${HTSLIB_INCLUDE} \
	${BOOST_INCLUDE} \
	${THISDIR}/third-party
LIBDIRS := \
	${LIBBLASR_LIB} \
	${LIBPBDATA_LIB} \
	${LIBPBIHDF_LIB} \
	${PBBAM_LIB} \
	${HDF5_LIB} \
	${HTSLIB_LIB} \
	${ZLIB_LIB}
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

all: pbdagcon dazcon

# Technically does not need pbdata or blasr, but so what?
dazcon: $(COMMON_OBJECTS) $(DAZCON_OBJECTS)
	$(CXX) -Wl,--no-as-needed -o $@ $^ $(LDFLAGS) $(LDLIBS)

pbdagcon: $(COMMON_OBJECTS) $(PBDAGCON_OBJECTS)
	$(CXX) -Wl,--no-as-needed -o $@ $^ $(LDFLAGS) $(LDLIBS)

$(COMMON_OBJECTS) $(PBDAGCON_OBJECTS):

clean:
	$(RM) *.d
	$(RM) *.o
	$(RM) pbdagcon
	$(RM) dazcon

.PHONY: all clean
