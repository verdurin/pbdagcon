#!/usr/bin/env python
"""Configure the build.

- Fetch boost/gtest.
- Create defines.mk
"""
import argparse
import commands
import contextlib
import os
import sys

PBDAGCON_ROOT = '${PBDAGCON_ROOT}'

def log(msg):
    sys.stderr.write(msg)
    sys.stderr.write('\n')

def system(cmd):
    log(cmd)
    status = os.system(cmd)
    if status:
        raise Exception('%d <- %r' %(status, cmd))
    return

def shell(cmd):
    log(cmd)
    status, output = commands.getstatusoutput(cmd)
    if status:
        raise Exception('%d <-| %r' %(status, cmd))
    return output


@contextlib.contextmanager
def cd(nwd):
    cwd = os.getcwd()
    log('cd %r -> %r' %(cwd, nwd))
    os.chdir(nwd)
    yield
    os.chdir(cwd)
    log('cd %r <- %r' %(cwd, nwd))

def fetch_gtest():
    gtest_version = 'gtest-1.7.0'
    gtest_uri = 'https://googletest.googlecode.com/files/%s.zip' %gtest_version
    gdir = os.path.join('test', 'cpp', gtest_version)
    if not os.path.isdir(gdir):
        zipfile = gdir + '.zip'
        if not os.path.isfile(zipfile):
            get_gtest_cmd = 'curl -L %s --output %s' %(gtest_uri, zipfile)
            system(get_gtest_cmd)
        install_gtest_cmd = 'unzip -q %s -d %s' %(zipfile, os.path.join('test', 'cpp'))
        system(install_gtest_cmd)
    assert os.path.isdir(gdir)
    return os.path.join(PBDAGCON_ROOT, gdir)

def fetch_boost_headers():
    """Fetch into ./src/cpp/third-party/
    Return actual directory path, relative to subdirs.
    """
    uri = 'https://www.dropbox.com/s/g22iayi83p5gbbq/boost_1_58_0-headersonly.tbz2?dl=0'
    hdir = os.path.join('src', 'cpp', 'third-party', 'boost_1_58_0-headersonly')
    if not os.path.isdir(hdir):
        #get_boost_cmd = 'curl -L %s | tar xjf -C src/cpp/third-party -' %uri
        tbz = os.path.join('src', 'cpp', 'third-party', 'boost_1_58_0-headersonly.tbz2')
        if not os.path.isfile(tbz):
            get_boost_cmd = 'curl -L %s --output %s' %(uri, tbz)
            system(get_boost_cmd)
        install_boost_cmd = 'tar vxjf %s -C src/cpp/third-party | head' %tbz
        system(install_boost_cmd)
    assert os.path.isdir(hdir)
    return os.path.join(PBDAGCON_ROOT, hdir)

def update_content(fn, content):
    current_content = open(fn).read() if os.path.exists(fn) else None
    if content != current_content:
        log('writing to %r' %fn)
        log('"""\n' + content + '"""')
        open(fn, 'w').write(content)

def compose_defines_with_hdf_headers(HDF_HEADERS):
    thisdir = os.path.dirname(os.path.abspath(__file__))
    return """
HDF_HEADERS:=%(HDF_HEADERS)s
#HDF5_INCLUDE?=${HDF_HEADERS}/src
CPPFLAGS+=-I${HDF_HEADERS}/src -I${HDF_HEADERS}/c++/src
CPPFLAGS+=-I../pbdata -I../hdf -I../alignment
LIBPBDATA_LIB     ?=../pbdata/libpbdata.so
LIBPBIHDF_LIB     ?=../pbdata/libpbihdf.so
LIBBLASR_LIB      ?=../pbdata/libblasr.so
"""%(dict(thisdir=thisdir, HDF_HEADERS=HDF_HEADERS))

