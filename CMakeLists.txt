cmake_minimum_required(VERSION 3.15)
project(CEF LANGUAGES CXX)

include(FetchContent)

# Option to use a locally provided CEF archive
set(CEF_LOCAL_ARCHIVE_PATH "" CACHE STRING "Path to a locally provided CEF archive (leave empty to download)")

# Option to enable robust download with no timeouts
option(CEF_ROBUST_DOWNLOAD "Enable robust download strategy with no timeouts" ON)

# Minimum expected CEF archive size in bytes (e.g., 10 MB)
set(MIN_CEF_ARCHIVE_SIZE 10000000)

# Detect platform and set CEF version and platform accordingly
# Using CEF version 118 which has good cross-platform support
set(CEF_VERSION "118.7.1+g99817d2+chromium-118.0.5993.119")

if(APPLE)
    # Detect Apple Silicon vs Intel Mac
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE MACHINE_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    # For CEF 118.7.1, ARM64 builds may not be available, so we use Intel builds with Rosetta 2
    # This provides better compatibility and avoids download failures
    if(MACHINE_ARCH STREQUAL "arm64")
        set(CEF_PLATFORM "macosx64")  # Use Intel build on ARM64 (runs via Rosetta 2)
        message(STATUS "Detected Apple Silicon Mac - using Intel CEF binary (runs via Rosetta 2)")
        message(STATUS "Note: Native ARM64 CEF builds may not be available for version ${CEF_VERSION}")
    else()
        set(CEF_PLATFORM "macosx64")
        message(STATUS "Detected Intel Mac - using x64 CEF binary")
    endif()
    
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

