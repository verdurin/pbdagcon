include pbi.mk
include boost.mk

COMMON_OBJECTS := Alignment.o AlnGraphBoost.o
PBDAGCON_OBJECTS := BlasrM5AlnProvider.o main.o SimpleAligner.o
DAZCON_OBJECTS := DB.o align.o DazAlnProvider.o dazcon.o

CXXFLAGS = -O3 -std=c++11 -Wall -Wuninitialized -pedantic -I third-party \
		   -I $(BOOST_INCLUDE)

CFLAGS = -O3 -Wall -Wextra -fno-strict-aliasing

INCDIRS := -I$(LIBPBDATA_INCLUDE) -I$(LIBBLASR_INCLUDE) $(EXTRA_INCDIRS)
LDFLAGS := -L$(LIBBLASR_LIB)
ifneq ($(SHARED_LIB),)
    # When linking shared libs, we need to specify the libpbihdf lib since
    # libblasr depends on them.
    LDFLAGS += -L$(LIBPBIHDF_LIB)
endif
LDFLAGS += -L$(LIBPBDATA_LIB)
LDFLAGS += $(EXTRA_LDFLAGS)

objects := $(COMMON_OBJECTS) $(PBDAGCON_OBJECTS) $(DAZCON_OBJECTS)
deps := $(objects:%.o=%.d)

all: pbdagcon

dazcon: LDLIBS = -lpthread
dazcon: $(COMMON_OBJECTS) $(DAZCON_OBJECTS)
	$(CXX) -Wl,--no-as-needed -o $@ $^ $(LDLIBS)

PBDAGCON_LDLIBS := $(LIBBLASR_LIBFLAGS)
ifneq ($(SHARED_LIB),)
    # When linking shared libs, we need to specify the libpbihdf lib since
    # libblasr depends on them.
    PBDAGCON_LDLIBS += $(LIBPBIHDF_LIBFLAGS)
endif
PBDAGCON_LDLIBS += $(LIBPBDATA_LIBFLAGS)
PBDAGCON_LDLIBS += $(EXTRA_LDLIBS)
PBDAGCON_LDLIBS += -Wl,-Bdynamic -lpthread
ifneq ($(SHARED_LIB),)
    # When linking shared libs, we need to specify the librt lib since
    # libblasr depends on them.
    PBDAGCON_LDLIBS += -Wl,-Bdynamic -lrt
endif

pbdagcon: LDLIBS = $(PBDAGCON_LDLIBS)
pbdagcon: CXXFLAGS += $(INCDIRS)
pbdagcon: $(COMMON_OBJECTS) $(PBDAGCON_OBJECTS)
	$(CXX) -Wl,--no-as-needed $(LIBDIRS) -o $@ $^ $(LDFLAGS) $(LDLIBS)

$(COMMON_OBJECTS): $(BOOST_HEADERS)

$(BOOST_HEADERS):
	cd third-party && $(GET_BOOST)

clean:
	$(RM) *.d
	$(RM) *.o
	$(RM) pbdagcon
	$(RM) dazcon

-include $(deps)

.PHONY: all clean
