cmake_minimum_required(VERSION 3.24)
project(CEF LANGUAGES C CXX)

# Set CEF version
set(CEF_VERSION "154.0.34+g14c5a08+chromium-154.0.8037.98")

# Include all CMake modules
include(cmake/CEFOptions.cmake)
include(cmake/CEFPlatform.cmake)
include(cmake/CEFDownload.cmake)

# Download and extract CEF
cef_download_and_extract()

# Verify CEF installation
cef_verify_installation()

# Find CEF libraries and setup paths
cef_find_libraries()

# Create the main CEF target
cef_create_target()

# Setup CEF DLL Wrapper
include(cmake/CEFWrapper.cmake)

# Setup testing
include(cmake/CEFTesting.cmake)

# Setup installation
include(cmake/CEFInstall.cmake)

# Setup deployment
include(cmake/CEFDeployment.cmake)

# Set the C++ standard to 20
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Remove -v from CXX flags
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -v")

# CEF options
option(CEF_ENABLE_TESTS "Enable CEF tests" ON)
option(CEF_WRAPPER_BUILD_SKIP "Skip building libcef_dll_wrapper" OFF) # Ensure wrapper is built

# Enable testing by default
option(BUILD_TESTING "Build the testing tree" ON)

set(CMAKE_VERBOSE_MAKEFILE ON)
