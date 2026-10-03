#!/bin/bash
set -euo pipefail
repository_dir="$(cd "$(dirname "$0")/../.." && pwd)"
output_dir="${1:?output directory required}"
configuration="${2:-Release}"
architectures="${3:-arm64}"
deployment_target="${MACOSX_DEPLOYMENT_TARGET:-26.0}"
sdk_path="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
[[ "$architectures" == "arm64" ]] || { echo "Zforge supports arm64 only" >&2; exit 1; }
mkdir -p "$output_dir"
libraries=()
for architecture in $architectures; do
    object_dir="$output_dir/$configuration/$architecture"
    mkdir -p "$object_dir"
    build_flags="$sdk_path|$deployment_target|$configuration|$architecture|asm=1"
    if [[ -f "$object_dir/configuration.txt" ]] && [[ "$(cat "$object_dir/configuration.txt")" != "$build_flags" ]]; then
        rm -f "$object_dir"/*.o "$object_dir"/*.d "$object_dir/libSevenZipCore.a"
    fi
    printf '%s' "$build_flags" > "$object_dir/configuration.txt"
    debug_flags="-g"
    [[ "$configuration" != "Debug" ]] || debug_flags="-g -O0"
    /usr/bin/make -C "$repository_dir/Vendor/7zip/CPP/7zip/Bundles/Format7zF" \
        -f "$repository_dir/BuildSupport/SevenZip/static.mk" -j "${SEVENZIP_BUILD_JOBS:-8}" \
        zforge-static O="$object_dir" CC="$(xcrun --find clang)" CXX="$(xcrun --find clang++)" \
        USE_CLANG=1 USE_ASM=1 IS_ARM64=1 MY_ARCH="-arch $architecture -isysroot $sdk_path -mmacosx-version-min=$deployment_target" \
        CXX_STD_FLAGS=-std=c++17 CFLAGS_DEBUG="$debug_flags" LFLAGS_NOEXECSTACK= \
        CFLAGS_BASE_LIST="-c -MMD -MP" > "$object_dir/build.log" 2>&1 || { tail -n 80 "$object_dir/build.log"; exit 1; }
    libraries+=("$object_dir/libSevenZipCore.a")
done
if [[ ! -f "$output_dir/libSevenZipCore.a" ]] || [[ "${libraries[0]}" -nt "$output_dir/libSevenZipCore.a" ]]; then
    xcrun lipo -create "${libraries[@]}" -output "$output_dir/libSevenZipCore.a"
fi
