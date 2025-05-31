# CompilerFlags.cmake
# CMake module for Clang compiler optimization and flags

function(configure_compiler_flags target_name)
    # Ensure we're using Clang
    if(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang" OR NOT CMAKE_OBJC_COMPILER_ID STREQUAL "Clang")
        message(WARNING "StealthKit is optimized for Clang compiler")
    endif()

    # Base compiler flags for all configurations
    target_compile_options(${target_name} PRIVATE
        # Objective-C specific flags
        -fobjc-arc                          # Enable ARC
        -fobjc-weak                         # Enable weak references
        -fmodules                           # Enable modules
        -fcxx-modules                       # Enable C++ modules
        
        # Warning flags
        -Wall                               # Enable most warnings
        -Wextra                             # Extra warnings
        -Wpedantic                          # Pedantic warnings
        -Wno-unused-parameter              # Ignore unused parameters (common in delegates)
        -Wno-gnu-zero-variadic-macro-arguments  # Ignore GNU extension warnings
        -Wno-gnu-conditional-omitted-operand   # Allow ?: with omitted middle operand
        
        # Security flags
        -fstack-protector-strong           # Stack protection
        -U_FORTIFY_SOURCE                  # Undefine if already defined
        -D_FORTIFY_SOURCE=2                # Buffer overflow protection
        
        # Performance flags
        -ffast-math                        # Fast math optimizations
        -funroll-loops                     # Loop unrolling
    )

    # Configuration-specific flags
    target_compile_options(${target_name} PRIVATE
        $<$<CONFIG:Debug>:
            -O0                            # No optimization
            -g3                            # Full debug info
            -DDEBUG=1                      # Debug flag
            -DSTEALTH_DEBUG=1              # StealthKit debug mode
            -fsanitize=address             # Address sanitizer
            -fsanitize=undefined           # Undefined behavior sanitizer
        >
        $<$<CONFIG:Release>:
            -O3                            # Maximum optimization
            -DNDEBUG                       # No debug
            -flto                          # Link-time optimization
            -fvisibility=hidden            # Hide symbols by default
        >
        $<$<CONFIG:RelWithDebInfo>:
            -O2                            # Moderate optimization
            -g1                            # Minimal debug info
            -DNDEBUG                       # No debug
        >
    )

    # Linker flags
    target_link_options(${target_name} PRIVATE
        $<$<CONFIG:Debug>:
            -fsanitize=address             # Address sanitizer linking
            -fsanitize=undefined           # Undefined behavior sanitizer linking
        >
        $<$<CONFIG:Release>:
            -flto                          # Link-time optimization
            -Wl,-dead_strip               # Remove dead code
            -Wl,-x                        # Remove local symbols
        >
    )

    # macOS-specific flags
    if(APPLE)
        target_compile_options(${target_name} PRIVATE
            -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}
        )
        
        target_link_options(${target_name} PRIVATE
            -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}
        )
    endif()

    # StealthKit-specific definitions
    target_compile_definitions(${target_name} PRIVATE
        STEALTHKIT_VERSION_MAJOR=${PROJECT_VERSION_MAJOR}
        STEALTHKIT_VERSION_MINOR=${PROJECT_VERSION_MINOR}
        STEALTHKIT_VERSION_PATCH=${PROJECT_VERSION_PATCH}
        STEALTHKIT_VERSION_STRING="${PROJECT_VERSION}"
    )

    message(STATUS "Configured compiler flags for ${target_name}")
    message(STATUS "  Compiler: ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
    message(STATUS "  Build Type: ${CMAKE_BUILD_TYPE}")
endfunction()

function(enable_static_analysis target_name)
    # Enable Clang static analyzer
    target_compile_options(${target_name} PRIVATE
        --analyze                          # Enable static analysis
        -Xanalyzer -analyzer-output=text   # Text output format
    )
    
    message(STATUS "Enabled static analysis for ${target_name}")
endfunction()

function(configure_sanitizers target_name)
    # Additional sanitizer options for development
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_options(${target_name} PRIVATE
            -fsanitize=thread              # Thread sanitizer (alternative to address)
            -fsanitize=memory              # Memory sanitizer
            -fno-omit-frame-pointer        # Keep frame pointers for better stack traces
        )
        
        target_link_options(${target_name} PRIVATE
            -fsanitize=thread
            -fsanitize=memory
        )
        
        message(STATUS "Configured additional sanitizers for ${target_name}")
    endif()
endfunction()
