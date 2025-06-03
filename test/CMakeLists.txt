cmake_minimum_required(VERSION 3.15)
project(cef_test LANGUAGES CXX)

add_executable(cef_sanity_test main.cpp)

# Link against the main CEF target which includes all necessary dependencies
target_link_libraries(cef_sanity_test PRIVATE cef)

# Try to link the CEF DLL wrapper if it was built
if(TARGET libcef_dll_wrapper)
    target_link_libraries(cef_sanity_test PRIVATE libcef_dll_wrapper)
endif()

# Platform-specific system libraries
find_package(Threads REQUIRED)
target_link_libraries(cef_sanity_test PRIVATE Threads::Threads)

# Platform-specific runtime setup
if(APPLE)
    # On macOS, copy the CEF framework to the correct location
    # The framework needs to be in Frameworks/ relative to the executable
    add_custom_command(TARGET cef_sanity_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
        $<TARGET_FILE_DIR:cef_sanity_test>/../Frameworks
        COMMENT "Creating Frameworks directory"
    )
    
    add_custom_command(TARGET cef_sanity_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CEF_FRAMEWORK_PATH}"
        "$<TARGET_FILE_DIR:cef_sanity_test>/../Frameworks/Chromium Embedded Framework.framework"
        COMMENT "Copying CEF framework to Frameworks directory"
    )
    
    # Copy CEF resources if they exist
    if(EXISTS "${cef_binaries_SOURCE_DIR}/Resources")
        add_custom_command(TARGET cef_sanity_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${cef_binaries_SOURCE_DIR}/Resources"
            $<TARGET_FILE_DIR:cef_sanity_test>/Resources
            COMMENT "Copying CEF Resources"
        )
    endif()
    
    # Set the correct RPATH so the executable can find the framework
    set_target_properties(cef_sanity_test PROPERTIES
        BUILD_WITH_INSTALL_RPATH TRUE
        INSTALL_RPATH "@executable_path/../Frameworks"
    )
elseif(WIN32)
    # On Windows, copy the CEF DLLs to the output directory for the test to run
    add_custom_command(TARGET cef_sanity_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CEF_LIBRARY_DIR}/libcef.dll"
        $<TARGET_FILE_DIR:cef_sanity_test>
        COMMENT "Copying CEF DLL to output directory"
    )
    
    # Copy other required CEF DLLs if they exist
    set(CEF_DLLS 
        "${CEF_LIBRARY_DIR}/chrome_elf.dll"
        "${CEF_LIBRARY_DIR}/d3dcompiler_47.dll"
        "${CEF_LIBRARY_DIR}/libEGL.dll"
        "${CEF_LIBRARY_DIR}/libGLESv2.dll"
        "${CEF_LIBRARY_DIR}/vk_swiftshader.dll"
        "${CEF_LIBRARY_DIR}/vulkan-1.dll"
    )
    
    foreach(dll ${CEF_DLLS})
        if(EXISTS "${dll}")
            add_custom_command(TARGET cef_sanity_test POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${dll}"
                $<TARGET_FILE_DIR:cef_sanity_test>
                COMMENT "Copying CEF support DLL: ${dll}"
            )
        endif()
    endforeach()
      # Copy CEF resources
    if(EXISTS "${cef_binaries_SOURCE_DIR}/Resources")
        add_custom_command(TARGET cef_sanity_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${cef_binaries_SOURCE_DIR}/Resources"
            $<TARGET_FILE_DIR:cef_sanity_test>/Resources
            COMMENT "Copying CEF Resources"
        )
    endif()
endif()

add_test(NAME cef_sanity_test COMMAND cef_sanity_test)
