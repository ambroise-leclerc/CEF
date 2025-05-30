cmake_minimum_required(VERSION 3.15)
project(CEF LANGUAGES CXX)

include(FetchContent)

# Detect platform and set CEF version and platform accordingly
# Using CEF version 118 which has good cross-platform support
set(CEF_VERSION "118.7.1+g99817d2+chromium-118.0.5993.119")

if(APPLE)
    # For macOS, use macosx64 for both Intel and Apple Silicon
    # CEF typically provides universal binaries or Intel binaries that work on both
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

# Display the URL being used for debugging
message(STATUS "CEF Platform: ${CEF_PLATFORM}")
message(STATUS "CEF URL: ${CEF_URL}")

# If the primary version fails, we could add fallback logic here
# For now, let's try with the specified version
FetchContent_Declare(
    cef
    URL      ${CEF_URL}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

# Add error handling for FetchContent
set(FETCHCONTENT_QUIET OFF)
FetchContent_MakeAvailable(cef)

# Verify that CEF was successfully downloaded and extracted
if(NOT EXISTS "${cef_SOURCE_DIR}/include/cef_version.h")
    message(FATAL_ERROR "CEF download failed or CEF headers not found. Please check the CEF version and platform compatibility.")
endif()

# Only build the minimal sanity test, do not build CEF sample apps or tests
# Do NOT remove CMakeLists.txt or tests from the CEF source tree, as this breaks the build system

# Debug: Show CEF source directory contents
message(STATUS "CEF source directory: ${cef_SOURCE_DIR}")
if(APPLE)
    message(STATUS "Contents of CEF source directory:")
    file(GLOB CEF_ROOT_FILES "${cef_SOURCE_DIR}/*")
    foreach(file ${CEF_ROOT_FILES})
        message(STATUS "  ${file}")
    endforeach()
    if(EXISTS "${cef_SOURCE_DIR}/Release")
        message(STATUS "Contents of Release directory:")
        file(GLOB CEF_RELEASE_FILES "${cef_SOURCE_DIR}/Release/*")
        foreach(file ${CEF_RELEASE_FILES})
            message(STATUS "  ${file}")
        endforeach()
    endif()
endif()

set(CEF_INCLUDE_DIR "${cef_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")

# Find and set the CEF library location with proper detection
if(APPLE)
    # On macOS, check multiple possible locations for libcef.dylib
    set(CEF_DYLIB_CANDIDATES 
        "${cef_SOURCE_DIR}/Debug/libcef.dylib"
        "${cef_SOURCE_DIR}/Release/libcef.dylib"
        "${cef_SOURCE_DIR}/libcef.dylib"
    )
    
    set(CEF_DYLIB_PATH "")
    foreach(candidate ${CEF_DYLIB_CANDIDATES})
        if(EXISTS "${candidate}")
            set(CEF_DYLIB_PATH "${candidate}")
            message(STATUS "Found libcef.dylib at: ${CEF_DYLIB_PATH}")
            break()
        endif()
    endforeach()
    
    if(NOT CEF_DYLIB_PATH)
        message(FATAL_ERROR "Could not find libcef.dylib in any expected location")
    endif()
    
    # Extract the directory for CEF_LIBRARY_DIR
    get_filename_component(CEF_LIBRARY_DIR "${CEF_DYLIB_PATH}" DIRECTORY CACHE)
else()
    # On Linux, libraries are typically in Release directory
    set(CEF_LIBRARY_DIR "${cef_SOURCE_DIR}/Release" CACHE STRING "Path to CEF library directory")
    set(CEF_SO_PATH "${CEF_LIBRARY_DIR}/libcef.so")
    if(NOT EXISTS "${CEF_SO_PATH}")
        message(FATAL_ERROR "Could not find libcef.so at ${CEF_SO_PATH}")
    endif()
endif()

# Create the main CEF interface library
add_library(cef INTERFACE)

# Define the libcef shared library target if not already defined
if(NOT TARGET libcef)
    add_library(libcef SHARED IMPORTED)
    if(APPLE)
        set_target_properties(libcef PROPERTIES IMPORTED_LOCATION "${CEF_DYLIB_PATH}")
    else()
        set_target_properties(libcef PROPERTIES IMPORTED_LOCATION "${CEF_SO_PATH}")
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
