cmake_minimum_required(VERSION 3.15)
project(CEF LANGUAGES CXX)

include(FetchContent)

# Download CEF binary distribution for Linux (example: 137.0.4+g8614a8d+chromium-137.0.7151.6)
set(CEF_VERSION "137.0.4+g8614a8d+chromium-137.0.7151.6")
set(CEF_PLATFORM "linux64")
set(CEF_DIST_NAME "cef_binary_${CEF_VERSION}_${CEF_PLATFORM}")
set(CEF_URL "https://cef-builds.spotifycdn.com/${CEF_DIST_NAME}.tar.bz2")

FetchContent_Declare(
    cef
    URL      ${CEF_URL}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)
FetchContent_MakeAvailable(cef)

# Expose CEF include and lib directories as variables for consumers
set(CEF_INCLUDE_DIR "${cef_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")
set(CEF_LIBRARY_DIR "${cef_SOURCE_DIR}/Release" CACHE STRING "Path to CEF library directory")
add_library(cef INTERFACE)
# Do not set INTERFACE_INCLUDE_DIRECTORIES or INTERFACE_LINK_DIRECTORIES to avoid CMake errors
# Consumers should use CEF_INCLUDE_DIR and CEF_LIBRARY_DIR
target_link_libraries(cef INTERFACE libcef)

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

enable_testing()
add_subdirectory(test)
