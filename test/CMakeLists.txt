cmake_minimum_required(VERSION 3.15)
project(cef_test LANGUAGES CXX)

add_executable(cef_sanity_test main.cpp)
# CEF headers expect the source directory as the include root, not just the include subdirectory
target_include_directories(cef_sanity_test PRIVATE ${cef_SOURCE_DIR})
target_link_directories(cef_sanity_test PRIVATE ${CEF_LIBRARY_DIR})

# Link against the CEF targets defined in the main CMakeLists.txt
target_link_libraries(cef_sanity_test PRIVATE libcef)

# Try to link the CEF DLL wrapper if it was built
if(TARGET libcef_dll_wrapper)
    target_link_libraries(cef_sanity_test PRIVATE libcef_dll_wrapper)
endif()

# Platform-specific system libraries
find_package(Threads REQUIRED)
target_link_libraries(cef_sanity_test PRIVATE Threads::Threads)

if(APPLE)
    # macOS-specific frameworks
    find_library(COCOA_FRAMEWORK Cocoa)
    find_library(COREFOUNDATION_FRAMEWORK CoreFoundation)
    target_link_libraries(cef_sanity_test PRIVATE ${COCOA_FRAMEWORK} ${COREFOUNDATION_FRAMEWORK})
endif()

add_test(NAME cef_sanity_test COMMAND cef_sanity_test)
