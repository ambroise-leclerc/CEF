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

# Only build the minimal sanity test, do not build CEF sample apps or tests
# Do NOT remove CMakeLists.txt or tests from the CEF source tree, as this breaks the build system

set(CEF_INCLUDE_DIR "${cef_SOURCE_DIR}/include" CACHE STRING "Path to CEF include directory")
set(CEF_LIBRARY_DIR "${cef_SOURCE_DIR}/Release" CACHE STRING "Path to CEF library directory")
add_library(cef INTERFACE)
target_link_libraries(cef INTERFACE libcef)

# Build the CEF dll wrapper if it exists (for static linking)
if(EXISTS "${cef_BINARY_DIR}/libcef_dll_wrapper/CMakeLists.txt")
    add_subdirectory(${cef_BINARY_DIR}/libcef_dll_wrapper libcef_dll_wrapper_build EXCLUDE_FROM_ALL)
    set(CEF_DLL_WRAPPER_LIB ${cef_BINARY_DIR}/libcef_dll_wrapper/libcef_dll_wrapper.a)
else()
    set(CEF_DLL_WRAPPER_LIB "")
endif()

add_executable(cef_sanity_test test/main.cpp)
set_target_properties(cef_sanity_test PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/test")
target_include_directories(cef_sanity_test PRIVATE ${CEF_INCLUDE_DIR})
target_link_libraries(cef_sanity_test PRIVATE ${CEF_LIBRARY_DIR}/libcef.so ${CEF_DLL_WRAPPER_LIB})

enable_testing()
add_test(NAME cef_sanity_test COMMAND cef_sanity_test)

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