# Choose source based on whether local archive is provided
if(CEF_USE_LOCAL_ARCHIVE AND EXISTS "${CEF_USE_LOCAL_ARCHIVE}")
    message(STATUS "Using local CEF archive: ${CEF_USE_LOCAL_ARCHIVE}")
    FetchContent_Declare(
        cef
        URL      ${CEF_USE_LOCAL_ARCHIVE}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
elseif(CEF_ROBUST_DOWNLOAD)
    message(STATUS "Using robust download strategy for CEF...")
    message(STATUS "CEF URL: ${CEF_URL}")
    message(STATUS "This may take several minutes for large downloads...")
    
    # Custom download function with robust handling
    function(robust_cef_download)
        set(CEF_DOWNLOAD_DIR "${CMAKE_BINARY_DIR}/_cef_download")
        set(CEF_ARCHIVE_PATH "${CEF_DOWNLOAD_DIR}/${CEF_DIST_NAME}.tar.bz2")
        
        # Create download directory
        file(MAKE_DIRECTORY "${CEF_DOWNLOAD_DIR}")
        
        # Check if already downloaded
        if(EXISTS "${CEF_ARCHIVE_PATH}")
            message(STATUS "CEF archive already exists, skipping download")
        else()
            message(STATUS "Downloading CEF archive to: ${CEF_ARCHIVE_PATH}")
              # Use file(DOWNLOAD) with reasonable timeout and progress reporting
            file(DOWNLOAD 
                "${CEF_URL}" 
                "${CEF_ARCHIVE_PATH}"
                TIMEOUT 1800                 # 30 minute timeout total
                INACTIVITY_TIMEOUT 300       # 5 minute inactivity timeout
                SHOW_PROGRESS               # Show download progress
                STATUS download_status
                LOG download_log
            )
            
            # Check download status
            list(GET download_status 0 status_code)
            list(GET download_status 1 status_string)
            
            if(NOT status_code EQUAL 0)
                message(STATUS "Download failed with status: ${status_code} - ${status_string}")
                message(STATUS "Download log: ${download_log}")
                  # Retry with curl if available, using more robust options
                find_program(CURL_EXECUTABLE curl)
                if(CURL_EXECUTABLE)
                    message(STATUS "Retrying download with curl using HTTP/1.1...")
                    execute_process(
                        COMMAND ${CURL_EXECUTABLE} 
                                -L                          # Follow redirects
                                --http1.1                   # Force HTTP/1.1 to avoid HTTP/2 issues
                                --retry 3                   # Retry failed downloads
                                --retry-delay 5             # Wait 5 seconds between retries
                                --max-time 1800             # 30 minute timeout total
                                --connect-timeout 60        # 60 second connection timeout
                                --progress-bar              # Show progress bar instead of verbose output
                                -o "${CEF_ARCHIVE_PATH}" 
                                "${CEF_URL}"
                        RESULT_VARIABLE curl_result
                        OUTPUT_VARIABLE curl_output
                        ERROR_VARIABLE curl_error
                    )
                      if(NOT curl_result EQUAL 0)
                        message(STATUS "Curl output: ${curl_output}")
                        message(STATUS "Curl failed with error (${curl_result}): ${curl_error}")
                        
                        # Try wget as a last resort
                        find_program(WGET_EXECUTABLE wget)
                        if(WGET_EXECUTABLE)
                            message(STATUS "Retrying download with wget...")
                            execute_process(
                                COMMAND ${WGET_EXECUTABLE} 
                                        --tries=3                   # Retry 3 times
                                        --wait=5                    # Wait 5 seconds between retries
                                        --timeout=1800              # 30 minute timeout
                                        --progress=bar              # Show progress
                                        -O "${CEF_ARCHIVE_PATH}" 
                                        "${CEF_URL}"
                                RESULT_VARIABLE wget_result
                                OUTPUT_VARIABLE wget_output
                                ERROR_VARIABLE wget_error
                            )
                            
                            if(NOT wget_result EQUAL 0)
                                message(STATUS "Wget output: ${wget_output}")
                                message(FATAL_ERROR "Failed to download CEF with CMake, curl, and wget. Wget error (${wget_result}): ${wget_error}. Please check your internet connection and the CEF URL: ${CEF_URL}")
                            endif()                        else()
                            # On Windows, try PowerShell as another fallback
                            if(WIN32)
                                message(STATUS "Retrying download with PowerShell...")
                                execute_process(
                                    COMMAND powershell -Command "
                                        $ProgressPreference = 'SilentlyContinue'
                                        try {
                                            Invoke-WebRequest -Uri '${CEF_URL}' -OutFile '${CEF_ARCHIVE_PATH}' -TimeoutSec 1800
                                            exit 0
                                        } catch {
                                            Write-Error $_.Exception.Message
                                            exit 1
                                        }"
                                    RESULT_VARIABLE powershell_result
                                    OUTPUT_VARIABLE powershell_output
                                    ERROR_VARIABLE powershell_error
                                )
                                
                                if(NOT powershell_result EQUAL 0)
                                    message(STATUS "PowerShell output: ${powershell_output}")
                                    message(FATAL_ERROR "Failed to download CEF with CMake, curl, and PowerShell. PowerShell error (${powershell_result}): ${powershell_error}. Please check your internet connection and the CEF URL: ${CEF_URL}")
                                endif()
                            else()
                                message(FATAL_ERROR "Failed to download CEF with CMake, curl, and wget. Please check your internet connection and the CEF URL: ${CEF_URL}")
                            endif()
                        endif()
                    endif()
                else()
                    message(FATAL_ERROR "Failed to download CEF: ${status_string}")
                endif()
            endif()
        endif()
        
        # Verify file exists and has reasonable size
        if(EXISTS "${CEF_ARCHIVE_PATH}")
            file(SIZE "${CEF_ARCHIVE_PATH}" archive_size)
            if(${archive_size} LESS ${MIN_CEF_ARCHIVE_SIZE}) 
                message(FATAL_ERROR "Downloaded CEF archive seems too small (${archive_size} bytes). Download may have failed.")
            endif()
            message(STATUS "CEF archive downloaded successfully (${archive_size} bytes)")
        else()
            message(FATAL_ERROR "CEF archive not found after download attempt")
        endif()
        
        # Set the archive path for FetchContent
        set(CEF_LOCAL_ARCHIVE "${CEF_ARCHIVE_PATH}" PARENT_SCOPE)
    endfunction()
    
    # Perform robust download
    robust_cef_download()
      # Use the downloaded archive
    FetchContent_Declare(
        cef_binaries
        URL      ${CEF_LOCAL_ARCHIVE}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )
else()
    # Standard download with reasonable timeout
    FetchContent_Declare(
        cef_binaries
        URL      ${CEF_URL}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        TIMEOUT  600  # 10 minutes timeout for large file
    )
endif()

# Add error handling for FetchContent
set(FETCHCONTENT_QUIET OFF)
FetchContent_GetProperties(cef_binaries)
if(NOT cef_binaries_POPULATED)
    message(STATUS "Extracting CEF binaries...")
    FetchContent_Populate(cef_binaries)
    message(STATUS "CEF binaries extracted to: ${cef_binaries_SOURCE_DIR}")
endif()

# Verify that CEF was successfully downloaded and extracted
if(NOT EXISTS "${cef_binaries_SOURCE_DIR}/include/cef_version.h")
    message(STATUS "CEF source directory: ${cef_binaries_SOURCE_DIR}")
    file(GLOB CEF_ROOT_FILES "${cef_binaries_SOURCE_DIR}/*")
    message(STATUS "Contents of CEF source directory:")
    foreach(file ${CEF_ROOT_FILES})
        message(STATUS "  ${file}")
    endforeach()
    message(FATAL_ERROR "CEF download failed or CEF headers not found. Please check the CEF version and platform compatibility.")
endif()

# Only build the minimal sanity test, do not build CEF sample apps or tests
# Do NOT remove CMakeLists.txt or tests from the CEF source tree, as this breaks the build system

# Debug: Show CEF source directory contents
if(DEBUG_MODE)
    message(STATUS "CEF source directory: ${cef_binaries_SOURCE_DIR}")
    if(APPLE)
        message(STATUS "Contents of CEF source directory:")
        file(GLOB CEF_ROOT_FILES "${cef_binaries_SOURCE_DIR}/*")
        foreach(file ${CEF_ROOT_FILES})
            message(STATUS "  ${file}")
        endforeach()
        if(EXISTS "${cef_binaries_SOURCE_DIR}/Release")
            message(STATUS "Contents of Release directory:")
            file(GLOB CEF_RELEASE_FILES "${cef_binaries_SOURCE_DIR}/Release/*")
            foreach(file ${CEF_RELEASE_FILES})
                message(STATUS "  ${file}")
            endforeach()
        endif()
    endif()
endif()

set(CEF_INCLUDE_DIR "${cef_binaries_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")

# Find and set the CEF library location with proper detection
if(APPLE)
    # On macOS, CEF is distributed as a framework, not individual dylib files
    set(CEF_FRAMEWORK_CANDIDATES 
        "${cef_binaries_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
        "${cef_binaries_SOURCE_DIR}/Debug/Chromium Embedded Framework.framework"
        "${cef_binaries_SOURCE_DIR}/Chromium Embedded Framework.framework"
    )
      set(CEF_FRAMEWORK_PATH "")
    foreach(candidate ${CEF_FRAMEWORK_CANDIDATES})
        message(STATUS "Checking for CEF framework at: ${candidate}")
        if(EXISTS "${candidate}")
            set(CEF_FRAMEWORK_PATH "${candidate}")
            message(STATUS "Found CEF framework at: ${CEF_FRAMEWORK_PATH}")
            break()
        else()
            message(STATUS "  Framework not found at this location")
        endif()
    endforeach()
    
    if(NOT CEF_FRAMEWORK_PATH)
        message(STATUS "Failed to find CEF framework. Debugging information:")
        message(STATUS "CEF source directory: ${cef_binaries_SOURCE_DIR}")
        file(GLOB CEF_ROOT_FILES "${cef_binaries_SOURCE_DIR}/*")
        message(STATUS "Contents of CEF source directory:")
        foreach(file ${CEF_ROOT_FILES})
            message(STATUS "  ${file}")
        endforeach()
        
        # Check Release directory specifically
        if(EXISTS "${cef_binaries_SOURCE_DIR}/Release")
            file(GLOB CEF_RELEASE_FILES "${cef_binaries_SOURCE_DIR}/Release/*")
            message(STATUS "Contents of Release directory:")
            foreach(file ${CEF_RELEASE_FILES})
                message(STATUS "  ${file}")
            endforeach()
        endif()
        
        message(FATAL_ERROR "Could not find Chromium Embedded Framework.framework in any expected location")
    endif()
      # Extract the directory for CEF_LIBRARY_DIR
    get_filename_component(CEF_LIBRARY_DIR "${CEF_FRAMEWORK_PATH}" DIRECTORY CACHE)
elseif(WIN32)
    # On Windows, libraries are typically in Release or Debug directory
    # Try to find the correct library directory
    set(CEF_LIBRARY_CANDIDATES 
        "${cef_binaries_SOURCE_DIR}/Release"
        "${cef_binaries_SOURCE_DIR}/Debug"
        "${cef_binaries_SOURCE_DIR}"
    )
      set(CEF_LIBRARY_DIR "")
    set(CEF_LIB_PATH "")
    set(CEF_DLL_PATH "")
      foreach(candidate ${CEF_LIBRARY_CANDIDATES})
        message(STATUS "Checking candidate: ${candidate}")
        if(EXISTS "${candidate}/libcef.lib")
            message(STATUS "  libcef.lib found")
        else()
            message(STATUS "  libcef.lib NOT found")
        endif()
        if(EXISTS "${candidate}/libcef.dll")
            message(STATUS "  libcef.dll found")
        else()
            message(STATUS "  libcef.dll NOT found")
        endif()
        
        if(EXISTS "${candidate}/libcef.lib" AND EXISTS "${candidate}/libcef.dll")
            set(CEF_LIBRARY_DIR "${candidate}")
            set(CEF_LIB_PATH "${CEF_LIBRARY_DIR}/libcef.lib")
            set(CEF_DLL_PATH "${CEF_LIBRARY_DIR}/libcef.dll")
            message(STATUS "Found CEF libraries at: ${CEF_LIBRARY_DIR}")
            break()
        endif()
    endforeach()
    
    if(NOT CEF_LIBRARY_DIR)
        # If we still can't find libraries, show debug info and fail
        message(STATUS "CEF source directory: ${cef_binaries_SOURCE_DIR}")
        file(GLOB CEF_ROOT_FILES "${cef_binaries_SOURCE_DIR}/*")
        message(STATUS "Contents of CEF source directory:")
        foreach(file ${CEF_ROOT_FILES})
            message(STATUS "  ${file}")
        endforeach()
        message(FATAL_ERROR "Could not find libcef.lib and libcef.dll in any expected location")
    endif()
else()
    # On Linux, libraries are typically in Release directory
    set(CEF_LIBRARY_DIR "${cef_binaries_SOURCE_DIR}/Release" CACHE STRING "Path to CEF library directory")
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
        $<BUILD_INTERFACE:${cef_binaries_SOURCE_DIR}>
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
        $<BUILD_INTERFACE:${cef_binaries_SOURCE_DIR}>
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
        $<BUILD_INTERFACE:${cef_binaries_SOURCE_DIR}>
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

# Ensure the CEF test is built by default when the parent project has testing enabled
# This prevents the "test not available without configuration" issue
if(TARGET cef_sanity_test)
    # Check if the parent project has testing enabled
    get_directory_property(PARENT_HAS_TESTING PARENT_DIRECTORY BUILDSYSTEM_TARGETS)
    if(PARENT_HAS_TESTING OR BUILD_TESTING OR CMAKE_TESTING_ENABLED)
        # Make the test target build by default (remove EXCLUDE_FROM_ALL)
        set_target_properties(cef_sanity_test PROPERTIES
            EXCLUDE_FROM_ALL FALSE
        )
        message(STATUS "CEF test will be built by default when parent project builds")
    endif()
endif()

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
install(DIRECTORY "${cef_binaries_SOURCE_DIR}/include/" 
        DESTINATION include 
        FILES_MATCHING PATTERN "*.h")

install(EXPORT CEFTargets FILE CEFTargets.cmake NAMESPACE CEF:: DESTINATION lib/cmake/CEF)
install(FILES 
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake" 
    DESTINATION lib/cmake/CEF)
