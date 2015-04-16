# Defines some variables specific to the PBI build env using relative paths
BASEDIR  ?= ../../../../../..
PREBUILT := $(BASEDIR)/smrtanalysis/prebuilt.out
BIFX     := $(BASEDIR)/smrtanalysis/bioinformatics
BLASR    ?= $(BIFX)/lib/cpp/alignment
PBDATA   ?= $(BIFX)/lib/cpp/pbdata
PBBAM    := $(BIFX)/staging/PostPrimary/pbbam
ZLIB     := $(PREBUILT)/zlib/zlib-1.2.5/$(OS_STRING2)/lib

INCDIRS := -I$(PBDATA) -I$(BLASR) -I$(PBBAM)/include -I$(PBBAM)/third-party/htslib
LDFLAGS := -L$(PBDATA) -L$(BLASR) -L$(PBBAM)/lib -L$(PBBAM)/third-party/htslib -L$(ZLIB)
