# Test script to verify CEF CPM integration works correctly
cmake_minimum_required(VERSION 3.15)
project(TestCEFCPM LANGUAGES CXX)

# Add CPM.cmake
include(FetchContent)
FetchContent_Declare(
  cpm
  GIT_REPOSITORY https://github.com/cpm-cmake/CPM.cmake.git
  GIT_TAG v0.40.2
)
FetchContent_MakeAvailable(cpm)
include(${cpm_SOURCE_DIR}/cmake/CPM.cmake)

# Add CEF package using CPM (using local path for testing)
CPMAddPackage(
  NAME CEF
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
  OPTIONS
    "CEF_ROBUST_DOWNLOAD ON"
    "BUILD_TESTING OFF"  # Disable tests for this integration test
)

# Test that both targets are available
if(TARGET CEF::cef)
    message(STATUS "✅ CEF::cef target is available")
else()
    message(FATAL_ERROR "❌ CEF::cef target is NOT available")
endif()

if(TARGET CEF::libcef_dll_wrapper)
    message(STATUS "✅ CEF::libcef_dll_wrapper target is available")
else()
    message(FATAL_ERROR "❌ CEF::libcef_dll_wrapper target is NOT available")
endif()

# Create a test executable that links to both CEF targets
add_executable(test_cef_integration ${CMAKE_CURRENT_SOURCE_DIR}/example_main.cpp)

# Set C++ standard (CEF requires C++17)
set_property(TARGET test_cef_integration PROPERTY CXX_STANDARD 17)
set_property(TARGET test_cef_integration PROPERTY CXX_STANDARD_REQUIRED ON)

# Link CEF libraries - BOTH targets are required for CEF applications
target_link_libraries(test_cef_integration PRIVATE 
    CEF::cef                    # Main CEF interface
    CEF::libcef_dll_wrapper     # C++ wrapper library (provides CefRefPtr, etc.)
)

# Platform-specific configuration
if(WIN32 AND MSVC)
    # Use static runtime to match CEF
    set_property(TARGET test_cef_integration PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

message(STATUS "✅ CEF CPM integration test configured successfully!")
