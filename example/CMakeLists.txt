cmake_minimum_required(VERSION 3.15)
project(CEFSimpleExample)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add CPM for package management
include(FetchContent)
FetchContent_Declare(
  cpm
  GIT_REPOSITORY https://github.com/cpm-cmake/CPM.cmake
  GIT_TAG v0.40.2
)
FetchContent_MakeAvailable(cpm)
include(${cpm_SOURCE_DIR}/cmake/CPM.cmake)

# Add the parent directory to find CEF
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/..")

# Enable CEF wrapper build
set(CEF_BUILD_WRAPPER ON CACHE BOOL "Build CEF wrapper library")

# Use CPM to get CEF (same as main project)
CPMAddPackage(
  NAME cef
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
)

# Include CEF deployment functions
include(cmake/CEFDeployment)

# Create the simple example executable
add_executable(simple_app simple_app.cpp)

# Create a simple deployment test executable
add_executable(simple_test simple_test.cpp)

# Configure CEF application with automated deployment
# This single function call will:
# - Link CEF libraries (cef + libcef_dll_wrapper)
# - Deploy all runtime files (DLLs, resources, locales)
# - Set proper MSVC runtime library on Windows
# - Configure platform-specific settings
cef_configure_app(simple_app)

# Configure the test executable (just deployment, no CEF linking needed)
cef_deploy_runtime(simple_test)

# Alternative manual approach (commented out):
# target_link_libraries(simple_app PRIVATE cef)
# if(TARGET libcef_dll_wrapper)
#     target_link_libraries(simple_app PRIVATE libcef_dll_wrapper)
# endif()
# cef_deploy_runtime(simple_app)

message(STATUS "CEF Simple Example configured with automated deployment")