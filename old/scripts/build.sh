#!/bin/bash
# StealthKit Build Script - Optimized Version
# Usage: ./scripts/build.sh [debug|release] [--dmg]

set -euo pipefail

# Global variables
CREATE_DMG=false
BUILD_TYPE="Debug"

#######################################
# Remove previous build artifacts
#######################################
clean_build_artifacts() {
    echo "[INFO] Cleaning build artifacts..."
    rm -rf build compile_commands.json CMakeCache.txt CMakeFiles
    find . -type f \( -name ".DS_Store" -o -name "*.tmp" -o -name "*.temp" \) -delete 2>/dev/null || true
}

#######################################
# Parse command line arguments
#######################################
parse_arguments() {
    for arg in "$@"; do
        case $arg in
            --dmg)
                CREATE_DMG=true
                ;;
            debug)
                BUILD_TYPE="Debug"
                ;;
            release)
                BUILD_TYPE="Release"
                ;;
            *)
                echo "[ERROR] Unknown argument: $arg"
                echo "Usage: ./scripts/build.sh [debug|release] [--dmg]"
                exit 1
                ;;
        esac
    done
    
    # DMG creation only available for release builds
    if [[ "$CREATE_DMG" == "true" && "$BUILD_TYPE" != "Release" ]]; then
        echo "[ERROR] DMG creation is only available for release builds."
        exit 1
    fi
}

#######################################
# Run CMake configuration and build
#######################################
build_project() {
    local build_dir="build/$BUILD_TYPE"
    local jobs=$(sysctl -n hw.ncpu)

    echo "[INFO] Starting build: type=$BUILD_TYPE, jobs=$jobs"

    mkdir -p "$build_dir"
    cmake -B "$build_dir" \
          -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
          -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
          -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

    cmake --build "$build_dir" --parallel "$jobs"
    
    # Copy compile_commands.json if it exists
    [[ -f "$build_dir/compile_commands.json" ]] && cp "$build_dir/compile_commands.json" .
}

#######################################
# Code sign the application
#######################################
code_sign_app() {
    local app_path="build/$BUILD_TYPE/StealthKit.app"
    
    echo "[INFO] Code signing application..."
    
    if security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        codesign --force --deep --sign "Developer ID Application" "$app_path"
    else
        echo "[WARNING] Using ad-hoc signing (users will see security warnings)"
        codesign --force --deep --sign - "$app_path"
    fi
}

#######################################
# Create DMG installer
#######################################
create_dmg() {
    local app_path="build/$BUILD_TYPE/StealthKit.app"
    local dmg_staging="build/$BUILD_TYPE/dmg_staging"
    # local version=$(cmake --build "build/$BUILD_TYPE" --target help | grep -o 'StealthKit.*' | head -1 | cut -d' ' -f2 || echo "1.0")
    # local dmg_path="build/$BUILD_TYPE/StealthKit-${version}.dmg"
    local dmg_path="build/$BUILD_TYPE/StealthKit.dmg"
    
    echo "[INFO] Creating DMG installer..."
    
    # Prepare staging directory
    rm -rf "$dmg_staging"
    mkdir -p "$dmg_staging"
    cp -R "$app_path" "$dmg_staging/"
    ln -sf /Applications "$dmg_staging/Applications"
    
    # Create DMG directly
    rm -f "$dmg_path"
    hdiutil create -srcfolder "$dmg_staging" -volname "StealthKit" \
        -format UDZO -imagekey zlib-level=9 "$dmg_path"
    
    rm -rf "$dmg_staging"
    
    echo "[SUCCESS] DMG created: $dmg_path ($(du -h "$dmg_path" | cut -f1))"
}

#######################################
# Verify build and handle post-build tasks
#######################################
verify_and_report() {
    local app_path="build/$BUILD_TYPE/StealthKit.app"
    local binary_path="$app_path/Contents/MacOS/StealthKit"

    if [[ ! -x "$binary_path" ]]; then
        echo "[ERROR] Build failed: Application executable not found."
        exit 1
    fi

    echo "[SUCCESS] Build complete: $app_path"
    
    # Post-build tasks for release builds
    if [[ "$BUILD_TYPE" == "Release" ]]; then
        code_sign_app
        [[ "$CREATE_DMG" == "true" ]] && create_dmg
    fi
    
    echo "[INFO] To launch: open $app_path"
}

#######################################
# Main
#######################################
main() {
    clean_build_artifacts
    parse_arguments "$@"
    build_project
    verify_and_report
}

main "$@"