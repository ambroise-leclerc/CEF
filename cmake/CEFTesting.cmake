# CEFTesting.cmake
# Handles enabling testing and adding the test target

enable_testing()
add_subdirectory(test)

# Ensure the CEF test is built by default when the parent project has testing enabled
if(TARGET cef_sanity_test)
    get_directory_property(PARENT_HAS_TESTING PARENT_DIRECTORY BUILDSYSTEM_TARGETS)
    if(PARENT_HAS_TESTING OR BUILD_TESTING OR CMAKE_TESTING_ENABLED)
        set_target_properties(cef_sanity_test PROPERTIES EXCLUDE_FROM_ALL FALSE)
        message(STATUS "CEF test will be built by default when parent project builds")
    endif()
endif()
