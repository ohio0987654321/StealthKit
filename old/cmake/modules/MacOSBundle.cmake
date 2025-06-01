# MacOSBundle.cmake
# CMake module for macOS app bundle configuration

function(configure_macos_bundle target_name)
    # Ensure we're building for macOS
    if(NOT APPLE)
        message(FATAL_ERROR "MacOSBundle.cmake can only be used on macOS")
    endif()

    # Set bundle properties
    set_target_properties(${target_name} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_BUNDLE_NAME "StealthKit"
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.stealthkit.browser"
        MACOSX_BUNDLE_EXECUTABLE_NAME "StealthKit"
    )

    # Create app bundle structure
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory 
            "$<TARGET_BUNDLE_DIR:${target_name}>/Contents/Resources"
        COMMENT "Creating app bundle directory structure"
    )

    # Set minimum deployment target
    target_compile_definitions(${target_name} PRIVATE
        MAC_OS_X_VERSION_MIN_REQUIRED=120000  # macOS 12.0
    )

    message(STATUS "Configured macOS app bundle for ${target_name}")
endfunction()

function(add_app_icon target_name icon_path)
    if(EXISTS ${icon_path})
        # Copy app icon to bundle
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${icon_path}
                "$<TARGET_BUNDLE_DIR:${target_name}>/Contents/Resources/AppIcon.appiconset"
            COMMENT "Adding app icon to bundle"
        )
        message(STATUS "Added app icon from ${icon_path}")
    else()
        message(WARNING "App icon not found at ${icon_path}")
    endif()
endfunction()

function(add_bundle_resources target_name resources_dir)
    if(EXISTS ${resources_dir})
        # Copy all resources to bundle
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${resources_dir}
                "$<TARGET_BUNDLE_DIR:${target_name}>/Contents/Resources"
            COMMENT "Copying resources to app bundle"
        )
        message(STATUS "Added resources from ${resources_dir}")
    else()
        message(WARNING "Resources directory not found at ${resources_dir}")
    endif()
endfunction()
