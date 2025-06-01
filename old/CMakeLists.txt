cmake_minimum_required(VERSION 3.25)
project(StealthKit VERSION 1.0.0 LANGUAGES C OBJC)

# macOS Configuration
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")
set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")
set(CMAKE_MACOSX_BUNDLE YES)

# Include custom modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")
include(MacOSBundle)
include(WebKitLinking)
include(CompilerFlags)

# Define main executable as macOS bundle
add_executable(StealthKit MACOSX_BUNDLE)

# Set executable properties
set_target_properties(StealthKit PROPERTIES
    MACOSX_BUNDLE_BUNDLE_NAME "StealthKit"
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE_IDENTIFIER "com.stealthkit.browser"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.stealthkit.browser"
    MACOSX_BUNDLE_EXECUTABLE_NAME "StealthKit"
    MACOSX_BUNDLE_COPYRIGHT "© 2025 StealthKit"
    MACOSX_BUNDLE_INFO_STRING "StealthKit - Privacy-Focused Browser"
)

# Add source directories
add_subdirectory(src/Application)
add_subdirectory(src/Browser)
add_subdirectory(src/UI)
add_subdirectory(src/Stealth)
add_subdirectory(src/Utilities)

# Configure app bundle
configure_macos_bundle(StealthKit)
setup_webkit_linking(StealthKit)
configure_compiler_flags(StealthKit)

# Generate Info.plist from template
configure_file(
    ${CMAKE_SOURCE_DIR}/resources/Info.plist.in
    ${CMAKE_CURRENT_BINARY_DIR}/Info.plist
    @ONLY
)

# Set the Info.plist for the bundle
set_target_properties(StealthKit PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_BINARY_DIR}/Info.plist
)

# Copy entitlements file for development builds
configure_file(
    ${CMAKE_SOURCE_DIR}/resources/Entitlements.plist
    ${CMAKE_CURRENT_BINARY_DIR}/Entitlements.plist
    COPYONLY
)

# Set app icon
set_target_properties(StealthKit PROPERTIES
    MACOSX_BUNDLE_ICON_FILE "AppIcon.icns"
)

# Copy icon to bundle Resources
set(APP_ICON_PATH "${CMAKE_SOURCE_DIR}/resources/icons/AppIcon.icns")
if(EXISTS "${APP_ICON_PATH}")
    set_source_files_properties("${APP_ICON_PATH}" PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
    target_sources(StealthKit PRIVATE "${APP_ICON_PATH}")
endif()

# Enable compile commands export for VSCode IntelliSense
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Print build summary
message(STATUS "StealthKit Configuration Summary:")
message(STATUS "  Version: ${PROJECT_VERSION}")
message(STATUS "  Target: macOS ${CMAKE_OSX_DEPLOYMENT_TARGET}+")
message(STATUS "  Architectures: ${CMAKE_OSX_ARCHITECTURES}")
message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
