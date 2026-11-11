# CEFPlatform.cmake
# Platform detection, library finding, and target creation

# Platform detection. The platform is derived from the *target* (not the host),
# so cross-compiling selects the right archive. It can be overridden with
# -DCEF_PLATFORM=<linux64|linuxarm64|macosx64|macosarm64|windows64|windowsarm64|windows32>.
set(_cef_valid_platforms linux64 linuxarm64 macosx64 macosarm64 windows64 windowsarm64 windows32)

# Normalized target architecture: "arm64", "x86_64" or "x86" (or the raw value if unknown).
function(_cef_detect_target_arch out_var)
    set(_arch "")
    if(APPLE AND CMAKE_OSX_ARCHITECTURES)
        list(GET CMAKE_OSX_ARCHITECTURES 0 _arch)
    elseif(WIN32)
        if(CMAKE_GENERATOR_PLATFORM)
            set(_arch "${CMAKE_GENERATOR_PLATFORM}")
        elseif(CMAKE_CXX_COMPILER_ARCHITECTURE_ID)
            set(_arch "${CMAKE_CXX_COMPILER_ARCHITECTURE_ID}")
        endif()
    endif()
    if(NOT _arch)
        if(CMAKE_SYSTEM_PROCESSOR)
            set(_arch "${CMAKE_SYSTEM_PROCESSOR}")
        else()
            set(_arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")
        endif()
    endif()
    string(TOLOWER "${_arch}" _arch)
    if(_arch MATCHES "^(arm64|aarch64|arm64ec)$")
        set(_arch "arm64")
    elseif(_arch MATCHES "^(x86_64|amd64|x64)$")
        set(_arch "x86_64")
    elseif(_arch MATCHES "^(x86|i[3-6]86|win32)$")
        set(_arch "x86")
    endif()
    set(${out_var} "${_arch}" PARENT_SCOPE)
endfunction()

_cef_detect_target_arch(CEF_TARGET_ARCH)

if(APPLE)
    set(_cef_family "macos")
    set(CEF_LIBRARY_EXTENSION "dylib")
elseif(WIN32)
    set(_cef_family "windows")
    set(CEF_LIBRARY_EXTENSION "dll")
else()
    set(_cef_family "linux")
    set(CEF_LIBRARY_EXTENSION "so")
endif()

if(CEF_PLATFORM)
    # Explicit override (command line, cache or parent project).
    if(NOT CEF_PLATFORM IN_LIST _cef_valid_platforms)
        message(FATAL_ERROR "Unsupported CEF_PLATFORM '${CEF_PLATFORM}'. Valid values: ${_cef_valid_platforms}")
    endif()
    message(STATUS "Using user-specified CEF platform: ${CEF_PLATFORM}")
else()
    if(CEF_TARGET_ARCH STREQUAL "arm64")
        set(CEF_PLATFORM "${_cef_family}arm64")
    elseif(CEF_TARGET_ARCH STREQUAL "x86_64")
        if(_cef_family STREQUAL "macos")
            set(CEF_PLATFORM "macosx64")
        else()
            set(CEF_PLATFORM "${_cef_family}64")
        endif()
    elseif(CEF_TARGET_ARCH STREQUAL "x86" AND _cef_family STREQUAL "windows")
        set(CEF_PLATFORM "windows32")
    else()
        message(FATAL_ERROR "Unsupported ${_cef_family} target architecture '${CEF_TARGET_ARCH}'. Set CEF_PLATFORM explicitly.")
    endif()
    message(STATUS "Detected target ${_cef_family}/${CEF_TARGET_ARCH} - using ${CEF_PLATFORM} CEF binary")
endif()

# The SDK's cef_variables.cmake only recognizes ARM64 through macOS/MSVC-specific
# names, so tell it the architecture unless the user already did.
if(NOT DEFINED PROJECT_ARCH)
    if(CEF_PLATFORM MATCHES "arm64$")
        set(PROJECT_ARCH "arm64")
    elseif(CEF_PLATFORM STREQUAL "windows32")
        set(PROJECT_ARCH "x86")
    else()
        set(PROJECT_ARCH "x86_64")
    endif()
endif()

# Function to verify CEF installation
function(cef_verify_installation)
    # Verify that CEF was successfully downloaded and extracted
    if(NOT EXISTS "${CEF_SOURCE_DIR}/include/cef_version.h")
        message(STATUS "CEF source directory: ${CEF_SOURCE_DIR}")
        file(GLOB CEF_ROOT_FILES "${CEF_SOURCE_DIR}/*")
        message(STATUS "Contents of CEF source directory:")
        foreach(file ${CEF_ROOT_FILES})
            message(STATUS "  ${file}")
        endforeach()
        message(FATAL_ERROR "CEF download failed or CEF headers not found. Please check the CEF version and platform compatibility.")
    endif()
    
    # Reject stale cached distributions or an unrelated local archive before
    # compiling against headers that do not match the package's pinned version.
    file(STRINGS "${CEF_SOURCE_DIR}/include/cef_version.h" _cef_version_line
        REGEX "^#define[ \t]+CEF_VERSION[ \t]+\"")
    if(NOT _cef_version_line MATCHES "\"([^\"]+)\"")
        message(FATAL_ERROR "Could not read CEF_VERSION from the downloaded headers")
    endif()
    if(NOT "${CMAKE_MATCH_1}" STREQUAL "${CEF_VERSION}")
        message(FATAL_ERROR "CEF distribution version mismatch: expected ${CEF_VERSION}, found ${CMAKE_MATCH_1}. Use a matching archive or clear the cached distribution.")
    endif()

    # Debug: Show CEF source directory contents if requested
    if(DEBUG_MODE)
        message(STATUS "CEF source directory: ${CEF_SOURCE_DIR}")
        if(APPLE)
            message(STATUS "Contents of CEF source directory:")
            file(GLOB CEF_ROOT_FILES "${CEF_SOURCE_DIR}/*")
            foreach(file ${CEF_ROOT_FILES})
                message(STATUS "  ${file}")
            endforeach()
            if(EXISTS "${CEF_SOURCE_DIR}/Release")
                message(STATUS "Contents of Release directory:")
                file(GLOB CEF_RELEASE_FILES "${CEF_SOURCE_DIR}/Release/*")
                foreach(file ${CEF_RELEASE_FILES})
                    message(STATUS "  ${file}")
                endforeach()
            endif()
        endif()
    endif()
    
    set(CEF_INCLUDE_DIR "${CEF_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")
endfunction()

# Function to find CEF libraries based on platform
function(cef_find_libraries)
    if(APPLE)
        _cef_find_macos_framework()
    elseif(WIN32)
        _cef_find_windows_libraries()
    else()
        _cef_find_linux_libraries()
    endif()
endfunction()

# Internal function to find macOS framework
function(_cef_find_macos_framework)
    set(CEF_FRAMEWORK_CANDIDATES 
        "${CEF_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
        "${CEF_SOURCE_DIR}/Debug/Chromium Embedded Framework.framework"
        "${CEF_SOURCE_DIR}/Chromium Embedded Framework.framework"
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
        _cef_debug_directory_contents("${CEF_SOURCE_DIR}")
        message(FATAL_ERROR "Could not find Chromium Embedded Framework.framework in any expected location")
    endif()
    
    # Extract the directory for CEF_LIBRARY_DIR
    get_filename_component(CEF_LIBRARY_DIR "${CEF_FRAMEWORK_PATH}" DIRECTORY)
    
    # Set variables in parent scope AND cache them globally
    set(CEF_FRAMEWORK_PATH "${CEF_FRAMEWORK_PATH}" PARENT_SCOPE)
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_FRAMEWORK_PATH "${CEF_FRAMEWORK_PATH}" CACHE STRING "Path to CEF framework" FORCE)
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF library directory" FORCE)
    
    # Set deployment variables for macOS
    set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF binary directory" FORCE)
    set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF resource directory" FORCE)
endfunction()

# Internal function to find Windows libraries
function(_cef_find_windows_libraries)
    set(CEF_LIBRARY_CANDIDATES 
        "${CEF_SOURCE_DIR}/Release"
        "${CEF_SOURCE_DIR}/Debug"
        "${CEF_SOURCE_DIR}"
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
        _cef_debug_directory_contents("${CEF_SOURCE_DIR}")
        message(FATAL_ERROR "Could not find libcef.lib and libcef.dll in any expected location")
    endif()
    
    # Set variables in parent scope AND cache them globally
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_LIB_PATH "${CEF_LIB_PATH}" PARENT_SCOPE)
    set(CEF_DLL_PATH "${CEF_DLL_PATH}" PARENT_SCOPE)
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF library directory" FORCE)
    set(CEF_LIB_PATH "${CEF_LIB_PATH}" CACHE STRING "Path to CEF lib file" FORCE)
    set(CEF_DLL_PATH "${CEF_DLL_PATH}" CACHE STRING "Path to CEF DLL file" FORCE)
    
    # Set deployment variables for Windows
    set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF binary directory" FORCE)
    set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF resource directory" FORCE)
endfunction()

# Internal function to find Linux libraries
function(_cef_find_linux_libraries)
    set(CEF_LIBRARY_DIR "${CEF_SOURCE_DIR}/Release")
    set(CEF_SO_PATH "${CEF_LIBRARY_DIR}/libcef.so")
    if(NOT EXISTS "${CEF_SO_PATH}")
        message(FATAL_ERROR "Could not find libcef.so at ${CEF_SO_PATH}")
    endif()
    
    # Set variables in parent scope AND cache them globally
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_SO_PATH "${CEF_SO_PATH}" PARENT_SCOPE)
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF library directory" FORCE)
    set(CEF_SO_PATH "${CEF_SO_PATH}" CACHE STRING "Path to CEF shared library" FORCE)
    
    # Set deployment variables for Linux
    set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF binary directory" FORCE)
    set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" CACHE STRING "Path to CEF resource directory" FORCE)
