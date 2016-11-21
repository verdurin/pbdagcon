.PHONY: all clean test init-submodule cpp cpp-check cpp-clean

THISDIR:=$(dir $(lastword ${MAKEFILE_LIST}))
ROOT:=${THISDIR}
-include ${CURDIR}/defines.mk

SHELL = /bin/bash -e

all: cpp

clean: cpp-clean

check: cpp-check

project: init-submodule cpp

init-submodule:
	${MAKE} update-submodule
	${MAKE} build-submodule

update-submodule:
	git submodule update --init

build-submodule:
	cd blasr_libcpp; NOHDF=1 NOPBBAM=1 ./configure.py
	${MAKE} -C blasr_libcpp/pbdata libconfig.h
	${MAKE} -C blasr_libcpp/pbdata libpbdata.a
	${MAKE} -C blasr_libcpp/alignment libblasr.a

submodule-clean:
	${RM} -r blasr_libcpp
	
cpp:
	${MAKE} -C src/cpp

cpp-check: cpp
	${MAKE} -C test/cpp

cpp-clean:
	${MAKE} -C src/cpp clean
	${MAKE} -C test/cpp clean

clean-all: cpp-clean submodule-clean
	${RM}r src/cpp/third-party/boost_1_58_0-headersonly
	${RM}r test/cpp/googletest-release-1.7.0
