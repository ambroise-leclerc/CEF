# CEF Automated Deployment

The CEF CPM package now includes automated runtime deployment functionality that simplifies CEF application development across Windows, Linux, and macOS.

## Quick Start

### Basic Usage

```cmake
# Find and configure CEF
find_package(CEF REQUIRED)

# Create your executable
add_executable(MyApp main.cpp)

# Configure CEF application (links libraries + deploys runtime)
cef_configure_app(MyApp)
```

### Manual Deployment

If you need more control, you can deploy runtime files manually:

```cmake
# Link CEF libraries manually
target_link_libraries(MyApp PRIVATE cef libcef_dll_wrapper)

# Deploy only runtime files
cef_deploy_runtime(MyApp)
```

## Functions

### `cef_configure_app(target_name)`
- Links CEF libraries (cef + libcef_dll_wrapper)
- Deploys all runtime files
- Sets MSVC runtime library on Windows
- One-stop solution for CEF applications

### `cef_deploy_runtime(target_name)`
- Deploys CEF runtime files to executable directory
- Handles platform-specific requirements
- Sets up proper library paths and permissions

### `cef_get_settings_paths(output_var)`
- Returns C++ code for CEF settings initialization
- Provides correct relative paths for resources
- Use in your CEF initialization code

## Platform-Specific Behavior

### Windows
- Deploys DLLs and `v8_context_snapshot.bin` from the distribution's `Release/` directory
- Deploys `icudtl.dat`, `*.pak` and `locales/` from the distribution's `Resources/` directory
- Resources are placed both next to the executable (CEF's default lookup) and in `Resources/` (paths returned by `cef_get_settings_paths()`)

### Linux
- Sets $ORIGIN rpath for library loading
- Deploys `libcef.so`, `chrome-sandbox`, `v8_context_snapshot.bin` and, when present, the ANGLE/SwiftShader libraries from `Release/`
- Deploys resources from `Resources/` with the same layout as on Windows
- Prints the `sudo` command that gives `chrome-sandbox` its SUID bit; nothing is run with elevated privileges at build time. Run it yourself, or set `settings.no_sandbox = true`

### macOS
- Deploys CEF framework to Frameworks/ directory
- Maintains proper app bundle structure

## Example CEF Initialization

```cpp
#include "include/cef_app.h"

bool InitializeCEF() {
    CefSettings settings;
    settings.no_sandbox = true;

    // Use paths compatible with automated deployment
    #ifdef _WIN32
        CefString(&settings.resources_dir_path) = ".\\Resources";
        CefString(&settings.locales_dir_path) = ".\\Resources\\locales";
    #else
        CefString(&settings.resources_dir_path) = "./Resources";
        CefString(&settings.locales_dir_path) = "./Resources/locales";
    #endif

    return CefInitialize(main_args, settings, app, nullptr);
}