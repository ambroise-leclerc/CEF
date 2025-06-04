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

install(TARGETS cef EXPORT CEFTargets)
install(DIRECTORY "${cef_binaries_SOURCE_DIR}/include/" 
        DESTINATION include 
        FILES_MATCHING PATTERN "*.h")

install(EXPORT CEFTargets FILE CEFTargets.cmake NAMESPACE CEF:: DESTINATION lib/cmake/CEF)
install(FILES 
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/CEFConfigVersion.cmake" 
    DESTINATION lib/cmake/CEF)
