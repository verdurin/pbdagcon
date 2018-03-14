#!/bin/bash
export PATH=$PWD/deployment/bin:$PATH
export LD_LIBRARY_PATH=$PWD/deployment/lib:$LD_LIBRARY_PATH
type module >& /dev/null \
|| . /mnt/software/Modules/current/init/bash
module load gcc
module load htslib
module load hdf5-tools
module load zlib

make -C repos/pbdagcon/build check
chmod +w -R repos/pbdagcon
