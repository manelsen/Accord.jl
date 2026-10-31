# Draft Yggdrasil recipe for libdave_jll (Discord's DAVE library, C API).
# Untested on BinaryBuilder: submit to JuliaPackaging/Yggdrasil as
# L/libdave/build_tarballs.jl and iterate there. Once libdave_jll exists,
# Accord can depend on it and drop the ACCORD_LIBDAVE requirement.
#
# libdave builds with vcpkg upstream; here vcpkg is bypassed. mlspp (the MLS
# implementation) is built from source at the commit libdave pins in
# cpp/vcpkg-alts/overlay-ports/mlspp/vcpkg.json, against OpenSSL_jll.
using BinaryBuilder, Pkg

name = "libdave"
version = v"1.2.2"

sources = [
    GitSource("https://github.com/discord/libdave.git",
              "6396c90aedbb9a6ee117ea9ce1ce9832af6a3375"),   # tag v1.2.2/cpp
    GitSource("https://github.com/cisco/mlspp.git",
              "1cc50a124a3bc4e143a787ec934280dc70c1034d"),
]

script = raw"""
# --- mlspp (static, PIC, so it ends up inside libdave) ---
cd ${WORKSPACE}/srcdir/mlspp
# Same trims as libdave's vcpkg overlay port
sed -i '/add_subdirectory(mls_ds)/d; /add_subdirectory(mls_vectors)/d' lib/CMakeLists.txt
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${WORKSPACE}/mlspp-install \
    -DCMAKE_PREFIX_PATH=${prefix} \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DDISABLE_GREASE=ON \
    -DMLS_CXX_NAMESPACE=mlspp \
    -DTESTING=OFF
cmake --build build --parallel ${nproc}
cmake --install build

# --- libdave (shared) ---
cd ${WORKSPACE}/srcdir/libdave/cpp
cmake -B build -G Ninja \
    -DCMAKE_INSTALL_PREFIX=${prefix} \
    -DCMAKE_PREFIX_PATH="${WORKSPACE}/mlspp-install;${prefix}" \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DTESTING=OFF \
    -DPERSISTENT_KEYS=OFF
cmake --build build --parallel ${nproc}
cmake --install build
install_license ${WORKSPACE}/srcdir/libdave/LICENSE
"""

# libdave needs C++20; mlspp and OpenSSL 3 rule out very old targets.
platforms = expand_cxxstring_abis(supported_platforms(; exclude = Sys.isfreebsd))

products = [
    LibraryProduct(["libdave", "dave"], :libdave),
]

dependencies = [
    Dependency("OpenSSL_jll"; compat = "3.0.8"),
    BuildDependency("nlohmann_json_jll"),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
               julia_compat = "1.10", preferred_gcc_version = v"12")
