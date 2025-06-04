# CEFWrapper.cmake
# Handles building the CEF DLL wrapper if it exists (for static linking)

if(EXISTS "${cef_BINARY_DIR}/libcef_dll_wrapper/CMakeLists.txt")
    add_subdirectory(${cef_BINARY_DIR}/libcef_dll_wrapper libcef_dll_wrapper_build EXCLUDE_FROM_ALL)
    if(WIN32)
        set(CEF_DLL_WRAPPER_LIB ${cef_BINARY_DIR}/libcef_dll_wrapper/libcef_dll_wrapper.lib)
    else()
        set(CEF_DLL_WRAPPER_LIB ${cef_BINARY_DIR}/libcef_dll_wrapper/libcef_dll_wrapper.a)
    endif()
else()
    set(CEF_DLL_WRAPPER_LIB "")
endif()
