.PHONY: all clean test init-submodule cpp-github cpp cpp-check cpp-clean
SHELL = /bin/bash -e

all: cpp-github

clean: cpp-clean

check: cpp-github-check

project: init-submodule cpp-github

init-submodule:
	$(MAKE) update-submodule
	$(MAKE) build-submodule

update-submodule:
	git submodule update --init

build-submodule:
	cd blasr_libcpp; NOHDF=1 NOPBBAM=1 ./configure.py
	$(MAKE) -C blasr_libcpp/pbdata -f build.mk all
	$(MAKE) -C blasr_libcpp/alignment -f build.mk all

submodule-clean:
	$(RM) -r blasr_libcpp
	
# C++ project build directives
cpp-github:
	$(MAKE) -C src/cpp BLASR=$(PWD)/blasr_libcpp/alignment PBDATA=$(PWD)/blasr_libcpp/pbdata

cpp-github-check:
	$(MAKE) -C test/cpp BLASR=$(PWD)/blasr_libcpp/alignment PBDATA=$(PWD)/blasr_libcpp/pbdata

cpp:
	$(MAKE) -C src/cpp

cpp-check: cpp
	$(MAKE) -C test/cpp

cpp-clean:
	$(MAKE) -C src/cpp clean
	$(MAKE) -C test/cpp clean

clean-all: cpp-clean submodule-clean
	$(RM)r src/cpp/third-party/boost_1_58_0-headersonly
	$(RM)r test/cpp/gtest-1.7.0

