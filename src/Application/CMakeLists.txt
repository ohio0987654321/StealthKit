# Application component CMakeLists.txt

set(APPLICATION_SOURCES
    main.m
    AppDelegate.m
)

set(APPLICATION_HEADERS
    AppDelegate.h
)

# Add sources to main target
target_sources(StealthKit PRIVATE
    ${APPLICATION_SOURCES}
    ${APPLICATION_HEADERS}
)

# Add include directory
target_include_directories(StealthKit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

message(STATUS "Added Application component sources")
