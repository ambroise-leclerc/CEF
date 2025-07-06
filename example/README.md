# CEF Simple Example with Automated Deployment

This example demonstrates the new automated deployment functionality of the CEF CPM package.

## What This Example Shows

- **Automated Runtime Deployment**: The `cef_configure_app()` function automatically handles all CEF setup
- **Cross-Platform Compatibility**: Works on Windows, Linux, and macOS
- **Proper Resource Paths**: Uses deployment-compatible paths for CEF initialization
- **Complete CEF Application**: A minimal but functional CEF browser application

## Building the Example

### Prerequisites
- CMake 3.15 or later
- C++ compiler (Visual Studio 2019+ on Windows, GCC/Clang on Linux/macOS)

### Build Steps

1. **Configure the project:**
   ```bash
   cmake -B build -S .
   ```

2. **Build the example:**
   ```bash
   cmake --build build --config Release
   ```

3. **Run the application:**
   - **Windows:** `./build/Release/simple_app.exe`
   - **Linux/macOS:** `./build/simple_app`

## Key Features Demonstrated

### Automated Deployment
The example uses a single function call for complete CEF setup:

```cmake
# This one line handles everything:
cef_configure_app(simple_app)
```

This automatically:
- Links CEF libraries (`cef` + `libcef_dll_wrapper`)
- Deploys all runtime files to the executable directory
- Sets up platform-specific configurations
- Configures MSVC runtime library on Windows

### Runtime File Deployment
After building, you'll find these files automatically copied to your executable directory:

**Windows:**
- `libcef.dll`, `chrome_elf.dll`, and other required DLLs
- `Resources/` directory with PAK files and ICU data
- `locales/` directory with localization files

**Linux:**
- `libcef.so` and other shared libraries
- `Resources/` and `locales/` directories
- Proper RPATH configuration for library loading

**macOS:**
- CEF framework deployed to `Frameworks/` directory
- Proper app bundle structure

### CEF Initialization
The example shows proper CEF initialization with deployment-compatible paths:

```cpp
// Use paths compatible with automated deployment
#ifdef _WIN32
    CefString(&settings.resources_dir_path) = ".\\Resources";
    CefString(&settings.locales_dir_path) = ".\\Resources\\locales";
#else
    CefString(&settings.resources_dir_path) = "./Resources";
    CefString(&settings.locales_dir_path) = "./Resources/locales";
#endif
```

## Manual Deployment Alternative

If you need more control, you can use manual deployment:

```cmake
# Manual approach
target_link_libraries(simple_app PRIVATE cef)
if(TARGET libcef_dll_wrapper)
    target_link_libraries(simple_app PRIVATE libcef_dll_wrapper)
endif()
cef_deploy_runtime(simple_app)
```

## What You'll See

The example creates a simple browser window that loads Google's homepage. This demonstrates:
- CEF initialization with proper resource paths
- Basic browser window creation
- CEF message loop handling
- Proper CEF shutdown

## Troubleshooting

If the application fails to start:
1. Check that all CEF runtime files were deployed correctly
2. Verify that the `Resources/` and `locales/` directories exist
3. On Linux, ensure proper library permissions and RPATH configuration
4. On Windows, verify all required DLLs are present

## Integration with Your Project

To use this deployment system in your own project:

```cmake
# Add CEF to your project
find_package(CEF REQUIRED)

# Create your executable
add_executable(my_app main.cpp)

# Configure with automated deployment
cef_configure_app(my_app)
```

That's it! The deployment system handles all the complexity of CEF runtime file management.