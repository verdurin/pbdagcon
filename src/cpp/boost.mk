# A URI location for a copy of boost 1_57_0, headers only
URI := https://www.dropbox.com/s/grryr7ttqymg2fu/boost_1_57_0.tbz2\?dl\=1 
# Obtain the boost URI and extract it into PWD
GET_BOOST := curl -L $(URI) | tar xjf -

# Three ways to boost: 1) Internal PBI repot, 2) URI, 3) User specified.

ifdef boost
BOOST_HEADERS := $(boost)
else
BOOST_HEADERS := third-party/boost_1_57_0
endif

ifneq ($(wildcard $(PREBUILT)/boost/boost_1_55_0/*),)
BOOST_HEADERS := $(PREBUILT)/boost/boost_1_55_0
endif
