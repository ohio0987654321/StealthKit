# Stealth component CMakeLists.txt
# Phase 4: Stealth Features Implementation

set(STEALTH_SOURCES
    StealthManager.m
    WindowCloaking.m
    StatusBarController.m
)

set(STEALTH_HEADERS
    StealthManager.h
    WindowCloaking.h
    StatusBarController.h
)

# Add sources to main target
target_sources(StealthKit PRIVATE
    ${STEALTH_SOURCES}
    ${STEALTH_HEADERS}
)

# Add include directory
target_include_directories(StealthKit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

message(STATUS "Stealth component configured for Phase 4")
message(STATUS "  - StealthManager: Central stealth coordination")
message(STATUS "  - WindowCloaking: Screen capture evasion")
message(STATUS "  - StatusBarController: Background operation")
