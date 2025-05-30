# Chromium Embedded Framework (CEF) Packaging

[![Linux Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml)
[![macOS Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml)
[![Windows Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml)

## Overview

This repository provides a packaging solution for the Chromium Embedded Framework (CEF) on Linux, macOS, and Windows, enabling seamless integration into C++ projects. The packaging is designed for use with [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake), allowing other projects to easily fetch and build CEF as a dependency.

## Usage

### With CPM.cmake (Recommended)
To use this CEF package in your own CMake project, simply add the following line to your `CMakeLists.txt`:

```cmake
CPMAddPackage("gh:ambroise-leclerc/CEF")
```

This will automatically download, configure, and build CEF as part of your project, ensuring all dependencies and minimal tests are handled as defined in this repository.

### Without CPM.cmake
If you do not use CPM.cmake, you may include this repository as a subdirectory or use CMake's FetchContent module:

**Option 1: Add as a subdirectory**
```cmake
git clone https://github.com/ambroise-leclerc/CEF.git
add_subdirectory(CEF)
```

**Option 2: Use FetchContent**
```cmake
include(FetchContent)
FetchContent_Declare(
  cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        main # or a specific release/tag
)
FetchContent_MakeAvailable(cef)
```

## Features
- Provides a reproducible and automated packaging of CEF for Linux, macOS, and Windows
- Integrates with CMake and CPM.cmake for easy consumption
- Includes a minimal sanity test to verify correct integration
- Continuous Integration (CI) with GitHub Actions for reliability across all platforms

## Platform Support

This CEF packaging supports the following platforms:
- **Linux (x64)**: Uses `cef_binary_*_linux64.tar.bz2` distribution
- **macOS (x64)**: Uses `cef_binary_*_macosx64.tar.bz2` distribution
- **Windows (x64)**: Uses `cef_binary_*_windows64.tar.bz2` distribution

### Build Requirements

#### Windows
- Visual Studio 2019 or later (with C++ tools)
- CMake 3.27 or later
- Windows 10 SDK

#### Linux
- GCC or Clang compiler
- CMake 3.27 or later

#### macOS
- Xcode or Command Line Tools
- CMake 3.27 or later

The platform is automatically detected during the CMake configuration phase, and the appropriate CEF binary distribution is downloaded and configured.

**Current CEF Version**: 118.7.1+g99817d2+chromium-118.0.5993.119

This version is chosen for its stability and cross-platform availability. If you need a different CEF version, you can modify the `CEF_VERSION` variable in the main `CMakeLists.txt` file, but ensure that the version you choose has builds available for all platforms you intend to support.

## Prerequisites
- Operating system: Linux, macOS, or Windows (x64)
- C++ compiler:
  - **Linux**: GCC 11 or newer recommended
  - **macOS**: Xcode or Command Line Tools
  - **Windows**: Visual Studio 2019 or later
- [CMake](https://cmake.org/) version 3.27 or later (workflows use 3.27.9)
- Git

## Building and Testing (for maintainers)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ambroise-leclerc/CEF.git
   cd CEF
   ```
2. **Configure the project:**
   ```bash
   cmake -B build -S .
   ```
3. **Build the test target:**
   ```bash
   cmake --build build --config Release --target cef_sanity_test
   ```
4. **Run the CEF sanity test:**
   - **Linux/macOS:**
     ```bash
     ./build/test/cef_sanity_test
     ```
   - **Windows:**
     ```bash
     ./build/test/Release/cef_sanity_test.exe
     ```

## Continuous Integration

The project employs GitHub Actions for CI on Linux, macOS, and Windows. The workflows are defined in `.github/workflows/` with separate files for each platform:
- `linux.yml` - Ubuntu with Unix Makefiles (default)
- `macos.yml` - macOS with Unix Makefiles (default)
- `windows.yml` - Windows with Visual Studio 2022 (MSBuild)

Each workflow is triggered on every push and pull request and performs the following steps:
- Install required dependencies
- Configure the project using CMake
- Build the `cef_sanity_test` target
- Execute the test to ensure correct functionality
- Upload build artifacts

## Development Container

A development container is provided via `.devcontainer/` for a reproducible development environment. It ensures the correct versions of CMake and Ninja are installed, matching the CI configuration.

## Troubleshooting

### CEF Download Issues
If you encounter a 404 error when downloading CEF binaries, it usually means:
1. The specified CEF version doesn't have a build for your platform
2. The CEF version string format has changed

To resolve this:
1. Check the [CEF Builds](https://cef-builds.spotifycdn.com/) page for available versions
2. Update the `CEF_VERSION` in `CMakeLists.txt` to a version that supports your platform
3. Ensure the version string format matches what's available on the CDN

### Platform Detection Issues
The build system automatically detects your platform. If detection fails:
- Ensure you're running on a supported platform (Linux x64, macOS x64, or Windows x64)
- Check the CMake output for platform detection messages

## Licensing

This project is distributed under the terms of the CeCILL License. See `CECILL-LICENSE.txt` for details.

## Acknowledgements

- [Chromium Embedded Framework (CEF)](https://bitbucket.org/chromiumembedded/cef)
- [Kitware CMake](https://cmake.org/)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)

---

For academic or industrial use, please cite the relevant upstream projects and adhere to their respective licences.
