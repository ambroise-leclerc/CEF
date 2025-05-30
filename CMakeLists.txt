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
elseif(WIN32)
    # For Windows, use windows64 platform
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(CEF_PLATFORM "windows64")
    else()
        set(CEF_PLATFORM "windows32")
    endif()
    set(CEF_LIBRARY_EXTENSION "dll")
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
if(DEBUG_MODE)
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
endif()

set(CEF_INCLUDE_DIR "${cef_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")

# Find and set the CEF library location with proper detection
if(APPLE)
    # On macOS, CEF is distributed as a framework, not individual dylib files
    set(CEF_FRAMEWORK_CANDIDATES 
        "${cef_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
        "${cef_SOURCE_DIR}/Debug/Chromium Embedded Framework.framework"
        "${cef_SOURCE_DIR}/Chromium Embedded Framework.framework"
    )
    
    set(CEF_FRAMEWORK_PATH "")
    foreach(candidate ${CEF_FRAMEWORK_CANDIDATES})
        if(EXISTS "${candidate}")
            set(CEF_FRAMEWORK_PATH "${candidate}")
            message(STATUS "Found CEF framework at: ${CEF_FRAMEWORK_PATH}")
            break()
        endif()
    endforeach()
    
    if(NOT CEF_FRAMEWORK_PATH)
        message(FATAL_ERROR "Could not find Chromium Embedded Framework.framework in any expected location")
    endif()
      # Extract the directory for CEF_LIBRARY_DIR
    get_filename_component(CEF_LIBRARY_DIR "${CEF_FRAMEWORK_PATH}" DIRECTORY CACHE)
elseif(WIN32)
    # On Windows, libraries are typically in Release or Debug directory
    set(CEF_LIBRARY_DIR "${cef_SOURCE_DIR}/${CMAKE_BUILD_TYPE}" CACHE STRING "Path to CEF library directory")
    set(CEF_LIB_PATH "${CEF_LIBRARY_DIR}/libcef.lib")
    set(CEF_DLL_PATH "${CEF_LIBRARY_DIR}/libcef.dll")
    if(NOT EXISTS "${CEF_LIB_PATH}")
        message(FATAL_ERROR "Could not find libcef.lib at ${CEF_LIB_PATH}")
    endif()
    if(NOT EXISTS "${CEF_DLL_PATH}")
        message(FATAL_ERROR "Could not find libcef.dll at ${CEF_DLL_PATH}")
    endif()
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

if(APPLE)
    # On macOS, link directly to the framework and include headers
    target_link_libraries(cef INTERFACE "${CEF_FRAMEWORK_PATH}/Chromium Embedded Framework")
    target_include_directories(cef INTERFACE 
        $<BUILD_INTERFACE:${cef_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
    )
    
    # Add required macOS system frameworks
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
    target_link_libraries(cef INTERFACE ${COCOA_FRAMEWORK} ${APPKIT_FRAMEWORK})
elseif(WIN32)
    # On Windows, link to the import library
    target_link_libraries(cef INTERFACE "${CEF_LIB_PATH}")
    target_include_directories(cef INTERFACE 
        $<BUILD_INTERFACE:${cef_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
    )
    
    # Add required Windows system libraries
    target_link_libraries(cef INTERFACE 
        comctl32.lib 
        rpcrt4.lib 
        shlwapi.lib 
        ws2_32.lib
        winmm.lib
        winspool.lib
        psapi.lib
    )
    
    # Define Windows-specific preprocessor definitions
    target_compile_definitions(cef INTERFACE 
        WIN32 
        _WIN32 
        _WINDOWS 
        UNICODE 
        _UNICODE
        NOMINMAX
        WIN32_LEAN_AND_MEAN
    )
else()
    # On Linux, link directly to the shared library
    target_link_libraries(cef INTERFACE "${CEF_SO_PATH}")
    target_include_directories(cef INTERFACE 
        $<BUILD_INTERFACE:${cef_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
    )
endif()

# Create a libcef target for backward compatibility but don't export it
add_library(libcef INTERFACE)
target_link_libraries(libcef INTERFACE cef)

# Build the CEF dll wrapper if it exists (for static linking)
if(EXISTS "${cef_BINARY_DIR}/libcef_dll_wrapper/CMakeLists.txt")
    add_subdirectory(${cef_BINARY_DIR}/libcef_dll_wrapper libcef_dll_wrapper_build EXCLUDE_FROM_ALL)
    if(WIN32)
        set(CEF_DLL_WRAPPER_LIB ${cef_BINARY_DIR}/libcef_dll_wrapper/libcef_dll_wrapper.lib)
    else()
        set(CEF_DLL_WRAPPER_LIB ${cef_BINARY_DIR}/libcef_dll_wrapper/libcef_dll_wrapper.a)
    endif()
else()
    set(CEF_DLL_WRAPPER_LIB "")
endif()

# Enable testing before adding test subdirectory
enable_testing()
add_subdirectory(test)

# The cef_sanity_test target definition has been moved to test/CMakeLists.txt.

# Install config for CPM consumers
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake"
    VERSION ${CEF_VERSION}
    COMPATIBILITY AnyNewerVersion
)

# Configure the config file
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/CEFConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfig.cmake"
    @ONLY
)

# Only export the main cef interface target
# This avoids issues with exporting target dependencies
install(TARGETS cef EXPORT CEFTargets)

# Install CEF headers for the exported target
install(DIRECTORY "${cef_SOURCE_DIR}/include/" 
        DESTINATION include 
        FILES_MATCHING PATTERN "*.h")

install(EXPORT CEFTargets FILE CEFTargets.cmake NAMESPACE CEF:: DESTINATION lib/cmake/CEF)
install(FILES 
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake" 
    DESTINATION lib/cmake/CEF)