def compose_defines():
    """
    Note that our local 'hdf' subdir will not even build
    in this case.
    """
    thisdir = os.path.dirname(os.path.abspath(__file__))
    return """
LIBPBDATA_INCLUDE ?=../pbdata
LIBPBIHDF_INCLUDE ?=../hdf
LIBBLASR_INCLUDE  ?=../alignment
LIBPBDATA_LIB     ?=%(thisdir)s/pbdata/libpbdata.so
LIBPBIHDF_LIB     ?=%(thisdir)s/pbdata/libpbihdf.so
LIBBLASR_LIB      ?=%(thisdir)s/pbdata/libblasr.so
nohdf             ?=1
"""%(dict(thisdir=thisdir))

def get_OS_STRING():
    G_BUILDOS_CMD = """bash -c 'set -e; set -o pipefail; id=$(lsb_release -si | tr "[:upper:]" "[:lower:]"); rel=$(lsb_release -sr); case $id in ubuntu) printf "$id-%04d\n" ${rel/./};; centos) echo "$id-${rel%%.*}";; *) echo "$id-$rel";; esac' 2>/dev/null"""
    return shell(G_BUILDOS_CMD)
def get_PREBUILT():
    cmd = 'cd ../../../../prebuilt.out 2>/dev/null && pwd || echo -n notfound'
    return shell(cmd)

def ifenvf(env, key, func):
    if key in env:
        return env[key]
    else:
        return func()
def setifenvf(envout, envin, key, func):
    envout[key] = ifenvf(envin, key, func)
def setifenv(envout, envin, key, val):
    envout[key] = envin.get(key, val)
def setenv(envout, key, val):
    envout[key] = val
def update_env_if(envout, envin, keys):
    for key in keys:
        if key in envin:
            envout[key] = envin[key]
def compose_defs_env(env):
    # We disallow env overrides for anything with a default from GNU make.
    nons = ['CXX', 'CC', 'AR'] # 'SHELL'?
    ovr    = ['%-20s ?= %s' %(k, v) for k,v in sorted(env.items()) if k not in nons]
    nonovr = ['%-20s := %s' %(k, v) for k,v in sorted(env.items()) if k in nons]
    return '\n'.join(ovr + nonovr + [''])
def compose_defines_pacbio(envin):
    """
    This is used by mobs via buildcntl.sh.
    """
    env = dict()
    #setifenv(env, envin, 'LIBPBDATA_INCLUDE', '../pbdata')
    #setifenv(env, envin, 'LIBPBIHDF_INCLUDE', '../hdf')
    #setifenv(env, envin, 'LIBBLASR_INCLUDE', '../alignment')
    #setifenv(env, envin, 'LIBPBDATA_LIB', '../pbdata/libpbdata.so')
    #setifenv(env, envin, 'LIBPBIHDF_LIB', '../hdf/libpbihdf.so')
    #setifenv(env, envin, 'LIBBLASR_LIB', '../alignment/libblasr.so')
    #setifenv(env, envin, 'nohdf', '1')
    possibs = set([
            'CC', 'CXX', 'AR',
            'GTEST_DIR',
            'LIBBLASR_INCLUDE', 'LIBBLASR_LIB', 'LIBBLASR_LIBFLAGS',
            'LIBPBDATA_INCLUDE', 'LIBPBDATA_LIB', 'LIBPBDATA_LIBFLAGS',
            'LIBPBIHDF_INCLUDE', 'LIBPBIHDF_LIB', 'LIBPBIHDF_LIBFLAGS',
            'HDF5_INCLUDE', 'HDF5_LIB', 'HDF5_LIBFLAGS',
            'PBBAM_INCLUDE', 'PBBAM_LIB', 'PBBAM_LIBFLAGS',
            'HTSLIB_INCLUDE', 'HTSLIB_LIB', 'HTSLIB_LIBFLAGS',
            'BOOST_INCLUDE',
            'ZLIB_LIB', 'ZLIB_LIBFLAGS',
    ])
    update_env_if(env, envin, possibs)
    return compose_defs_env(env)

def update(content_defines_mk):
    """ Write these relative to the same directory as *this* file.
    """
    thisdir = os.path.dirname(os.path.abspath(__file__))
    fn_defines_mk = os.path.join(thisdir, 'defines.mk')
    update_content(fn_defines_mk, content_defines_mk)

