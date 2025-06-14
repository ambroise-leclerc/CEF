cmake_minimum_required(VERSION 3.15)
project(cef_test LANGUAGES CXX)

add_executable(cef_sanity_test cef_sanity_test.cpp)

# Set C++ standard for sanity test
set_property(TARGET cef_sanity_test PROPERTY CXX_STANDARD 17)
set_property(TARGET cef_sanity_test PROPERTY CXX_STANDARD_REQUIRED ON)

# On Windows, ensure we use the same runtime library as CEF (static runtime)
if(WIN32 AND MSVC)
    set_property(TARGET cef_sanity_test PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Add include directories for CEF headers
target_include_directories(cef_sanity_test PRIVATE 
    ${CEF_SOURCE_DIR}/include
    ${CEF_SOURCE_DIR}
)

# Link against the main CEF target which includes all necessary dependencies
target_link_libraries(cef_sanity_test PRIVATE cef)

# Try to link the CEF DLL wrapper if it was built
if(TARGET libcef_dll_wrapper)
    target_link_libraries(cef_sanity_test PRIVATE libcef_dll_wrapper)
endif()

# Platform-specific system libraries
find_package(Threads REQUIRED)
target_link_libraries(cef_sanity_test PRIVATE Threads::Threads)

# On macOS, ensure the CEF framework is available for simple executables
if(APPLE)
    # Copy the CEF framework to the build directory so simple executables can find it
    add_custom_command(TARGET cef_sanity_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/../Frameworks"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
            "${CMAKE_CURRENT_BINARY_DIR}/../Frameworks/Chromium Embedded Framework.framework"
        VERBATIM)
endif()

# Add the CEF resources test (simpler than borderless window test)
add_executable(cef_resources_test cef_resources_test.cpp)

# Set C++ standard
set_property(TARGET cef_resources_test PROPERTY CXX_STANDARD 17)
set_property(TARGET cef_resources_test PROPERTY CXX_STANDARD_REQUIRED ON)

# On Windows, ensure we use the same runtime library as CEF (static runtime)
if(WIN32 AND MSVC)
    set_property(TARGET cef_resources_test PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Add include directories for CEF headers
target_include_directories(cef_resources_test PRIVATE 
    ${CEF_SOURCE_DIR}/include
    ${CEF_SOURCE_DIR}
)

# Link required libraries for filesystem operations and threading
target_link_libraries(cef_resources_test PRIVATE Threads::Threads)

# Handle std::filesystem linking for different platforms
if(UNIX AND NOT APPLE)
    # On Linux with GCC < 9, we need to link stdc++fs
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS "9.0")
        target_link_libraries(cef_resources_test PRIVATE stdc++fs)
    endif()
elseif(WIN32)
    # Windows doesn't need additional filesystem library linking
endif()

# This test only needs CEF headers, not the wrapper library
# No complex linking required - just basic filesystem operations

# On macOS, ensure the CEF framework is available for simple executables
if(APPLE)
    # Use the same framework copy as the sanity test
    add_custom_command(TARGET cef_resources_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/../Frameworks"
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
            "${CMAKE_CURRENT_BINARY_DIR}/../Frameworks/Chromium Embedded Framework.framework"
        VERBATIM)
elseif(WIN32)
    # On Windows, copy CEF binaries and resources for the resources test to the test directory
    add_custom_command(TARGET cef_resources_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_SOURCE_DIR}/Release/libcef.dll"
            "${CMAKE_CURRENT_BINARY_DIR}/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_SOURCE_DIR}/Release/chrome_elf.dll"
            "${CMAKE_CURRENT_BINARY_DIR}/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_SOURCE_DIR}/Release/d3dcompiler_47.dll"
            "${CMAKE_CURRENT_BINARY_DIR}/"
        VERBATIM)
    
    # Copy CEF resources directory for the resources test to the test directory
    add_custom_command(TARGET cef_resources_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Resources"
            "${CMAKE_CURRENT_BINARY_DIR}/Resources"
        VERBATIM)
endif()

# Add the CEF window test (full CEF window functionality)
add_executable(cef_window_test cef_window_test.cpp)

# Set C++ standard for window test
set_property(TARGET cef_window_test PROPERTY CXX_STANDARD 17)
set_property(TARGET cef_window_test PROPERTY CXX_STANDARD_REQUIRED ON)

