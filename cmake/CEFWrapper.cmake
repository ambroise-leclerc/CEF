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

  # Add the subdirectory that builds libcef_dll_wrapper.
  # The CMakeLists.txt for libcef_dll_wrapper is in CEF_WRAPPER_SOURCE_DIR.
  # The third argument ensures that targets from the subdirectory are excluded from 'all' by default if desired.
  add_subdirectory(${CEF_WRAPPER_SOURCE_DIR} ${CEF_WRAPPER_BINARY_SUBDIR} ${CEF_WRAPPER_EXCLUDE_FROM_ALL})

  # The target name for the static wrapper library, as defined in its own CMakeLists.txt
  # (typically libcef_dll_wrapper or libcef_dll_wrapper_static).
  set(CEF_WRAPPER_STATIC_LIBRARY_TARGET libcef_dll_wrapper)

  # Get the location of the built static library file to be used for -force_load.
  # This needs to be done after the subdirectory is added and configured.
  # We use a separate variable with CACHE INTERNAL to make it available globally.
  if(TARGET ${CEF_WRAPPER_STATIC_LIBRARY_TARGET})
    # Use generator expression $<TARGET_FILE:...> as recommended for robustness.
    set(ForceLoadWrapperStaticLibFile "$<TARGET_FILE:${CEF_WRAPPER_STATIC_LIBRARY_TARGET}>" CACHE INTERNAL "Path to the libcef_dll_wrapper static library for -force_load (using generator expression)")
    message(STATUS "CEF Wrapper static library location for force_load (deferred via genex): $<TARGET_FILE:${CEF_WRAPPER_STATIC_LIBRARY_TARGET}>")
  else()
    message(WARNING "CEF_WRAPPER_STATIC_LIBRARY_TARGET target '${CEF_WRAPPER_STATIC_LIBRARY_TARGET}' not found when trying to get its location for force_load.")
    set(ForceLoadWrapperStaticLibFile "" CACHE INTERNAL "Path to the libcef_dll_wrapper static library for -force_load") # Set to empty if not found
  endif()

  # Define the main INTERFACE library target for the wrapper.
  # This makes it easy for other targets to link against the wrapper and get its include directories.
  if(NOT TARGET libcef_dll_wrapper)
    add_library(libcef_dll_wrapper INTERFACE)
    target_include_directories(libcef_dll_wrapper INTERFACE
        "${CEF_WRAPPER_SOURCE_DIR}" # For "include/cef_version.h" etc.
        "${CEF_WRAPPER_SOURCE_DIR}/include" # For "cef_app.h" etc.
    )
    # If the static library was built, link the interface target to it.
    if(TARGET ${CEF_WRAPPER_STATIC_LIBRARY_TARGET})
        target_link_libraries(libcef_dll_wrapper INTERFACE ${CEF_WRAPPER_STATIC_LIBRARY_TARGET})
    endif()
    message(STATUS "Defined libcef_dll_wrapper INTERFACE target.")
  endif()

else() # CEF_WRAPPER_BUILD_SKIP is ON
  message(STATUS "CEF DLL wrapper build explicitly skipped via CEF_WRAPPER_BUILD_SKIP=ON")
  # Ensure ForceLoadWrapperStaticLibFile is defined even if skipped
  if(NOT DEFINED ForceLoadWrapperStaticLibFile)
    set(ForceLoadWrapperStaticLibFile "" CACHE INTERNAL "Path to the libcef_dll_wrapper static library for -force_load")
  endif()
  # Ensure libcef_dll_wrapper INTERFACE target exists even if not building, so dependent targets don't fail.
  if(NOT TARGET libcef_dll_wrapper)
    add_library(libcef_dll_wrapper INTERFACE)
    message(STATUS "Defined empty libcef_dll_wrapper INTERFACE target as build is skipped.")
  endif()
endif()
