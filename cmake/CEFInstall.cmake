# CEFInstall.cmake
# Handles install and export logic for CEF

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake"
    VERSION ${CEF_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/CEFConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfig.cmake"
    @ONLY
)

# Install the main CEF target
install(TARGETS cef EXPORT CEFTargets)

# Install the CEF wrapper library if it was built
if(TARGET libcef_dll_wrapper AND NOT CEF_WRAPPER_BUILD_SKIP)
    install(TARGETS libcef_dll_wrapper EXPORT CEFTargets)
    message(STATUS "libcef_dll_wrapper will be exported for installation")
endif()

# Install CEF headers
install(DIRECTORY "${CEF_SOURCE_DIR}/include/" 
        DESTINATION include 
        FILES_MATCHING PATTERN "*.h")

# Export all CEF targets (main cef + wrapper if available)
install(EXPORT CEFTargets FILE CEFTargets.cmake NAMESPACE CEF:: DESTINATION lib/cmake/CEF)
install(FILES 
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake" 
    DESTINATION lib/cmake/CEF)
