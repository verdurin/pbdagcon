#!/bin/bash -e
NEXUS_BASEURL=http://ossnexus.pacificbiosciences.com/repository
#NEXUS_URL=$NEXUS_BASEURL/unsupported/gcc-4.9.2
if [ ! -e .distfiles/gtest/release-1.7.0.tar.gz ]; then
  mkdir -p .distfiles/gtest
  curl -sL $NEXUS_BASEURL/unsupported/distfiles/googletest/release-1.7.0.tar.gz \
    -o .distfiles/gtest/release-1.7.0.tar.gz
fi
tar zxf .distfiles/gtest/release-1.7.0.tar.gz -C repos/
ln -sfn googletest-release-1.7.0 repos/gtest

rm -rf deployment
mkdir -p deployment
#curl -s -L $NEXUS_URL/DAZZ_DB-SNAPSHOT.tgz|tar zx -C deployment
BLASR=tarballs/blasr.tgz
BLASR_LIBCPP=tarballs/blasr_libcpp.tgz
PBBAM=tarballs/pbbam.tgz
tar zxf $BLASR_LIBCPP -C deployment
tar zxf $BLASR        -C deployment
tar zxf $PBBAM        -C deployment

export PATH=$PWD/deployment/bin:$PATH
export LD_LIBRARY_PATH=$PWD/deployment/lib:$LD_LIBRARY_PATH

type module >& /dev/null || . /mnt/software/Modules/current/init/bash
module load git
module load gcc
module load ccache
export CCACHE_DIR=/mnt/secondary/Share/tmp/bamboo.mobs.ccachedir
module load boost
if [[ $BOOST_ROOT =~ /include ]]; then
  set -x
  BOOST_ROOT=$(dirname $BOOST_ROOT)
  set +x
fi
module load htslib
module load hdf5-tools
module load zlib

cd repos/pbdagcon
export CCACHE_BASEDIR=$PWD
rm -f defines.mk
set -x
mkdir build
    BOOST_INCLUDE=$BOOST_ROOT/include \
LIBPBDATA_INCLUDE=$PWD/../../deployment/include/pbdata \
    LIBPBDATA_LIB=$PWD/../../deployment/lib \
 LIBBLASR_INCLUDE=$PWD/../../deployment/include/alignment \
     LIBBLASR_LIB=$PWD/../../deployment/lib \
LIBPBIHDF_INCLUDE=$PWD/../../deployment/include/hdf \
    LIBPBIHDF_LIB=$PWD/../../deployment/lib \
    PBBAM_INCLUDE=$PWD/../../deployment/include \
        PBBAM_LIB=$PWD/../../deployment/lib \
   HTSLIB_INCLUDE=$(pkg-config --cflags-only-I htslib|sed -e 's/-I//g') \
       HTSLIB_LIB=$(pkg-config --libs-only-L htslib|awk '{print $1}'|sed -e 's/^-L//') \
     HDF5_INCLUDE=$(pkg-config --cflags-only-I hdf5|awk '{print $1}'|sed -e 's/^-I//') \
         HDF5_LIB=$(pkg-config --libs-only-L hdf5|awk '{print $1}'|sed -e 's/^-L//') \
     DALIGNER_SRC=$PWD/../daligner \
      DAZZ_DB_SRC=$PWD/../dazzdb \
        GTEST_SRC=$PWD/../gtest/src \
    GTEST_INCLUDE=$PWD/../gtest/include \
    ZLIB_LIBFLAGS="$(pkg-config --libs zlib)" \
./configure.py --build-dir=$PWD/build
make -C build
cp -a build/src/cpp/pbdagcon ../../deployment/bin/
cp -a build/src/cpp/dazcon   ../../deployment/bin/
cd ../..

myVERSION=`pbdagcon --version|awk '/version/{print $3}'`
rm -rf tarballs && mkdir -p tarballs
cd deployment
tar zcf ../tarballs/pbdagcon-${myVERSION}.tgz bin/pbdagcon bin/dazcon
