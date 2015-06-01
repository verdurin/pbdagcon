# A URI location for a copy of boost headers only
URI := https://www.dropbox.com/s/g22iayi83p5gbbq/boost_1_58_0-headersonly.tbz2\?dl\=0
# Obtain the boost URI and extract it into PWD
GET_BOOST := curl -L $(URI) | tar xjf -

MYPATH__ := $(dir $(CURDIR)/$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))

# Three ways to boost: 1) Internal PBI repot, 2) URI, 3) User specified.

ifdef boost
BOOST_HEADERS := $(boost)
else
BOOST_HEADERS := $(MYPATH__)third-party/boost_1_58_0-headersonly
endif

ifneq ($(wildcard $(PREBUILT)/boost/boost_1_58_0-headersonly/*),)
BOOST_HEADERS := $(PREBUILT)/boost/boost_1_58_0-headersonly
endif
