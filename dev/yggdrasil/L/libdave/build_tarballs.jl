using BinaryBuilder, Pkg

const YGGDRASIL_DIR = "../.."
include(joinpath(YGGDRASIL_DIR, "platforms", "macos_sdks.jl"))

name = "libdave"
version = v"1.2.2"

sources = [
    GitSource("https://github.com/discord/libdave.git",
              "6396c90aedbb9a6ee117ea9ce1ce9832af6a3375";
              tag="v$(version)/cpp"),
]

script = raw"""
cd ${WORKSPACE}/srcdir/libdave/cpp
# OpenSSL_jll keeps the 64-bit MinGW import libraries in lib64
if [[ ${target} == x86_64-*-mingw* ]]; then
    export OPENSSL_ROOT_DIR=${prefix}/lib64
fi
cmake -B build \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DPERSISTENT_KEYS=OFF \
    -DTESTING=OFF
cmake --build build --parallel ${nproc}
cmake --install build
install_license ../LICENSE
"""

# std::variant's throwing accessors need libc++ from macOS 10.14
sources, script = require_macos_sdk("10.14", sources, script)

platforms = expand_cxxstring_abis(supported_platforms())

products = [
    # Upstream names it libdave off Windows, which MinGW turns into liblibdave.dll
    LibraryProduct(["libdave", "liblibdave"], :libdave),
]

dependencies = [
    Dependency("mlspp_jll";
               compat="0.1.1"),
    Dependency("OpenSSL_jll";
               compat="3.0.16"),
    BuildDependency("nlohmann_json_jll"),
    Dependency("CompilerSupportLibraries_jll";
               compat="1.1.2",
               platforms=filter(!Sys.isbsd, platforms)),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat="1.6",
               preferred_gcc_version=v"8")
