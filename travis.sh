#!/usr/bin/env bash
set -ex

make -j init-submodule
make --debug=b -j
make --debug=v -j check
