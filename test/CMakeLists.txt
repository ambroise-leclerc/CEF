cmake_minimum_required(VERSION 3.15)
project(cef_test LANGUAGES CXX)

add_executable(cef_sanity_test main.cpp)
# CEF headers expect the source directory as the include root, not just the include subdirectory
target_include_directories(cef_sanity_test PRIVATE ${cef_SOURCE_DIR})
target_link_directories(cef_sanity_test PRIVATE ${CEF_LIBRARY_DIR})

# Define imported targets for CEF libraries only if not already defined
if(NOT TARGET libcef)
    add_library(libcef SHARED IMPORTED)
    if(APPLE)
        set_target_properties(libcef PROPERTIES IMPORTED_LOCATION ${CEF_LIBRARY_DIR}/libcef.dylib)
    else()
        set_target_properties(libcef PROPERTIES IMPORTED_LOCATION ${CEF_LIBRARY_DIR}/libcef.so)
    endif()
endif()

if(NOT TARGET libcef_dll_wrapper)
    add_library(libcef_dll_wrapper STATIC IMPORTED)
    set_target_properties(libcef_dll_wrapper PROPERTIES IMPORTED_LOCATION ${CMAKE_BINARY_DIR}/_deps/cef-build/libcef_dll_wrapper/libcef_dll_wrapper.a)
endif()

# Link the imported targets to the executable
target_link_libraries(cef_sanity_test PRIVATE libcef libcef_dll_wrapper)

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
