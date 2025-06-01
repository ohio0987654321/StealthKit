# Browser component CMakeLists.txt

set(BROWSER_SOURCES
    BrowserWindow.m
    TabManager.m
)

set(BROWSER_HEADERS
    BrowserWindow.h
    TabManager.h
)

# Add sources to main target
target_sources(StealthKit PRIVATE
    ${BROWSER_SOURCES}
    ${BROWSER_HEADERS}
)

# Add include directory
target_include_directories(StealthKit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link required frameworks
target_link_libraries(StealthKit PRIVATE
    "-framework Cocoa"
    "-framework WebKit"
)

message(STATUS "Browser component configured")
