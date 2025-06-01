# Utilities component CMakeLists.txt
# Phase 3: Smart Address Bar Implementation

set(UTILITIES_SOURCES
    URLHelper.m
    SearchEngineManager.m
    ShortcutManager.m
)

set(UTILITIES_HEADERS
    URLHelper.h
    SearchEngineManager.h
    ShortcutManager.h
)

# Add sources to main target
target_sources(StealthKit PRIVATE
    ${UTILITIES_SOURCES}
    ${UTILITIES_HEADERS}
)

# Add include directory
target_include_directories(StealthKit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

message(STATUS "Utilities component configured for Phase 3")
message(STATUS "  - URLHelper: Smart URL detection")
message(STATUS "  - SearchEngineManager: Configurable search engines")
message(STATUS "  - ShortcutManager: Centralized keyboard shortcuts")
