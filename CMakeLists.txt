cmake_minimum_required(VERSION 3.15)
project(CEF LANGUAGES CXX)

include(FetchContent)

# Detect platform and set CEF version and platform accordingly
set(CEF_VERSION "137.0.4+g8614a8d+chromium-137.0.7151.6")

if(APPLE)
    set(CEF_PLATFORM "macosx64")
    set(CEF_LIBRARY_EXTENSION "dylib")
elseif(UNIX)
    set(CEF_PLATFORM "linux64")
    set(CEF_LIBRARY_EXTENSION "so")
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

set(CEF_DIST_NAME "cef_binary_${CEF_VERSION}_${CEF_PLATFORM}")
set(CEF_URL "https://cef-builds.spotifycdn.com/${CEF_DIST_NAME}.tar.bz2")

FetchContent_Declare(
    cef
    URL      ${CEF_URL}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(cef)

# Only build the minimal sanity test, do not build CEF sample apps or tests
# Do NOT remove CMakeLists.txt or tests from the CEF source tree, as this breaks the build system

set(CEF_INCLUDE_DIR "${cef_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")
set(CEF_LIBRARY_DIR "${cef_SOURCE_DIR}/Release" CACHE STRING "Path to CEF library directory")

# Create the main CEF interface library
add_library(cef INTERFACE)

# Define the libcef shared library target if not already defined
if(NOT TARGET libcef)
    add_library(libcef SHARED IMPORTED)
    if(APPLE)
        set_target_properties(libcef PROPERTIES IMPORTED_LOCATION ${CEF_LIBRARY_DIR}/libcef.dylib)
    else()
        set_target_properties(libcef PROPERTIES IMPORTED_LOCATION ${CEF_LIBRARY_DIR}/libcef.${CEF_LIBRARY_EXTENSION})
    endif()
endif()

target_link_libraries(cef INTERFACE libcef)

# Build the CEF dll wrapper if it exists (for static linking)
if(EXISTS "${cef_BINARY_DIR}/libcef_dll_wrapper/CMakeLists.txt")
    add_subdirectory(${cef_BINARY_DIR}/libcef_dll_wrapper libcef_dll_wrapper_build EXCLUDE_FROM_ALL)
    set(CEF_DLL_WRAPPER_LIB ${cef_BINARY_DIR}/libcef_dll_wrapper/libcef_dll_wrapper.a)
else()
    set(CEF_DLL_WRAPPER_LIB "")
endif()

add_subdirectory(test)

# The cef_sanity_test target definition has been moved to test/CMakeLists.txt.

enable_testing()
# The cef_sanity_test test command has been moved to test/CMakeLists.txt.

# Install config for CPM consumers
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake"
    VERSION ${CEF_VERSION}
    COMPATIBILITY AnyNewerVersion
)
install(TARGETS cef EXPORT CEFTargets)
install(EXPORT CEFTargets FILE CEFTargets.cmake NAMESPACE CEF:: DESTINATION lib/cmake/CEF)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake" DESTINATION lib/cmake/CEF)