def configure_nopbbam():
    HDF_HEADERS = fetch_hdf5_headers()
    content1 = compose_defines_with_hdf_headers(HDF_HEADERS)
    update(content1)

def configure_nopbbam_nohdf5():
    content1 = compose_defines()
    update(content1)

def configure_pacbio(envin, shared):
    content1 = compose_defines_pacbio(envin)
    if shared:
        content1 += 'LDLIBS+=-lrt\n'
    update(content1)

def get_make_style_env(envin, args):
    envout = dict()
    for arg in args:
        if '=' in arg:
            k, v = arg.split('=')
            envout[k] = v
    envout.update(envin)
    return envout

def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('--boost-headers', action='store_true',
            help='Download Boost headers.')
    parser.add_argument('--gtest', action='store_true',
            help='Download google-test.')
    parser.add_argument('--no-pbbam', action='store_true',
            help='Avoid compiling anything which would need pbbam.')
    parser.add_argument('--submodules', action='store_true',
            help='Set variables to use our git-submodules, which must be pulled and built first. (Implies --no-pbbam.)')
    parser.add_argument('--shared', action='store_true',
            help='Build for dynamic linking.')
    parser.add_argument('--mode', default='opt',
            help='debug, opt, profile [default=%(default)s] CURRENTLY IGNORED')
    parser.add_argument('makevars', nargs='*',
            help='Variables in the style of make: FOO=val1 BAR=val2 etc.')
    return parser.parse_args(args)

def set_defs_defaults(env, nopbbam):
    defaults = {
        'LIBPBDATA_LIBFLAGS': '-lpbdata',
        'LIBBLASR_LIBFLAGS':  '-lblasr',
        'SHELL': 'bash -xe',
    }
    setifenvf(defaults, env, 'OS_STRING', get_OS_STRING)
    setifenvf(defaults, env, 'PREBUILT', get_PREBUILT)
    pbbam_defaults = {
        'LIBPBIHDF_LIBFLAGS': '-lpbihdf',
        'PBBAM_LIBFLAGS': '-lpbbam',
        'HTSLIB_LIBFLAGS': '-lhts',
        'HDF5_LIBFLAGS': '-lhdf5_cpp -lhdf5',
        'ZLIB_LIBFLAGS': '-lz',
        'PTHREAD_LIBFLAGS': '-lpthread',
        'DL_LIBFLAGS': '-ldl', # neeeded by HDF5 always
    }
    if not nopbbam:
        defaults.update(pbbam_defaults)
    for k in defaults:
        if k not in env:
            env[k] = defaults[k]

def set_defs_submodule_defaults(env, nopbbam):
    subdir = os.path.join(PBDAGCON_ROOT, 'blasr_libcpp')
    defaults = {
        'LIBPBDATA_INCLUDE': os.path.join(subdir, 'pbdata'),
        'LIBBLASR_INCLUDE':  os.path.join(subdir, 'alignment'),
        'LIBPBIHDF_INCLUDE': '' if nopbbam else os.path.join(subdir, 'hdf'),
        'LIBPBDATA_LIB': os.path.join(subdir, 'pbdata'),
        'LIBBLASR_LIB':  os.path.join(subdir, 'alignment'),
        'LIBPBIHDF_LIB': '' if nopbbam else os.path.join(subdir, 'hdf'),
    }
    for k in defaults:
        if k not in env:
            env[k] = defaults[k]

def main(prog, *args):
    """We are still deciding what env-vars to use, if any.
    """
    conf = parse_args(args)
    envin = get_make_style_env(os.environ, conf.makevars)
    if conf.boost_headers:
        envin['BOOST_INCLUDE'] = fetch_boost_headers()
    if conf.gtest:
        envin['GTEST_DIR'] = fetch_gtest()
    if conf.submodules:
        set_defs_submodule_defaults(envin, conf.no_pbbam)
        conf.no_pbbam = True
    set_defs_defaults(envin, conf.no_pbbam)
    configure_pacbio(envin, conf.shared)


if __name__=="__main__":
    main(*sys.argv)
