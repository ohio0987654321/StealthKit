# WebKitLinking.cmake
# CMake module for WebKit framework linking

function(setup_webkit_linking target_name)
    # Ensure we're building for macOS
    if(NOT APPLE)
        message(FATAL_ERROR "WebKitLinking.cmake can only be used on macOS")
    endif()

    # Find required frameworks
    find_library(WEBKIT_FRAMEWORK WebKit)
    find_library(COCOA_FRAMEWORK Cocoa)
    find_library(FOUNDATION_FRAMEWORK Foundation)

    if(NOT WEBKIT_FRAMEWORK)
        message(FATAL_ERROR "WebKit framework not found")
    endif()

    if(NOT COCOA_FRAMEWORK)
        message(FATAL_ERROR "Cocoa framework not found")
    endif()

    if(NOT FOUNDATION_FRAMEWORK)
        message(FATAL_ERROR "Foundation framework not found")
    endif()

    # Link frameworks to target
    target_link_libraries(${target_name} PRIVATE
        ${WEBKIT_FRAMEWORK}
        ${COCOA_FRAMEWORK}
        ${FOUNDATION_FRAMEWORK}
    )

    # Add framework search paths
    target_link_directories(${target_name} PRIVATE
        /System/Library/Frameworks
        /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks
    )

    # Add include directories for framework headers
    target_include_directories(${target_name} PRIVATE
        /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/WebKit.framework/Headers
        /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Cocoa.framework/Headers
        /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Foundation.framework/Headers
    )

    # Set WebKit-specific compile definitions
    target_compile_definitions(${target_name} PRIVATE
        WEBKIT_API_AVAILABLE=1
    )

    message(STATUS "Configured WebKit framework linking for ${target_name}")
    message(STATUS "  WebKit: ${WEBKIT_FRAMEWORK}")
    message(STATUS "  Cocoa: ${COCOA_FRAMEWORK}")
    message(STATUS "  Foundation: ${FOUNDATION_FRAMEWORK}")
endfunction()

function(configure_webkit_privacy target_name)
    # Add privacy-focused WebKit configurations
    target_compile_definitions(${target_name} PRIVATE
        WK_PRIVATE_DATA_STORE=1
        WK_STEALTH_MODE=1
    )
    
    message(STATUS "Configured WebKit privacy settings for ${target_name}")
endfunction()
