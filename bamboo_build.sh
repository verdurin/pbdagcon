#!/bin/bash -e
rm -rf prebuilt deployment
mkdir -p prebuilts/libbzip2-1.0.6
curl -sL http://ossnexus/repository/unsupported/pitchfork/gcc-4.9.2/libbzip2-1.0.6.tgz \
| tar zxf - -C prebuilts/libbzip2-1.0.6
if [ ! -e .distfiles/gtest/release-1.7.0.tar.gz ]; then
  mkdir -p .distfiles/gtest
  curl -sL http://ossnexus/repository/unsupported/distfiles/googletest/release-1.7.0.tar.gz \
    -o .distfiles/gtest/release-1.7.0.tar.gz
fi

type module >& /dev/null || \
. /mnt/software/Modules/current/init/bash
module load git/2.8.3
module load gcc/4.9.2
module load ccache/3.2.3

cat > pitchfork/settings.mk << EOF
CCACHE_BASEDIR=$PWD/pitchfork
CCACHE_DIR=/mnt/secondary/Share/tmp/bamboo.mobs.ccachedir
export CCACHE_BASEDIR CCACHE_DIR
# from Herb
HAVE_OPENSSL      = /mnt/software/o/openssl/1.0.2a
HAVE_PYTHON       = /mnt/software/p/python/2.7.9/bin/python
HAVE_BOOST        = /mnt/software/b/boost/1.58.0
HAVE_ZLIB         = /mnt/software/z/zlib/1.2.8
HAVE_SAMTOOLS     = /mnt/software/s/samtools/1.3.1mobs
HAVE_NCURSES      = /mnt/software/n/ncurses/5.9
# from MJ
HAVE_HDF5         = /mnt/software/a/anaconda2/4.2.0
HAVE_OPENBLAS     = /mnt/software/o/openblas/0.2.14
HAVE_CMAKE        = /mnt/software/c/cmake/3.2.2/bin/cmake
HAVE_LIBBZIP2     = $PWD/prebuilts/libbzip2-1.0.6
#
pbdagcon_REPO     = $PWD/repos/pbdagcon
pbbam_REPO        = $PWD/repos/pbbam
htslib_REPO       = $PWD/repos/htslib
blasr_libcpp_REPO = $PWD/repos/blasr_libcpp
PREFIX            = $PWD/deployment
EOF
echo y | make -C pitchfork _startover
make -j8 -C pitchfork pbdagcon

source deployment/setup-env.sh
myVERSION=`pbdagcon --version|awk '/version/{print $3}'`
rm -rf tarballs && mkdir -p tarballs
cd deployment
tar zcf ../tarballs/pbdagcon-${myVERSION}.tgz $(grep -v '^#' var/pkg/pbdagcon)
