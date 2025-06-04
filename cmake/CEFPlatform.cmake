# CEFPlatform.cmake
# Platform detection, library finding, and target creation

# Detect platform and set CEF_PLATFORM
if(APPLE)
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE MACHINE_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(MACHINE_ARCH STREQUAL "arm64")
        set(CEF_PLATFORM "macosarm64")
        message(STATUS "Detected Apple Silicon Mac - using ARM64 CEF binary (macosarm64)")
    else()
        set(CEF_PLATFORM "macosx64")
        message(STATUS "Detected Intel Mac - using x64 CEF binary")
    endif()
    set(CEF_LIBRARY_EXTENSION "dylib")
elseif(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        execute_process(
            COMMAND uname -m
            OUTPUT_VARIABLE MACHINE_ARCH_WIN
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(MACHINE_ARCH_WIN STREQUAL "aarch64" OR MACHINE_ARCH_WIN STREQUAL "arm64")
            set(CEF_PLATFORM "windowsarm64")
            message(STATUS "Detected Windows ARM64 - using windowsarm64 CEF binary")
        else()
            set(CEF_PLATFORM "windows64")
            message(STATUS "Detected Windows x64 - using windows64 CEF binary")
        endif()
    else()
        set(CEF_PLATFORM "windows32")
    endif()
    set(CEF_LIBRARY_EXTENSION "dll")
else()
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE MACHINE_ARCH_LINUX
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(MACHINE_ARCH_LINUX STREQUAL "aarch64" OR MACHINE_ARCH_LINUX STREQUAL "arm64")
        set(CEF_PLATFORM "linuxarm64")
        message(STATUS "Detected Linux ARM64 - using linuxarm64 CEF binary")
    else()
        set(CEF_PLATFORM "linux64")
        message(STATUS "Detected Linux x64 - using linux64 CEF binary")
    endif()
    set(CEF_LIBRARY_EXTENSION "so")
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
    set(CEF_FRAMEWORK_PATH "${CEF_FRAMEWORK_PATH}" PARENT_SCOPE)
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
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
    
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_LIB_PATH "${CEF_LIB_PATH}" PARENT_SCOPE)
    set(CEF_DLL_PATH "${CEF_DLL_PATH}" PARENT_SCOPE)
endfunction()

# Internal function to find Linux libraries
function(_cef_find_linux_libraries)
    set(CEF_LIBRARY_DIR "${CEF_SOURCE_DIR}/Release")
    set(CEF_SO_PATH "${CEF_LIBRARY_DIR}/libcef.so")
    if(NOT EXISTS "${CEF_SO_PATH}")
        message(FATAL_ERROR "Could not find libcef.so at ${CEF_SO_PATH}")
    endif()
    
    set(CEF_LIBRARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    set(CEF_SO_PATH "${CEF_SO_PATH}" PARENT_SCOPE)
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
