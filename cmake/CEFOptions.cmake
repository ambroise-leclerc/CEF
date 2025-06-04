# CEFOptions.cmake
# Defines CMake options for CEF packaging

option(CEF_ROBUST_DOWNLOAD "Enable robust download strategy with no timeouts" ON)
option(CEF_USE_MINIMAL_DIST "Download the _minimal CEF distribution (recommended for most users)" OFF)
set(CEF_LOCAL_ARCHIVE_PATH "" CACHE STRING "Path to a locally provided CEF archive (leave empty to download)")
set(MIN_CEF_ARCHIVE_SIZE 10000000 CACHE STRING "Minimum expected size for CEF archive in bytes")

# For backward compatibility, also check the old variable name
if(CEF_USE_LOCAL_ARCHIVE AND NOT CEF_LOCAL_ARCHIVE_PATH)
    set(CEF_LOCAL_ARCHIVE_PATH "${CEF_USE_LOCAL_ARCHIVE}")
endif()
