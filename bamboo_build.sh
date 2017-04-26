#!/bin/bash -e
rm -rf prebuilt deployment
mkdir -p prebuilt
PBBAM=`/bin/ls -t tarballs/pbbam*-x86_64.tgz|head -1`
curl -s -L http://nexus/repository/maven-snapshots/pacbio/sat/htslib/htslib-1.1-SNAPSHOT.tgz -o tarballs/htslib-1.1-SNAPSHOT.tgz
HTSLIB=`/bin/ls -t tarballs/htslib-*.tgz|head -1`
BLASR=`/bin/ls -t tarballs/blasr-*tgz|head -1`
BLASR_LIBCPP=`/bin/ls -t tarballs/blasr_libcpp*tgz|head -1`
HAVE_HTSLIB=$PWD/prebuilts/`basename $HTSLIB .tgz`
HAVE_BLASR_LIBCPP=$PWD/prebuilts/`basename $BLASR_LIBCPP .tgz`
HAVE_PBBAM=$PWD/prebuilts/`basename $PBBAM -x86_64.tgz`
mkdir -p \
         $HAVE_HTSLIB \
         $HAVE_BLASR_LIBCPP \
         $HAVE_PBBAM
tar zxf $HTSLIB -C $HAVE_HTSLIB
tar zxf $PBBAM -C prebuilts
tar zxf $BLASR_LIBCPP -C $HAVE_BLASR_LIBCPP

type module >& /dev/null || \
. /mnt/software/Modules/current/init/bash
module load git/2.8.3
module load gcc/4.9.2
module load ccache/3.2.3

cat > pitchfork/settings.mk << EOF
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
#
pbdagcon_REPO     = $PWD/repos/pbdagcon
pbbam_REPO        = $PWD/repos/pbbam
htslib_REPO       = $PWD/repos/htslib
blasr_libcpp_REPO = $PWD/repos/blasr_libcpp
PREFIX            = $PWD/deployment
EOF
echo y | make -C pitchfork _startover
make -C pitchfork pbdagcon

source deployment/setup-env.sh
myVERSION=`pbdagcon --version|awk '/version/{print $3}'`
rm -rf tarballs && mkdir -p tarballs
cd deployment
tar zcf ../tarballs/pbdagcon-${myVERSION}.tgz $(grep -v '^#' var/pkg/pbdagcon)
