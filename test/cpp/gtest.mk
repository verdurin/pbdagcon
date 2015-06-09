# user-specified location of gtest
ifdef gtest
GTEST_DIR := $(gtest)
else
# download/unpack a version from the inter-web
gtest_version := gtest-1.7.0
gtest_uri := https://googletest.googlecode.com/files/$(gtest_version).zip
get_gtest := curl -O $(gtest_uri)
GTEST_DIR := $(gtest_version)
endif