endfunction()

# Internal function for debug output
function(_cef_debug_directory_contents source_dir)
    message(STATUS "CEF source directory: ${source_dir}")
    file(GLOB CEF_ROOT_FILES "${source_dir}/*")
    message(STATUS "Contents of CEF source directory:")
    foreach(file ${CEF_ROOT_FILES})
        message(STATUS "  ${file}")
    endforeach()
    
    # Check Release directory specifically
    if(EXISTS "${source_dir}/Release")
        file(GLOB CEF_RELEASE_FILES "${source_dir}/Release/*")
        message(STATUS "Contents of Release directory:")
        foreach(file ${CEF_RELEASE_FILES})
            message(STATUS "  ${file}")
        endforeach()
    endif()
endfunction()

# Function to create the main CEF target
function(cef_create_target)
    # Create the main CEF interface library
    add_library(cef INTERFACE)
    target_compile_features(cef INTERFACE cxx_std_20)
    
    if(APPLE)
        _cef_configure_macos_target()
    elseif(WIN32)
        _cef_configure_windows_target()
    else()
        _cef_configure_linux_target()
    endif()
endfunction()

# Internal function to configure macOS target
function(_cef_configure_macos_target)
    # Link directly to the framework and include headers
    target_link_libraries(cef INTERFACE "${CEF_FRAMEWORK_PATH}")
    target_include_directories(cef INTERFACE 
        $<BUILD_INTERFACE:${CEF_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
    )
    
    # Add required macOS system frameworks
    find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
    find_library(APPKIT_FRAMEWORK AppKit REQUIRED)
    target_link_libraries(cef INTERFACE ${COCOA_FRAMEWORK} ${APPKIT_FRAMEWORK})
endfunction()

# Internal function to configure Windows target
function(_cef_configure_windows_target)
    # Link to the import library
    target_link_libraries(cef INTERFACE "${CEF_LIB_PATH}")
    target_include_directories(cef INTERFACE 
        $<BUILD_INTERFACE:${CEF_SOURCE_DIR}>
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
endfunction()

# Internal function to configure Linux target
function(_cef_configure_linux_target)
    # Link directly to the shared library
    target_link_libraries(cef INTERFACE "${CEF_SO_PATH}")
    target_include_directories(cef INTERFACE 
        $<BUILD_INTERFACE:${CEF_SOURCE_DIR}>
        $<INSTALL_INTERFACE:include>
    )
endfunction()
