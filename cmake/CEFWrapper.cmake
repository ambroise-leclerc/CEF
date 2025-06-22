# CEFWrapper.cmake
# Handles building the CEF DLL wrapper if it exists (for static linking)

# Build the libcef_dll_wrapper static library if not explicitly skipped.
if(NOT CEF_WRAPPER_BUILD_SKIP)
  # Determine the source directory for libcef_dll_wrapper.
  set(CEF_WRAPPER_SOURCE_DIR "${CEF_SOURCE_DIR}") # e.g., _deps/cef_binaries-src
  # Determine the binary directory for libcef_dll_wrapper.
  # Use a relative path; it will be created under CMAKE_CURRENT_BINARY_DIR.
  set(CEF_WRAPPER_BINARY_SUBDIR "libcef_dll_wrapper_build")

  message(STATUS "Configuring libcef_dll_wrapper build (Source: ${CEF_WRAPPER_SOURCE_DIR}, Binary SubDir: ${CEF_WRAPPER_BINARY_SUBDIR})")

  # Set up CEF environment variables for building the wrapper
  set(CEF_ROOT "${CEF_WRAPPER_SOURCE_DIR}")
  
  # Use find_package to properly load CEF macros and variables
  list(APPEND CMAKE_MODULE_PATH "${CEF_ROOT}/cmake")
  find_package(CEF REQUIRED)

  # Add the subdirectory that builds libcef_dll_wrapper.
  # The CMakeLists.txt for libcef_dll_wrapper is in CEF_WRAPPER_SOURCE_DIR/libcef_dll.
  add_subdirectory(${CEF_WRAPPER_SOURCE_DIR}/libcef_dll ${CEF_WRAPPER_BINARY_SUBDIR})

  # The target name for the static wrapper library, as defined in its own CMakeLists.txt
  set(CEF_WRAPPER_STATIC_LIBRARY_TARGET libcef_dll_wrapper)

  # Get the location of the built static library file to be used for -force_load.
  # This needs to be done after the subdirectory is added and configured.
  # We use a separate variable with CACHE INTERNAL to make it available globally.
  if(TARGET ${CEF_WRAPPER_STATIC_LIBRARY_TARGET})
    # Use generator expression $<TARGET_FILE:...> as recommended for robustness.
    set(ForceLoadWrapperStaticLibFile "$<TARGET_FILE:${CEF_WRAPPER_STATIC_LIBRARY_TARGET}>" CACHE INTERNAL "Path to the libcef_dll_wrapper static library for -force_load (using generator expression)")
    message(STATUS "CEF Wrapper static library target found: ${CEF_WRAPPER_STATIC_LIBRARY_TARGET}")
    
    # Configure the actual static library target for installation and export
    # Add interface include directories so consumers can use the headers
    target_include_directories(${CEF_WRAPPER_STATIC_LIBRARY_TARGET} INTERFACE
        $<BUILD_INTERFACE:${CEF_WRAPPER_SOURCE_DIR}> # For build-time include directories
        $<BUILD_INTERFACE:${CEF_WRAPPER_SOURCE_DIR}/include> # For "cef_app.h" etc.
        $<INSTALL_INTERFACE:include> # For installed headers
    )
    
    message(STATUS "Configured ${CEF_WRAPPER_STATIC_LIBRARY_TARGET} for installation and export")
  else()
    message(WARNING "CEF_WRAPPER_STATIC_LIBRARY_TARGET target '${CEF_WRAPPER_STATIC_LIBRARY_TARGET}' not found when trying to configure for export.")
    set(ForceLoadWrapperStaticLibFile "" CACHE INTERNAL "Path to the libcef_dll_wrapper static library for -force_load") # Set to empty if not found
  endif()

else() # CEF_WRAPPER_BUILD_SKIP is ON
  message(STATUS "CEF DLL wrapper build explicitly skipped via CEF_WRAPPER_BUILD_SKIP=ON")
  # Ensure ForceLoadWrapperStaticLibFile is defined even if skipped
  if(NOT DEFINED ForceLoadWrapperStaticLibFile)
    set(ForceLoadWrapperStaticLibFile "" CACHE INTERNAL "Path to the libcef_dll_wrapper static library for -force_load")
  endif()
  # Create an empty INTERFACE target so dependent projects don't fail when trying to link
  if(NOT TARGET libcef_dll_wrapper)
    add_library(libcef_dll_wrapper INTERFACE)
    message(STATUS "Defined empty libcef_dll_wrapper INTERFACE target as build is skipped.")
  endif()
endif()
