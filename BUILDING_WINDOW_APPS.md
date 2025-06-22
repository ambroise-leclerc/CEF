# How to Build a CEF Window Application

This package now exports both the main `cef` target and the `libcef_dll_wrapper` target needed to build CEF applications like `cef_window_test.cpp`.

## Quick Start

### 1. Basic CMake Setup

```cmake
cmake_minimum_required(VERSION 3.15)
project(my_cef_app LANGUAGES CXX)

# Add the CEF package
CPMAddPackage("gh:ambroise-leclerc/CEF@137.0.17b")

# Create your executable
add_executable(my_cef_app main.cpp)

# Set C++ standard (CEF requires C++17)
set_property(TARGET my_cef_app PROPERTY CXX_STANDARD 17)
set_property(TARGET my_cef_app PROPERTY CXX_STANDARD_REQUIRED ON)

# Link CEF libraries
target_link_libraries(my_cef_app PRIVATE 
    CEF::cef                    # Main CEF interface
    CEF::libcef_dll_wrapper     # CEF C++ wrapper library
    Threads::Threads            # Threading support
)

# Platform-specific configuration
if(WIN32 AND MSVC)
    # Use static runtime to match CEF
    set_property(TARGET my_cef_app PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()
```

### 2. Exported Targets

The package now exports:
- **CEF::cef** - Main CEF interface library
- **CEF::libcef_dll_wrapper** - CEF C++ wrapper library (essential for C++ applications)

### 3. Application Code Structure

Based on `cef_window_test.cpp`, your application should include:

```cpp
#include "include/cef_app.h"
#include "include/cef_browser.h" 
#include "include/cef_client.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/wrapper/cef_helpers.h"

// Platform-specific includes
#if defined(__APPLE__)
    #include "include/wrapper/cef_library_loader.h"
#endif

// Your CEF application class
class MyApp : public CefApp, public CefBrowserProcessHandler {
    // Implementation
};

// Your client handler
class MyClient : public CefClient, public CefDisplayHandler, public CefLifeSpanHandler {
    // Implementation
};

int main(int argc, char* argv[]) {
    // CEF initialization code
}
```

### 4. Platform-Specific Setup

#### Windows
```cmake
if(WIN32)
    # Copy required CEF DLLs
    add_custom_command(TARGET my_cef_app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_SOURCE_DIR}/$<CONFIG>/libcef.dll"
            "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_SOURCE_DIR}/$<CONFIG>/chrome_elf.dll"
            "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/"
        # Add other required DLLs as needed
    )
    
    # Copy CEF resources
    add_custom_command(TARGET my_cef_app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Resources"
            "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/Resources"
    )
endif()
```

#### macOS
```cmake
if(APPLE)
    # Build as app bundle
    set_target_properties(my_cef_app PROPERTIES MACOSX_BUNDLE TRUE)
    
    # Copy CEF framework
    add_custom_command(TARGET my_cef_app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Release/Chromium Embedded Framework.framework"
            "$<TARGET_BUNDLE_CONTENT_DIR:my_cef_app>/Frameworks/Chromium Embedded Framework.framework"
    )
endif()
```

#### Linux
```cmake
if(UNIX AND NOT APPLE)
    # Copy CEF shared library
    add_custom_command(TARGET my_cef_app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CEF_SOURCE_DIR}/Release/libcef.so"
            "${CMAKE_CURRENT_BINARY_DIR}/"
    )
    
    # Copy resources
    add_custom_command(TARGET my_cef_app POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CEF_SOURCE_DIR}/Resources"
            "${CMAKE_CURRENT_BINARY_DIR}/Resources"
    )
endif()
```

## Complete Example

See the working `cef_window_test.cpp` in this repository for a complete, functional example of:
- CEF initialization
- Window creation using CEF Views framework
- Browser lifecycle management
- Platform-specific considerations

## Package Features

✅ **Exports `libcef_dll_wrapper`** - Now available for building CEF applications  
✅ **Cross-platform support** - Windows, macOS, Linux  
✅ **Automatic CEF download** - Handles platform-specific binaries  
✅ **Complete headers** - All CEF headers installed  
✅ **CMake integration** - Easy to use with modern CMake

The package now provides everything needed to build CEF window applications!
