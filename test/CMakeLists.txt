cmake_minimum_required(VERSION 3.15)
project(cef_test LANGUAGES CXX)

add_executable(cef_sanity_test main.cpp)

# Set C++ standard for sanity test
set_property(TARGET cef_sanity_test PROPERTY CXX_STANDARD 17)
set_property(TARGET cef_sanity_test PROPERTY CXX_STANDARD_REQUIRED ON)

# Add include directories for CEF headers
target_include_directories(cef_sanity_test PRIVATE 
    ${CEF_SOURCE_DIR}/include
    ${CEF_SOURCE_DIR}
)

# Link against the main CEF target which includes all necessary dependencies
target_link_libraries(cef_sanity_test PRIVATE cef)

# Try to link the CEF DLL wrapper if it was built
if(TARGET libcef_dll_wrapper)
    target_link_libraries(cef_sanity_test PRIVATE libcef_dll_wrapper)
endif()

# Platform-specific system libraries
find_package(Threads REQUIRED)
target_link_libraries(cef_sanity_test PRIVATE Threads::Threads)

# Add the new borderless window test
add_executable(cef_borderless_window_test cef_borderless_window_test.cpp)

# Set C++ standard
set_property(TARGET cef_borderless_window_test PROPERTY CXX_STANDARD 17)
set_property(TARGET cef_borderless_window_test PROPERTY CXX_STANDARD_REQUIRED ON)

# Add include directories for CEF headers
target_include_directories(cef_borderless_window_test PRIVATE 
    ${CEF_SOURCE_DIR}/include
    ${CEF_SOURCE_DIR}
)

# Link against the main CEF target which includes all necessary dependencies
target_link_libraries(cef_borderless_window_test PRIVATE cef)

# Link the CEF DLL wrapper library directly
set(CEF_WRAPPER_LIB "${CMAKE_BINARY_DIR}/_deps/cef-build/libcef_dll_wrapper/Release/libcef_dll_wrapper.lib")
if(EXISTS "${CEF_WRAPPER_LIB}")
    target_link_libraries(cef_borderless_window_test PRIVATE "${CEF_WRAPPER_LIB}")
    message(STATUS "Linking with CEF wrapper: ${CEF_WRAPPER_LIB}")
else()
    message(STATUS "CEF wrapper not found at: ${CEF_WRAPPER_LIB}")
endif()

# Platform-specific system libraries
target_link_libraries(cef_borderless_window_test PRIVATE Threads::Threads)

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
        "${CEF_FRAMEWORK_PATH}"        "$<TARGET_FILE_DIR:cef_sanity_test>/../Frameworks/Chromium Embedded Framework.framework"
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
    
    # macOS setup for borderless window test
    add_custom_command(TARGET cef_borderless_window_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
        $<TARGET_FILE_DIR:cef_borderless_window_test>/../Frameworks
        COMMENT "Creating Frameworks directory for borderless test"
    )
    
    add_custom_command(TARGET cef_borderless_window_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CEF_FRAMEWORK_PATH}"        "$<TARGET_FILE_DIR:cef_borderless_window_test>/../Frameworks/Chromium Embedded Framework.framework"
        COMMENT "Copying CEF framework to borderless test Frameworks directory"
    )
    
    # Copy CEF resources for borderless test if they exist
    if(EXISTS "${cef_binaries_SOURCE_DIR}/Resources")
        add_custom_command(TARGET cef_borderless_window_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${cef_binaries_SOURCE_DIR}/Resources"
            $<TARGET_FILE_DIR:cef_borderless_window_test>/Resources
            COMMENT "Copying CEF Resources for borderless test"
        )
    endif()
    
    # Set the correct RPATH for borderless test so the executable can find the framework
    set_target_properties(cef_borderless_window_test PROPERTIES
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
    endforeach()    # Copy CEF resources
    if(EXISTS "${cef_binaries_SOURCE_DIR}/Resources")
        add_custom_command(TARGET cef_sanity_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${cef_binaries_SOURCE_DIR}/Resources"
            $<TARGET_FILE_DIR:cef_sanity_test>/Resources
            COMMENT "Copying CEF Resources"
        )
    endif()
    
    # Copy DLLs and resources for the borderless window test
    add_custom_command(TARGET cef_borderless_window_test POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CEF_LIBRARY_DIR}/libcef.dll"
        $<TARGET_FILE_DIR:cef_borderless_window_test>
        COMMENT "Copying CEF DLL to borderless test output directory"
    )
    
    # Copy other required CEF DLLs for borderless test
    foreach(dll ${CEF_DLLS})
        if(EXISTS "${dll}")
            add_custom_command(TARGET cef_borderless_window_test POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${dll}"
                $<TARGET_FILE_DIR:cef_borderless_window_test>
                COMMENT "Copying CEF support DLL to borderless test: ${dll}"
            )
        endif()
    endforeach()
    
    # Copy CEF resources for borderless test
    if(EXISTS "${cef_binaries_SOURCE_DIR}/Resources")
        add_custom_command(TARGET cef_borderless_window_test POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${cef_binaries_SOURCE_DIR}/Resources"
            $<TARGET_FILE_DIR:cef_borderless_window_test>/Resources
            COMMENT "Copying CEF Resources for borderless test"
        )
    endif()
endif()

add_test(NAME cef_sanity_test COMMAND cef_sanity_test)
add_test(NAME cef_borderless_window_test COMMAND cef_borderless_window_test)
