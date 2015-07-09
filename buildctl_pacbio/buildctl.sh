#!/bin/bash

# ---- required subroutines
set_globals() {
    # required globals:
    g_name="pbdagcon"

    if $opt_mobs; then

	mobs_exe=$MOBS_EXE;
	if [[ -z "$mobs_exe" ]]; then
	    mobs_exe="$g_progdir/../../../../../build/3.x/mobs";
	fi
	eval $($mobs_exe -p "$g_name")

	g_make_exe=$MOBS_make__make_exe
	g_gxx_exe=$MOBS_gcc__gxx_exe
	g_git_exe=$MOBS_git__git_exe

	g_libblasr_rootdir_abs=$MOBS_libblasr__install_dir
	g_libpbihdf_rootdir_abs=$MOBS_libpbihdf__install_dir
	g_libpbdata_rootdir_abs=$MOBS_libpbdata__install_dir
	g_pbbam_rootdir_abs=$MOBS_pbbam__install_dir
	g_htslib_rootdir_abs=$MOBS_htslib__install_dir
	g_hdf5_rootdir_abs=$MOBS_hdf5__install_dir
	g_zlib_rootdir_abs=$MOBS_zlib__install_dir
	g_boost_rootdir_abs=$MOBS_boost__root_dir


	eval g_outdir_abs="\$MOBS_${g_name}__output_dir"
	eval g_outdir="\$MOBS_${g_name}__output_dir"
	eval g_installbuild_dir_abs="\$MOBS_${g_name}__install_dir"
	eval g_installbuild_dir="\$MOBS_${g_name}__install_dir"

	eval g_binwrap_build_dir="\$MOBS_${g_name}__install_binwrapbuild_dir"

	eval g_git_fetch_dir="\$MOBS_${g_name}__git_fetch_dir"
        eval g_git_remote_url="\$MOBS_${g_name}__git_remote_url"
        eval g_git_ref="\$MOBS_${g_name}__git_ref"

	# For binwrap-build directory:
	build_topdir=$MOBS_global__build_topdir;

	# Compute the path to the dependency lib dirs, relative to the top
	# of the build tree
	g_libblasr_build_runtime_libdir_reltop=${MOBS_libblasr__runtimelib_dir#$build_topdir/}
	g_libpbihdf_build_runtime_libdir_reltop=${MOBS_libpbihdf__runtimelib_dir#$build_topdir/}
	g_libpbdata_build_runtime_libdir_reltop=${MOBS_libpbdata__runtimelib_dir#$build_topdir/}
	g_pbbam_build_runtime_libdir_reltop=${MOBS_pbbam__runtimelib_dir#$build_topdir/}
	g_htslib_build_runtime_libdir_reltop=${MOBS_htslib__runtimelib_dir#$build_topdir/}
	g_hdf5_build_runtime_libdir_reltop=${MOBS_hdf5__runtimelib_dir#$build_topdir/}
	g_zlib_build_runtime_libdir_reltop=${MOBS_zlib__runtimelib_dir#$build_topdir/}
	g_gcc_build_runtime_libdir_reltop=${MOBS_gcc__runtimelib_dir#$build_topdir/}

	# For binwrap-deploy directory:
	g_libblasr_deploy_runtime_libdir_reltop="pacbio/libblasr/lib"
	g_libpbihdf_deploy_runtime_libdir_reltop="pacbio/libpbihdf/lib"
	g_libpbdata_deploy_runtime_libdir_reltop="pacbio/libpbdata/lib"
	g_pbbam_deploy_runtime_libdir_reltop="pacbio/pbbam/lib"
	g_htslib_deploy_runtime_libdir_reltop="pacbio/htslib/lib"
	g_hdf5_deploy_runtime_libdir_reltop="thirdparty/hdf5/hdf5-1.8.12/lib"
	g_zlib_deploy_runtime_libdir_reltop="thirdparty/zlib/zlib_1.2.8/lib"
	g_gcc_deploy_runtime_libdir_reltop="thirdparty/gcc/gcc-4.8.4/lib"

	# The deploy topdir is effectively the 'private' directory
	g_deploy_topdir_relprog="../../.."


	echo "Computing reltop..."
	binwrap_reltop=${g_binwrap_build_dir#$build_topdir/}
	top_relbinwrap=""
	if [[ $binwrap_reltop =~ ^/ ]]; then
	    merror "Could not compute topdir (binwrap not under topdir)"
	fi

	while [[ x"$binwrap_reltop" != x"." ]] ; do
	    if [[ x"$binwrap_reltop" == x"/" ]] ; then
		minterror "Error in computing topdir."
	    fi
	    top_relbinwrap="$top_relbinwrap/..";
	    binwrap_reltop=$(dirname "$binwrap_reltop");
	done
	top_relbinwrap=${top_relbinwrap#/};
	g_build_topdir_relprog="$top_relbinwrap"
    else
	g_module_dir_reltop="bioinformatics/tools/pbdagcon"

	g_topdir="$g_progdir/../../../../.."
	g_topdir_abs=$(readlink -f "$g_topdir");
	g_module_dir="$g_topdir/$g_module_dir_reltop";
	g_module_dir_abs="$g_topdir_abs/$g_module_dir_reltop";

        # other globals:
	g_make_rootdir="/usr"
	g_gcc_rootdir="$g_topdir_abs/prebuilt.out/3.x/gcc/gcc-4.8.4/libc-2.5"
	g_git_rootdir="$g_topdir_abs/prebuilt.tmpsrc/git/git_2.4.5/_output/install"

	g_make_exe="${g_make_rootdir}/bin/make"
	g_gxx_exe="${g_gcc_rootdir}/bin/g++"
	g_git_exe="${g_git_rootdir}/binwrap-build/git"

	g_outdir_name="_output";
	g_outdir_abs="$g_module_dir_abs/$g_outdir_name"
	g_outdir=$g_outdir_abs;
	g_installbuild_dir_abs="${g_outdir}/install-build"
	g_installbuild_dir="${g_installbuild_dir_abs}"

	g_git_fetch_dir="$g_outdir_abs/build"
        g_git_remote_url=$("$g_make_exe" -C "$g_module_dir_abs" SHELL=/bin/bash --no-print-directory print-remote)
        g_git_ref=$("$g_make_exe" -C "$g_module_dir_abs" SHELL=/bin/bash --no-print-directory print-ref)

	g_libblasr_rootdir_abs="$g_topdir_abs/bioinformatics/lib/cpp/alignment/${g_outdir_name}/install-build"
	g_libpbihdf_rootdir_abs="$g_topdir_abs/bioinformatics/lib/cpp/hdf/${g_outdir_name}/install-build"
	g_libpbdata_rootdir_abs="$g_topdir_abs/bioinformatics/lib/cpp/pbdata/${g_outdir_name}/install-build"
	g_pbbam_rootdir_abs="$g_topdir_abs/bioinformatics/staging/PostPrimary/pbbam/${g_outdir_name}/install-build"
	g_htslib_rootdir_abs="$g_topdir_abs/bioinformatics/staging/PostPrimary/htslib/${g_outdir_name}/install-build"
	g_hdf5_rootdir_abs="$g_topdir_abs/prebuilt.out/hdf5/hdf5-1.8.12/centos-5"
	g_zlib_rootdir_abs="$g_topdir_abs/prebuilt.tmpsrc/zlib/zlib_1.2.8/_output/install"
	g_boost_rootdir_abs="$g_topdir_abs/prebuilt.out/boost/boost_1_55_0"

	g_build_topdir_relprog=".."

	g_libblasr_build_runtime_libdir_reltop="runtimelibs/libblasr/lib"
	g_libpbihdf_build_runtime_libdir_reltop="runtimelibs/libpbihdf/lib"
	g_libpbdata_build_runtime_libdir_reltop="runtimelibs/libpbdata/lib"
	g_pbbam_build_runtime_libdir_reltop="runtimelibs/pbbam/lib"
	g_htslib_build_runtime_libdir_reltop="runtimelibs/htslib/lib"
	g_hdf5_build_runtime_libdir_reltop="runtimelibs/hdf5/lib"
	g_zlib_build_runtime_libdir_reltop="runtimelibs/zlib/lib"
	g_gcc_build_runtime_libdir_reltop="runtimelibs/gcc/lib"
    fi

    git_dirname=$(basename "$g_git_remote_url" .git)
    g_git_build_topdir="$g_git_fetch_dir/$git_dirname"
    g_git_build_srcdir="$g_git_build_topdir/src/cpp"
    g_make_cmd='
	$g_make_exe -C "$g_git_build_srcdir"
    '
    g_make_cmd=$(echo $g_make_cmd)
}

# ---- build targets

fetch_gitsrc() {
    local git_home=$g_git_fetch_dir;
    local git_destdir="$g_git_build_topdir"

    local remoteinfo;
    local mustclone=false;
    local stat;
    stat=0;
    if [[ ! -e "$git_destdir" ]] ; then
	mustclone=true;
    else
	remoteinfo=$(HOME="$git_home" "$g_git_exe" -C "$git_destdir" remote show origin) || stat=$?
	if [[ $stat -eq 0 ]] ; then
	    local fetchurl;
	    fetchurl=$(echo "$remoteinfo" | sed -ne 's/^[[:space:]]*Fetch URL:[[:space:]]*//p')
	    if [[ x"$fetchurl" != x"$g_git_remote_url" ]] ; then
		mustclone=true;
	    fi
	elif [[ $stat -eq 1 ]] ; then
	    mustclone=true;
	else
	    merror "Unexpected error (1) when running git command (exitstat: $stat)"
	fi
    fi

    if $mustclone; then
	echo "Cloning $g_name sources from git..."
	rm -rf "$git_home"
	mkdir -p "$git_home"
	HOME="$git_home" "$g_git_exe" clone "$g_git_remote_url" "$git_destdir"
    fi

    local mustfetch=false;
    # This will check to see if the reference is actually a valid git commint
    # sha hash in the local repository.  If so, we don't need to go out and 
    # fetch the latest from the remote repository.  For any other ref type
    # (e.g. HEAD, tag, branch,...) we cannot be guaranteed that it didnt't 
    # change on the remote side, so we need to fetch anyway.  If it not a 
    # reference listed by 'show-ref', but it is a git commit sha hash listed 
    # with parse-rev, but it not in the local repository, we also need
    # to fetch the latest.  This rev-parse command should handle all the cases
    # (no need to fetch if exits with zero status, fetch otherwise).
    # See this link for more info on testing refs:
    #    http://stackoverflow.com/questions/18222634/given-a-git-refname-can-i-detect-whether-its-a-hash-tag-or-branch
    stat=0
    HOME="$git_home" "$g_git_exe" -C "$git_destdir" show-ref "${g_git_ref}" > /dev/null 2>&1 || stat=$?
    if [[ $stat -eq 0 ]] ; then    
	# This is a HEAD, tag, branch, remote reference.  We will need to 
	# fetch (since it is a pointer that may have been updated in the
	# remote repository.
	mustfetch=true;
    elif [[ $stat -eq 1 ]] ; then
	stat=0
	HOME="$git_home" "$g_git_exe" -C "$git_destdir" rev-parse "${g_git_ref}^{commit}" > /dev/null 2>&1 || stat=$?
	if [[ $stat -ne 0 ]] ; then
	    # This is either not a valid sha hash, or it is one that our 
	    # local repository does not know about yet.  In either case
	    # fetch it from the remote repository.
	    mustfetch=true;
	fi
    else
	merror "Unexpected error (2) when running git command (exitstat: $stat)"
    fi

    if $mustfetch; then
	echo "Fetching (updating) $g_name sources from git..."
	HOME="$git_home" "$g_git_exe" -C "$git_destdir" fetch
    else
	echo "Git sources for $g_name already up to date..."
    fi

    # Now do a sanity check to make sure we actually have the ref in question
    # in our local repository
    stat=0
    HOME="$git_home" "$g_git_exe" -C "$git_destdir" rev-parse "${g_git_ref}^{commit}" > /dev/null 2>&1 || stat=$?
    if [[ $stat -ne 0 ]] ; then
	merror "Could not find the git reference '$g_git_ref' after updating the local repository"
    fi

    # Now update to the specified reference or sha hash
    HOME="$git_home" "$g_git_exe" -C "$git_destdir" reset --hard "$g_git_ref"

    # At this point we should have the expected code in $git_destdir
}

clean() {
    echo "Running $g_name 'clean' target..."
    # Clean the build artifacts
    # NOTE: don't need HDF5_INC/LIB for clean, supply /dev/null to inhibit
    #       errors
    if [[ -e "$g_git_build_srcdir/Makefile" ]] ; then
	eval "$g_make_cmd" clean \
	    COMMON_NO_THIRD_PARTY_REQD=true \
	    ${1+"$@"}
    fi
    # Remove the _output directory
    rm -rf "${g_outdir}"
}
cleanall() {
    echo "Running $g_name 'cleanall' target..."
    clean;
}
build() {
    fetch_gitsrc;

    echo "Running $g_name 'build' target..."

    # Temporary modifications to Makefile (until it gets in the real Makefile)
    use_alt_makefile=true;
    if $use_alt_makefile; then
	progdir_abs=$(readlink -f "$g_progdir")

	alt_makefile="$progdir_abs/src_cpp_Makefile.tmp.buildctl"
	old_makefile="$g_git_build_srcdir/Makefile"
	orig_old_makefile_md5="e6714f739e0068a5ad6452dfe5c46760";
	cur_old_makefile_md5=$(md5sum "$old_makefile" | sed -e 's/[[:space:]].*//')
	if [[ x"$orig_old_makefile_md5" != x"$cur_old_makefile_md5" ]]; then
	    merror "Original $g_name Makefile '$old_makefile' changed.  Must update alternate Makefile '$alt_makefile' accordingly."
	fi

	alt_pbi_mk="$progdir_abs/src_cpp_pbi.mk.tmp.buildctl"
	old_pbi_mk="$g_git_build_srcdir/pbi.mk"
	orig_old_pbi_mk_md5="792d8eff52a6d910af91e5fe6fd70ceb";
	cur_old_pbi_mk_md5=$(md5sum "$old_pbi_mk" | sed -e 's/[[:space:]].*//')
	if [[ x"$orig_old_pbi_mk_md5" != x"$cur_old_pbi_mk_md5" ]]; then
	    merror "Original $g_name pbi.mk '$old_pbi_mk' changed.  Must update alternate common.mk '$alt_pbi_mk' accordingly."
	fi

	alt_boost_mk="$progdir_abs/src_cpp_boost.mk.tmp.buildctl"
	old_boost_mk="$g_git_build_srcdir/boost.mk"
	orig_old_boost_mk_md5="b4153163f4431834eb71ac0700925df3";
	cur_old_boost_mk_md5=$(md5sum "$old_boost_mk" | sed -e 's/[[:space:]].*//')
	if [[ x"$orig_old_boost_mk_md5" != x"$cur_old_boost_mk_md5" ]]; then
	    merror "Original $g_name boost.mk '$old_boost_mk' changed.  Must update alternate common.mk '$alt_boost_mk' accordingly."
	fi

	g_make_cmd='
	    $g_make_exe -C "$g_git_build_srcdir" -f "$alt_makefile"
        '
	g_make_cmd=$(echo $g_make_cmd)
    fi


    # Create dependency links
    rm -rf "${g_outdir}/deplinks"
    mkdir -p "${g_outdir}/deplinks"

    ln -s "$g_libblasr_rootdir_abs" "${g_outdir}/deplinks/libblasr"
    ln -s "$g_libpbihdf_rootdir_abs" "${g_outdir}/deplinks/libpbihdf"
    ln -s "$g_libpbdata_rootdir_abs" "${g_outdir}/deplinks/libpbdata"
    ln -s "$g_pbbam_rootdir_abs" "${g_outdir}/deplinks/pbbam"
    ln -s "$g_htslib_rootdir_abs" "${g_outdir}/deplinks/htslib"
    ln -s "$g_hdf5_rootdir_abs" "${g_outdir}/deplinks/hdf5"
    ln -s "$g_zlib_rootdir_abs" "${g_outdir}/deplinks/zlib"
    ln -s "$g_boost_rootdir_abs" "${g_outdir}/deplinks/boost"

    shared_flag=""
    shared_libopt="-Wl,-Bstatic"
    if $opt_mobs || $opt_shared; then
	shared_libopt="-Wl,-Bdynamic"
	shared_flag="SHARED_LIB=true"
    fi

    libblasr_includes="${g_outdir}/deplinks/libblasr/include;${g_outdir}/deplinks/libblasr/include/alignment"
    libpbdata_includes="${g_outdir}/deplinks/libpbdata/include"
    pbbam_includes="${g_outdir}/deplinks/pbbam/include"
    htslib_includes="${g_outdir}/deplinks/htslib/include"
    boost_includes="${g_outdir}/deplinks/boost/include"

    # FIXME: HACK to only provide the single include directories that blasr
    #        needs for libblasr, libpbihdf and boost.   Other things that 
    #        depend on those libraries require two versions of the include
    #        directories (probably because they inconsistently use the 
    #        directory prefix becasue they are poking into the source
    #        tree for the include files).  The makefile for blasr should
    #        probably handle multilple directories regardless, just to handle
    #        the general case, but the other builds and the include files
    #        provided to mobs should also be fixed to use just a single 
    #        directory.
    libblasr_include=${libblasr_includes#*;}
    libpbdata_include=$libpbdata_includes
    pbbam_include=$pbbam_includes
    htslib_include=$htslib_includes
    boost_include=${boost_includes}

    libblasr_libdir="${g_outdir}/deplinks/libblasr/lib"
    libpbihdf_libdir="${g_outdir}/deplinks/libpbihdf/lib"
    libpbdata_libdir="${g_outdir}/deplinks/libpbdata/lib"
    pbbam_libdir="${g_outdir}/deplinks/pbbam/lib"
    htslib_libdir="${g_outdir}/deplinks/htslib/lib"
    hdf5_libdir="${g_outdir}/deplinks/hdf5/lib"
    zlib_libdir="${g_outdir}/deplinks/zlib/lib"

    libblasr_libflags="$shared_libopt -lblasr"
    libpbihdf_libflags="$shared_libopt -lpbihdf"
    libpbdata_libflags="$shared_libopt -lpbdata"
    pbbam_libflags="$shared_libopt -lpbbam"
    htslib_libflags="$shared_libopt -lhts"
    hdf5_libflags="$shared_libopt -lhdf5_cpp $shared_libopt -lhdf5"
    zlib_libflags="$shared_libopt -lz"

    # build
    eval "$g_make_cmd" \
	-j \
	CXX=\"$g_gxx_exe\" \
	\
	BOOST_HEADERS=\"\" \
	USE_PBBAM=\"true\" \
	"${shared_flag}" \
	\
	LIBBLASR_INCLUDE=\"$libblasr_include\" \
        LIBPBDATA_INCLUDE=\"$libpbdata_include\" \
	PBBAM_INCLUDE=\"$pbbam_include\" \
	HTSLIB_INCLUDE=\"$htslib_include\" \
	BOOST_INCLUDE=\"$boost_include\" \
	\
	LIBBLASR_LIB=\"$libblasr_libdir\" \
	LIBPBIHDF_LIB=\"$libpbihdf_libdir\" \
        LIBPBDATA_LIB=\"$libpbdata_libdir\" \
	PBBAM_LIB=\"$pbbam_libdir\" \
	HTSLIB_LIB=\"$htslib_libdir\" \
	HDF5_LIB=\"$hdf5_libdir\" \
	ZLIB_LIB=\"$zlib_libdir\" \
	\
	LIBBLASR_LIBFLAGS=\"$libblasr_libflags\" \
	LIBPBIHDF_LIBFLAGS=\"$libpbihdf_libflags\" \
        LIBPBDATA_LIBFLAGS=\"$libpbdata_libflags\" \
	PBBAM_LIBFLAGS=\"$pbbam_libflags\" \
	HTSLIB_LIBFLAGS=\"$htslib_libflags\" \
	HDF5_LIBFLAGS=\"$hdf5_libflags\" \
	ZLIB_LIBFLAGS=\"$zlib_libflags\" \
	\
	${1+"$@"}
}
install_build() {
    if ! $opt_no_sub_targets; then
	build;
    fi

    echo "Running $g_name 'install-build' target..."

    # clean install dir
    rm -rf "$g_installbuild_dir";
    mkdir -p "$g_installbuild_dir";

    # install bin executables
    mkdir "$g_installbuild_dir/bin"
    cp -a "${g_git_build_srcdir}/${g_name}"  "$g_installbuild_dir/bin"

    if $opt_mobs || $opt_shared; then
        # Hack the runtime libs if not running under mobs
	if ! $opt_mobs; then
	    echo "Copying runtime libs..."
	    rm -rf "$g_installbuild_dir/runtimelibs"

	    mkdir -p "$g_installbuild_dir/runtimelibs/libblasr/lib"
	    cp -a "$g_libblasr_rootdir_abs/lib/libblasr.so"*  "$g_installbuild_dir/runtimelibs/libblasr/lib"

	    mkdir -p "$g_installbuild_dir/runtimelibs/libpbdata/lib"
	    cp -a "$g_libpbdata_rootdir_abs/lib/libpbdata.so"*  "$g_installbuild_dir/runtimelibs/libpbdata/lib"

	    mkdir -p "$g_installbuild_dir/runtimelibs/pbbam/lib"
	    cp -a "$g_pbbam_rootdir_abs/lib/libpbbam.so"*  "$g_installbuild_dir/runtimelibs/pbbam/lib"

	    mkdir -p "$g_installbuild_dir/runtimelibs/htslib/lib"
	    cp -a "$g_htslib_rootdir_abs/lib/libhts.so"*  "$g_installbuild_dir/runtimelibs/htslib/lib"

	    mkdir -p "$g_installbuild_dir/runtimelibs/zlib/lib"
	    cp -a "$g_zlib_rootdir_abs/lib/libz.so"*  "$g_installbuild_dir/runtimelibs/zlib/lib"

	    mkdir -p "$g_installbuild_dir/runtimelibs/gcc/lib"
	    cp -a "$g_gcc_rootdir/x86_64-libc_2.5-linux-gnu/sysroot/lib/"libstdc++.so* "$g_installbuild_dir/runtimelibs/gcc/lib"
	    cp -a "$g_gcc_rootdir/x86_64-libc_2.5-linux-gnu/sysroot/lib/"libgcc_s.so* "$g_installbuild_dir/runtimelibs/gcc/lib"
	    cp -a "$g_gcc_rootdir/x86_64-libc_2.5-linux-gnu/sysroot/lib/"libgfortran.so* "$g_installbuild_dir/runtimelibs/gcc/lib"
	fi

        # Create the binwrap dir
	echo "Creating the binwrap-build wrappers..."
	rm -rf "$g_installbuild_dir/binwrap-build"
	mkdir -p "$g_installbuild_dir/binwrap-build"
	if $opt_mobs; then
	    rm -rf "$g_installbuild_dir/binwrap-deploy"
	    mkdir -p "$g_installbuild_dir/binwrap-deploy"
	fi

        # Create the binwrap wrappers
	binwrap_tmpl="$g_progdir/infiles/pbdagcon-binwrap.sh.tmpl"
	prognames=""
	prognames="$prognames $g_name"
	for i in $prognames; do
	    # build binwrap:
	    sed \
		-e "s,%PROGNAME%,$i," \
		-e "s,%TOPDIR_RELPROG%,$g_build_topdir_relprog," \
		-e "s,%LIBBLASR_RUNTIMELIB_RELTOP%,$g_libblasr_build_runtime_libdir_reltop," \
		-e "s,%LIBPBIHDF_RUNTIMELIB_RELTOP%,$g_libpbihdf_build_runtime_libdir_reltop," \
		-e "s,%LIBPBDATA_RUNTIMELIB_RELTOP%,$g_libpbdata_build_runtime_libdir_reltop," \
		-e "s,%PBBAM_RUNTIMELIB_RELTOP%,$g_pbbam_build_runtime_libdir_reltop," \
		-e "s,%HTSLIB_RUNTIMELIB_RELTOP%,$g_htslib_build_runtime_libdir_reltop," \
		-e "s,%HDF5_RUNTIMELIB_RELTOP%,$g_hdf5_build_runtime_libdir_reltop," \
		-e "s,%ZLIB_RUNTIMELIB_RELTOP%,$g_zlib_build_runtime_libdir_reltop," \
		-e "s,%GCC_RUNTIMELIB_RELTOP%,$g_gcc_build_runtime_libdir_reltop," \
		"$binwrap_tmpl" > "$g_installbuild_dir/binwrap-build/$i"
	    chmod a+x "$g_installbuild_dir/binwrap-build/$i"

	    # deploy binwrap:
	    if $opt_mobs; then
		sed \
		    -e "s,%PROGNAME%,$i," \
		    -e "s,%TOPDIR_RELPROG%,$g_deploy_topdir_relprog," \
		    -e "s,%LIBBLASR_RUNTIMELIB_RELTOP%,$g_libblasr_deploy_runtime_libdir_reltop," \
		    -e "s,%LIBPBIHDF_RUNTIMELIB_RELTOP%,$g_libpbihdf_deploy_runtime_libdir_reltop," \
		    -e "s,%LIBPBDATA_RUNTIMELIB_RELTOP%,$g_libpbdata_deploy_runtime_libdir_reltop," \
		    -e "s,%PBBAM_RUNTIMELIB_RELTOP%,$g_pbbam_deploy_runtime_libdir_reltop," \
		    -e "s,%HTSLIB_RUNTIMELIB_RELTOP%,$g_htslib_deploy_runtime_libdir_reltop," \
		    -e "s,%HDF5_RUNTIMELIB_RELTOP%,$g_hdf5_deploy_runtime_libdir_reltop," \
		    -e "s,%ZLIB_RUNTIMELIB_RELTOP%,$g_zlib_deploy_runtime_libdir_reltop," \
		    -e "s,%GCC_RUNTIMELIB_RELTOP%,$g_gcc_deploy_runtime_libdir_reltop," \
		    "$binwrap_tmpl" > "$g_installbuild_dir/binwrap-deploy/$i"
		chmod a+x "$g_installbuild_dir/binwrap-deploy/$i"
	    fi
	done
    fi
}
install_prod() {
    echo "Running $g_name 'install-prod' target..."
}
publish_build() {
    if ! $opt_no_sub_targets; then
	install_build;
    fi

    echo "Running $g_name 'publish-build' target..."

}
publish_prod() {
    if ! $opt_no_sub_targets; then
	install_prod;
    fi
    echo "Running $g_name 'cleanall' target..."

}


# ---- End of Module-specific code
# Common code from here on out, do not modify...

# ---- error handling
set -o errexit;
set -o posix;
set -o pipefail;
set -o errtrace;
unexpected_error() {
    local errstat=$?
    echo "${g_prog:-$(basename $0)}: Error! Encountered unexpected error at 'line $(caller)', bailing out..." 1>&2
    exit $errstat;
}
trap unexpected_error ERR;


g_prog=$(basename $0);
g_progdir=$(dirname $0);

# ---- usage

usage() {
  local exitstat=2;
  if [[ ! -z "$2" ]] ; then
      exitstat=$2;
  fi

  # Only redirect to stderr on non-zero exit status
  if [[ $exitstat -ne 0 ]] ; then
      exec 1>&2;
  fi

  if [[ ! -z "$1" ]] ; then
      echo "$g_prog: Error! $1" 1>&2;
  fi

  echo "Usage: $g_prog [--help] \\"
#  echo "              -t|--target buildtarget";
#  echo "         -t|--target     -- chef target to build (e.g. 'cookbookname::build')";
  echo "         --help          -- print this usage";
  echo "";

  # bash only:
  if [[ $exitstat -ne 0 ]] ; then
      echo "  at: $(caller)";
  fi
  exit $exitstat;
}

# ---- argument parsing

# Save off the original args, use as "${g_origargs[@]}" (with double quotes)
declare -a g_origargs;
g_origargs=( ${1+"$@"} )

opt_target_exist_check=false;
opt_no_sub_targets=false;
opt_process_all_deps=false;
opt_mobs=false;
opt_shared=false;
declare -a opt_additional_options;
declare -a opt_targets;
while [[ $# != 0 ]]; do
    opt="$1"; shift;
    case "$opt" in
	# Flag with no argument example:
	#   --flag|--fla|--fl|--f)
	#     opt_flag=true;;
	# Option with argument example:
	#   --arg|--ar|--a)
	#     [[ $# -eq 0 ]] && usage;
	#     opt_somearg=$1; shift;;
	-e|--exists|--exist-check|--target-exist-check) opt_target_exist_check=true;;
	-s|--no-sub|--no-subs|--no-sub-targets|--single) opt_no_sub_targets=true;;
	-d|--deps|--process-all-deps|--all-deps|-all) opt_process_all_deps=true;;
	--mobs) opt_mobs=true;;
	--shared) opt_shared=true;;
	-o) 
	    [[ $# -eq 0 ]] && usage;
	    opt_additional_options=( "${opt_additional_options[@]}" "$1" );
	    shift;;
	-h|-help|--help|--hel|--he|--h) usage "" 0;;
	--*) opt_targets=( "${opt_targets[@]}" "$opt" );;
	-*) usage "Unrecognized option: $opt";;
	*)  usage "Extra trailing arguments: $opt $@";;
    esac
done

# ---- error functions
merror() {
    echo "$g_prog: Error! ""$@" 1>&2;
    exit 1;
}
minterror() {
    echo "$g_prog: Internal Error! ""$@" 1>&2;
    exit 1;
}
mwarn() {
    echo "$g_prog: Warning! ""$@" 1>&2;
}

# ---- globals

# ---- subroutines

munge_target() {
    local target=$1; shift;
    local mtarget=$target;
    
    mtarget=${mtarget#--}
    mtarget=${mtarget//-/_}
    echo "$mtarget"
}

# ---- main

set_globals;

warnings=false;
for target in "${opt_targets[@]}"; do
    mtarget=$(munge_target "$target");
    if ! declare -f -F "$mtarget" > /dev/null; then
	if $opt_strict; then
	    mwarn "target '$target' does not exist"
	    warnings=true;
	else
	    echo "$g_prog: target '$target' does not exist"
	fi
    fi
done
if $warnings; then
    merror "Detected warnings, bailing out..."
fi	

if ! $opt_target_exist_check; then
    for target in "${opt_targets[@]}"; do
	mtarget=$(munge_target "$target");
	eval "$mtarget" "${opt_additional_options[@]}"
    done
fi

exit 0;
