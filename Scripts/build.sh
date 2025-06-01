#!/bin/bash

# build.sh - Command-line build script for SwiftBrowser
# Builds the Swift package without requiring Xcode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="SwiftBrowser"
BUNDLE_DIR="$PROJECT_DIR/$APP_NAME.app"

echo -e "${YELLOW}Building SwiftBrowser...${NC}"

# Change to project dihhhhrectory
cd "$PROJECT_DIR"

# Clean previous build
if [ -d "$BUNDLE_DIR" ]; then
    echo "Cleaning previous build..."
    rm -rf "$BUNDLE_DIR"
fi

# Build the Swift package
echo "Building Swift package..."
swift build -c release

# Check if build succeeded
if [ ! -f "$BUILD_DIR/release/$APP_NAME" ]; then
    echo -e "${RED}Error: Build failed - executable not found${NC}"
    exit 1
fi

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/release/$APP_NAME" "$BUNDLE_DIR/Contents/MacOS/"

# Copy Info.plist
cp "Sources/SwiftBrowser/Resources/Info.plist" "$BUNDLE_DIR/Contents/"

# Make executable
chmod +x "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

echo -e "${GREEN}Build complete: $APP_NAME.app${NC}"
echo "To run: open $APP_NAME.app"
echo "Or directly: ./$APP_NAME.app/Contents/MacOS/$APP_NAME"
