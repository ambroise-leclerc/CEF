# CEFDeployment.cmake
# Automated CEF runtime deployment for cross-platform applications

# Include CEF macros for file operations (only if CEF is properly configured)
function(_cef_include_macros_if_available)
    if(DEFINED CEF_SOURCE_DIR AND EXISTS "${CEF_SOURCE_DIR}/cmake/cef_macros.cmake")
        include("${CEF_SOURCE_DIR}/cmake/cef_macros.cmake" PARENT_SCOPE)
        set(CEF_MACROS_AVAILABLE TRUE PARENT_SCOPE)
    else()
        set(CEF_MACROS_AVAILABLE FALSE PARENT_SCOPE)
    endif()
endfunction()

# Set platform-specific variables for deployment
function(_cef_set_deployment_variables)
    # Set OS detection variables (compatible with CEF's cef_macros.cmake)
    if(WIN32)
        set(OS_WINDOWS TRUE PARENT_SCOPE)
        set(OS_LINUX FALSE PARENT_SCOPE)
        set(OS_MAC FALSE PARENT_SCOPE)
    elseif(APPLE)
        set(OS_WINDOWS FALSE PARENT_SCOPE)
        set(OS_LINUX FALSE PARENT_SCOPE)
        set(OS_MAC TRUE PARENT_SCOPE)
    else()
        set(OS_WINDOWS FALSE PARENT_SCOPE)
        set(OS_LINUX TRUE PARENT_SCOPE)
        set(OS_MAC FALSE PARENT_SCOPE)
    endif()
    
    # Set CEF binary and resource directories
    if(CEF_LIBRARY_DIR)
        set(CEF_BINARY_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
        set(CEF_RESOURCE_DIR "${CEF_LIBRARY_DIR}" PARENT_SCOPE)
    else()
        message(WARNING "CEF_LIBRARY_DIR not set. CEF deployment may not work correctly.")
    endif()
endfunction()

# Get list of CEF binary files for deployment
function(_cef_get_binary_files output_var)
    _cef_set_deployment_variables()
    
    set(binary_files "")
    
    if(OS_WINDOWS)
        list(APPEND binary_files
            "libcef.dll"
            "chrome_elf.dll"
            "d3dcompiler_47.dll"
            "libEGL.dll"
            "libGLESv2.dll"
            "vk_swiftshader.dll"
            "vulkan-1.dll"
        )
        # Optional files that may not exist in all CEF versions
        set(optional_files
            "dxcompiler.dll"
            "dxil.dll"
        )
        foreach(file ${optional_files})
            if(EXISTS "${CEF_BINARY_DIR}/${file}")
                list(APPEND binary_files "${file}")
            endif()
        endforeach()
        
    elseif(OS_LINUX)
        list(APPEND binary_files
            "libcef.so"
            "chrome-sandbox"
        )
        # Optional files
        if(EXISTS "${CEF_BINARY_DIR}/libminigbm.so")
            list(APPEND binary_files "libminigbm.so")
        endif()
        
    elseif(OS_MAC)
        # macOS uses framework deployment, handled separately
        set(binary_files "")
    endif()
    
    set(${output_var} "${binary_files}" PARENT_SCOPE)
endfunction()

# Get list of CEF resource files for deployment
function(_cef_get_resource_files output_var)
    _cef_set_deployment_variables()
    
    set(resource_files "")
    
    if(OS_WINDOWS OR OS_LINUX)
        list(APPEND resource_files
            "icudtl.dat"
            "chrome_100_percent.pak"
            "chrome_200_percent.pak"
            "resources.pak"
            "v8_context_snapshot.bin"
        )
    endif()
    
    set(${output_var} "${resource_files}" PARENT_SCOPE)
endfunction()

# Main function to deploy CEF runtime files for a target
function(cef_deploy_runtime target_name)
    if(NOT TARGET ${target_name})
        message(FATAL_ERROR "Target '${target_name}' does not exist")
    endif()
    
    _cef_set_deployment_variables()
    _cef_include_macros_if_available()
    
    # Apply CEF target properties
    if(COMMAND SET_EXECUTABLE_TARGET_PROPERTIES)
        SET_EXECUTABLE_TARGET_PROPERTIES(${target_name})
    endif()
    
    # Determine target output directory
    if(COMMAND SET_CEF_TARGET_OUT_DIR)
        SET_CEF_TARGET_OUT_DIR()
    else()
        # Fallback for when CEF macros are not available
        if(CMAKE_GENERATOR MATCHES "Visual Studio" OR CMAKE_GENERATOR MATCHES "Xcode")
            set(CEF_TARGET_OUT_DIR "$<TARGET_FILE_DIR:${target_name}>")
        else()
            set(CEF_TARGET_OUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE}")
        endif()
    endif()
    
    # Platform-specific deployment
    if(OS_LINUX)
        _cef_deploy_linux(${target_name})
    elseif(OS_MAC)
        _cef_deploy_macos(${target_name})
    elseif(OS_WINDOWS)
        _cef_deploy_windows(${target_name})
    endif()
    
    message(STATUS "CEF runtime deployment configured for target: ${target_name}")
endfunction()

# Linux-specific deployment
function(_cef_deploy_linux target_name)
    # Set rpath for library loading
    set_target_properties(${target_name} PROPERTIES 
        INSTALL_RPATH "$ORIGIN"
        BUILD_WITH_INSTALL_RPATH TRUE
        RUNTIME_OUTPUT_DIRECTORY ${CEF_TARGET_OUT_DIR}
    )
    
    # Get file lists
    _cef_get_binary_files(binary_files)
    _cef_get_resource_files(resource_files)
    
    # Deploy binary files
    if(binary_files)
        if(COMMAND COPY_FILES)
            COPY_FILES("${target_name}" "${CEF_BINARY_DIR}" "${CEF_TARGET_OUT_DIR}" FILES ${binary_files})
        else()
            # Fallback: use add_custom_command for each file
            foreach(file ${binary_files})
                if(EXISTS "${CEF_BINARY_DIR}/${file}")
                    add_custom_command(
                        TARGET ${target_name}
                        POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                                "${CEF_BINARY_DIR}/${file}"
                                "${CEF_TARGET_OUT_DIR}/${file}"
                        VERBATIM
                    )
                endif()
            endforeach()
        endif()
    endif()
    
    # Deploy resource files
    if(resource_files)
        if(COMMAND COPY_FILES)
            COPY_FILES("${target_name}" "${CEF_RESOURCE_DIR}" "${CEF_TARGET_OUT_DIR}" FILES ${resource_files})
        else()
            # Fallback: use add_custom_command for each file
            foreach(file ${resource_files})
                if(EXISTS "${CEF_RESOURCE_DIR}/${file}")
                    add_custom_command(
                        TARGET ${target_name}
                        POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                                "${CEF_RESOURCE_DIR}/${file}"
                                "${CEF_TARGET_OUT_DIR}/${file}"
                        VERBATIM
                    )
                endif()
            endforeach()
        endif()
    endif()
    
    # Deploy locales directory
    if(EXISTS "${CEF_RESOURCE_DIR}/locales")
        add_custom_command(
            TARGET ${target_name}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${CEF_RESOURCE_DIR}/locales"
                    "${CEF_TARGET_OUT_DIR}/locales"
            VERBATIM
        )
    endif()
    
    # Deploy Resources directory (if exists)
    if(EXISTS "${CEF_RESOURCE_DIR}/Resources")
        add_custom_command(
            TARGET ${target_name}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${CEF_RESOURCE_DIR}/Resources"
                    "${CEF_TARGET_OUT_DIR}/Resources"
            VERBATIM
        )
    endif()
    
    # Set SUID permissions for chrome-sandbox
    if(COMMAND SET_LINUX_SUID_PERMISSIONS)
        SET_LINUX_SUID_PERMISSIONS("${target_name}" "${CEF_TARGET_OUT_DIR}/chrome-sandbox")
    endif()
endfunction()

# macOS-specific deployment
function(_cef_deploy_macos target_name)
    if(CEF_FRAMEWORK_PATH)
        # Deploy CEF framework
        add_custom_command(
            TARGET ${target_name}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${CEF_FRAMEWORK_PATH}"
                    "$<TARGET_FILE_DIR:${target_name}>/../Frameworks/Chromium Embedded Framework.framework"
            VERBATIM
        )
    else()
        message(WARNING "CEF_FRAMEWORK_PATH not set. macOS framework deployment may not work.")
    endif()
endfunction()

# Windows-specific deployment
function(_cef_deploy_windows target_name)
    # Get file lists
    _cef_get_binary_files(binary_files)
    _cef_get_resource_files(resource_files)
    
    # Deploy binary files
    if(binary_files)
        if(COMMAND COPY_FILES)
            COPY_FILES("${target_name}" "${CEF_BINARY_DIR}" "${CEF_TARGET_OUT_DIR}" FILES ${binary_files})
        else()
            # Fallback: use add_custom_command for each file
            foreach(file ${binary_files})
                if(EXISTS "${CEF_BINARY_DIR}/${file}")
                    add_custom_command(
                        TARGET ${target_name}
                        POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                                "${CEF_BINARY_DIR}/${file}"
                                "${CEF_TARGET_OUT_DIR}/${file}"
                        VERBATIM
                    )
                endif()
            endforeach()
        endif()
    endif()
    
    # Deploy resource files
    if(resource_files)
        if(COMMAND COPY_FILES)
            COPY_FILES("${target_name}" "${CEF_RESOURCE_DIR}" "${CEF_TARGET_OUT_DIR}" FILES ${resource_files})
        else()
            # Fallback: use add_custom_command for each file
            foreach(file ${resource_files})
                if(EXISTS "${CEF_RESOURCE_DIR}/${file}")
                    add_custom_command(
                        TARGET ${target_name}
                        POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                                "${CEF_RESOURCE_DIR}/${file}"
                                "${CEF_TARGET_OUT_DIR}/${file}"
                        VERBATIM
                    )
                endif()
            endforeach()
        endif()
    endif()
    
    # Deploy locales directory
    if(EXISTS "${CEF_RESOURCE_DIR}/locales")
        add_custom_command(
            TARGET ${target_name}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${CEF_RESOURCE_DIR}/locales"
                    "${CEF_TARGET_OUT_DIR}/locales"
            VERBATIM
        )
    endif()
    
    # Deploy Resources directory (if exists)
    if(EXISTS "${CEF_RESOURCE_DIR}/Resources")
        add_custom_command(
            TARGET ${target_name}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                    "${CEF_RESOURCE_DIR}/Resources"
                    "${CEF_TARGET_OUT_DIR}/Resources"
            VERBATIM
        )
    endif()
endfunction()

# Convenience function to configure a CEF application target
function(cef_configure_app target_name)
    # Link CEF libraries
    target_link_libraries(${target_name} PRIVATE cef)
    
    # Link CEF wrapper if available
    if(TARGET libcef_dll_wrapper)
        target_link_libraries(${target_name} PRIVATE libcef_dll_wrapper)
    endif()
    
    # Deploy runtime files
    cef_deploy_runtime(${target_name})
    
    # Set MSVC runtime library to match CEF on Windows
    if(WIN32 AND MSVC)
        set_target_properties(${target_name} PROPERTIES
            MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
        )
    endif()
    
    message(STATUS "CEF application configured: ${target_name}")
endfunction()

# Function to get CEF settings for initialization
function(cef_get_settings_paths output_var)
    _cef_set_deployment_variables()
    
    set(settings_code "")
    
    if(OS_WINDOWS)
        string(APPEND settings_code
            "CefString(&settings.resources_dir_path) = \".\\\\Resources\";\n"
            "CefString(&settings.locales_dir_path) = \".\\\\Resources\\\\locales\";\n"
        )
    else()
        string(APPEND settings_code
            "CefString(&settings.resources_dir_path) = \"./Resources\";\n"
            "CefString(&settings.locales_dir_path) = \"./Resources/locales\";\n"
        )
    endif()
    
    set(${output_var} "${settings_code}" PARENT_SCOPE)
endfunction()