# On Windows, ensure we use the same runtime library as CEF (static runtime)
if(WIN32 AND MSVC)
    set_property(TARGET cef_window_test PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

if(APPLE)
    # On macOS, build as an app bundle
    set_target_properties(cef_window_test PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/MacOSXBundleInfo.plist.in"
    )
    
    # Find the CEF sandbox library dynamically
    find_library(CEF_SANDBOX_LIBRARY
        NAMES cef_sandbox
        PATHS "${CEF_SOURCE_DIR}/Release" "${CEF_SOURCE_DIR}/Debug"
        NO_DEFAULT_PATH
    )
    
    # On Apple, link cef, libcef_dll_wrapper, and Threads::Threads normally
    target_link_libraries(cef_window_test PRIVATE
        cef                 # Main CEF interface target
        libcef_dll_wrapper  # CEF static wrapper library
        Threads::Threads    # Threading support
    )
    
    # Add the CEF sandbox library if found
    if(CEF_SANDBOX_LIBRARY)
        target_link_libraries(cef_window_test PRIVATE "${CEF_SANDBOX_LIBRARY}")
        message(STATUS "Found CEF sandbox library: ${CEF_SANDBOX_LIBRARY}")
    else()
        message(WARNING "CEF sandbox library not found")
    endif()

    # On macOS, copy the CEF framework to the correct location within the app bundle
    add_custom_command(TARGET cef_window_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
            "$<TARGET_BUNDLE_CONTENT_DIR:cef_window_test>/Frameworks/Chromium Embedded Framework.framework"
        VERBATIM)

    # Add linker flag for Objective-C code, typically required by CEF on macOS.
    target_link_options(cef_window_test PRIVATE "-ObjC")
else()
    # For other platforms, link cef, libcef_dll_wrapper, and Threads directly.
    target_link_libraries(cef_window_test PRIVATE
        cef                 # Main CEF interface target
        libcef_dll_wrapper  # CEF static wrapper library
        Threads::Threads    # Threading support
    )
    
    # On Windows, copy CEF binaries and resources to the test output directory
    if(WIN32)
        # Copy CEF DLLs
        add_custom_command(TARGET cef_window_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/$<CONFIG>/libcef.dll"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/$<CONFIG>/chrome_elf.dll"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/$<CONFIG>/d3dcompiler_47.dll"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/$<CONFIG>/libEGL.dll"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/$<CONFIG>/libGLESv2.dll"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/$<CONFIG>/v8_context_snapshot.bin"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            VERBATIM)
        
        # Copy CEF resources
        add_custom_command(TARGET cef_window_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/Resources/icudtl.dat"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/Resources/chrome_100_percent.pak"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/Resources/chrome_200_percent.pak"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CEF_SOURCE_DIR}/Resources/resources.pak"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
            VERBATIM)
        
        # Copy locales directory
        add_custom_command(TARGET cef_window_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${CEF_SOURCE_DIR}/Resources/locales"
                "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/locales"
            VERBATIM)
    endif()
endif()

# Enable testing with CTest - use the standard BUILD_TESTING option
include(CTest)

# Always add tests when testing is enabled (which is the default)
if(BUILD_TESTING)
    # Add basic sanity test
    add_test(NAME cef_sanity_test 
             COMMAND cef_sanity_test
             WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    
    # Add resources test
    add_test(NAME cef_resources_test 
             COMMAND cef_resources_test
             WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    
    # Add window test with special handling for macOS app bundle
    if(APPLE)
        add_test(NAME cef_window_test 
                 COMMAND ${CMAKE_CURRENT_BINARY_DIR}/cef_window_test.app/Contents/MacOS/cef_window_test
                 WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    else()
        add_test(NAME cef_window_test 
                 COMMAND cef_window_test
                 WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    endif()
    
    # Set test properties for better output and timeout handling
    set_tests_properties(cef_sanity_test PROPERTIES
        TIMEOUT 30
        LABELS "basic;quick"
    )
    
    set_tests_properties(cef_resources_test PROPERTIES
        TIMEOUT 30
        LABELS "basic;filesystem"
    )
    
    set_tests_properties(cef_window_test PROPERTIES
        TIMEOUT 60
        LABELS "gui;integration"
        ENVIRONMENT "DISPLAY=:0"  # For headless environments
    )
    
    message(STATUS "CEF tests have been configured for CTest")
endif()
