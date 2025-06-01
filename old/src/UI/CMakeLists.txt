# UI component CMakeLists.txt

set(UI_SOURCES
    AddressBarView.m
    ToolbarView.m
    TabBarView.m
    UIManager.m
    # TODO: Add in later phases:
    # MenuBuilder.m
    # StatusBarController.m
)

set(UI_HEADERS
    AddressBarView.h
    ToolbarView.h
    TabBarView.h
    UIManager.h
    # TODO: Add in later phases:
    # MenuBuilder.h
    # StatusBarController.h
)

# Add sources to main target
target_sources(StealthKit PRIVATE
    ${UI_SOURCES}
    ${UI_HEADERS}
)

# Add include directory
target_include_directories(StealthKit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Link required frameworks
target_link_libraries(StealthKit PRIVATE
    "-framework Cocoa"
    "-framework QuartzCore"
)

message(STATUS "UI component configured for Phase 2")
