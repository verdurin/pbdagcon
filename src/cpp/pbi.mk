# Darwin/Clang is unhappy with -L for a non-existent directory, so we
# cannot use this file to build on OSX.
# Instead of a bunch of ifdefs, we can conditionally include this file.

# Defines some variables specific to the PBI build env using relative paths
BASEDIR  ?= ../../../../../..
PREBUILT := $(BASEDIR)/smrtanalysis/prebuilt.out
BIFX     := $(BASEDIR)/smrtanalysis/bioinformatics
BLASR    ?= $(BIFX)/lib/cpp/alignment
PBDATA   ?= $(BIFX)/lib/cpp/pbdata
PBBAM    := $(BIFX)/staging/PostPrimary/pbbam
ZLIB     := $(PREBUILT)/zlib/zlib-1.2.5/$(OS_STRING2)/lib


LIBBLASR_INCLUDE  := $(BLASR)
LIBPBIHDF_INCLUDE := 
LIBPBDATA_INCLUDE := $(PBDATA)
PBBAM_INCLUDE     := $(PBBAM)/include
HTSLIB_INCLUDE    := $(PBBAM)/../htslib
ZLIB_INCLUDE      := $(ZLIB)

LIBBLASR_LIB  := $(BLASR)
LIBPBIHDF_LIB := 
LIBPBDATA_LIB := $(PBDATA)
PBBAM_LIB     := $(PBBAM)/lib
HTSLIB_LIB    := $(PBBAM)/..//htslib
HDF5_LIB      := 
ZLIB_LIB      := $(ZLIB)

LIBPBIHDF_CPP_LIBFLAG := -lhdf5_cpp
LIBPBIHDF_LIBFLAG     := -lhdf5

LIBBLASR_LIBFLAGS  := -lblasr
LIBPBIHDF_LIBFLAGS := -lpbihdf
LIBPBDATA_LIBFLAGS := -lpbdata
PBBAM_LIBFLAGS     := -lpbbam
HTSLIB_LIBFLAGS    := -lhts
HDF5_LIBFLAGS      := $(LIBHDF5_CPP_LIBFLAG) $(LIBHDF5_LIBFLAG)
ZLIB_LIBFLAGS      := -lz

ifneq ($(wildcard $(PBBAM)/*),)
    USE_PBBAM := true
else
    USE_PBBAM :=
endif

ifeq ($(USE_PBBAM),)
    # Not using pbbam
    EXTRA_INCDIRS :=
    EXTRA_LDFLAGS :=
    EXTRA_LDLIBS  :=
else
    # Using pbbam
    EXTRA_INCDIRS := -I$(PBBAM_INCLUDE) -I$(HTSLIB_INCLUDE)
    EXTRA_LDFLAGS := -L$(PBBAM_LIB) -L$(HTSLIB_LIB) -L$(ZLIB_LIB)
    ifneq ($(SHARED_LIB),)
        # When linking shared libs, we need to specify the hdf5 libs since
        # libblasr and libpbihdr depend on them.
        EXTRA_LDFLAGS += -L$(HDF5_LIB)
    endif

    # We are moving to BAM, which requires extra lib support when compiling 
    # against libblasr.  This conditional allows backward compatable 
    # compilations with PacificBiosciences/blasr_libcpp.
    EXTRA_LDLIBS  := $(PBBAM_LIBFLAGS) $(HTSLIB_LIBFLAGS) $(ZLIB_LIBFLAGS)
    ifneq ($(SHARED_LIB),)
        # When linking shared libs, we need to specify the hdf5 libs since
        # libblasr and libpbihdf depend on them.
        EXTRA_LDLIBS += $(HDF5_LIBFLAGS)
    endif
    EXTRA_LDLIBS  += -Wl,-Bdynamic -lpthread
endif
