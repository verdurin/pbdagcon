.PHONY: all clean test init-submodule cpp-github cpp cpp-check cpp-clean
SHELL = /bin/bash -e

all: cpp-github

clean: cpp-clean

test: cpp-check

init-submodule:
	git submodule init
	$(MAKE) -C blasr_libcpp/alignment nohdf=1
	$(MAKE) -C blasr_libcpp/pbdata
	
# C++ project build directives
cpp-github:
	$(MAKE) -C src/cpp BLASR=$(PWD)/blasr_libcpp/alignment PBDATA=$(PWD)/blasr_libcpp/pbdata

cpp:
	$(MAKE) -C src/cpp

cpp-check: cpp
	$(MAKE) -C test/cpp

cpp-clean:
	$(MAKE) -C src/cpp clean
	$(MAKE) -C test/cpp clean
