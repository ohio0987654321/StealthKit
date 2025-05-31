#!/bin/bash
# StealthKit Build Script
# Usage: ./scripts/build.sh [debug|release]

set -euo pipefail

#######################################
# Remove previous build artifacts
#######################################
clean_build_artifacts() {
    echo "[INFO] Cleaning build artifacts..."

    rm -rf build compile_commands.json CMakeCache.txt CMakeFiles
    find . -type f \( -name ".DS_Store" -o -name "*.tmp" -o -name "*.temp" \) -delete 2>/dev/null || true

    echo "[INFO] Cleanup complete."
}

#######################################
# Determine and validate the build type
# Globals:
#   BUILD_TYPE
#######################################
set_build_type() {
    local input="${1:-debug}"
    input=$(echo "$input" | tr '[:upper:]' '[:lower:]')

    if [[ "$input" != "debug" && "$input" != "release" ]]; then
        echo "[ERROR] Invalid build type: '$input'. Use 'debug' or 'release'."
        exit 1
    fi

    # Capitalize first letter: "debug" -> "Debug"
    BUILD_TYPE="$(tr '[:lower:]' '[:upper:]' <<< ${input:0:1})${input:1}"
}

#######################################
# Run CMake configuration and build
#######################################
build_project() {
    local build_dir="build/$BUILD_TYPE"
    local jobs
    jobs=$(sysctl -n hw.ncpu)

    echo "[INFO] Starting build: type=$BUILD_TYPE, jobs=$jobs"

    mkdir -p "$build_dir"
    cmake -B "$build_dir" \
          -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
          -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64" \
          -DCMAKE_VERBOSE_MAKEFILE=OFF

    cmake --build "$build_dir" --parallel "$jobs"
}

#######################################
# Copy compile_commands.json if exists
#######################################
update_compile_commands() {
    cp "build/$BUILD_TYPE/compile_commands.json" . 2>/dev/null || true
    echo "[INFO] compile_commands.json updated."
}

#######################################
# Check if build succeeded and show result
#######################################
verify_and_report() {
    local app_path="build/$BUILD_TYPE/StealthKit.app"
    local binary_path="$app_path/Contents/MacOS/StealthKit"

    if [[ -x "$binary_path" ]]; then
        echo "[SUCCESS] Build complete: $app_path"
        echo "[INFO] To launch the application: open $app_path"
    else
        echo "[ERROR] Build failed: Application bundle or executable not found."
        exit 1
    fi
}

#######################################
# Main
#######################################
main() {
    clean_build_artifacts
    set_build_type "$@"
    build_project
    update_compile_commands
    verify_and_report
}

main "$@"
