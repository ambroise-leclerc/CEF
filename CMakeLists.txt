cmake_minimum_required(VERSION 3.15)
project(CEF LANGUAGES CXX)

# Set CEF version
set(CEF_VERSION "137.0.4+g8614a8d+chromium-137.0.7151.6")

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
