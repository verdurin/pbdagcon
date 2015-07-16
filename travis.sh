#!/usr/bin/env bash
set -ex

./configure.py --boost --gtest --sub
make -j init-submodule
make --debug=b -j
make --debug=v -j check
