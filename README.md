# Chromium Embedded Framework (CEF) Packaging

[![CI Status](https://github.com/<your-org-or-username>/CEF/actions/workflows/linux.yml/badge.svg)](https://github.com/<your-org-or-username>/CEF/actions/workflows/linux.yml)

## Overview

This repository provides a packaging solution for the Chromium Embedded Framework (CEF) on Linux, enabling seamless integration into C++ projects. The packaging is designed for use with [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake), allowing other projects to easily fetch and build CEF as a dependency.

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
- Provides a reproducible and automated packaging of CEF for Linux
- Integrates with CMake and CPM.cmake for easy consumption
- Includes a minimal sanity test to verify correct integration
- Continuous Integration (CI) with GitHub Actions for reliability

## Prerequisites
- Linux-based operating system
- C++ compiler (GCC 11 or newer recommended)
- [CMake](https://cmake.org/) version 3.27.9 or later
- [Ninja](https://ninja-build.org/) build system
- Git

## Building and Testing (for maintainers)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<your-org-or-username>/CEF.git
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
   ```bash
   ./build/test/cef_sanity_test
   ```

## Continuous Integration

The project employs GitHub Actions for CI. The workflow is defined in `.github/workflows/linux.yml` and is triggered on every push and pull request. The CI pipeline performs the following steps:
- Installs required dependencies (`cmake`, `ninja-build`)
- Configures the project using CMake
- Builds the `cef_sanity_test` target
- Executes the test to ensure correct functionality

## Development Container

A development container is provided via `.devcontainer/` for a reproducible development environment. It ensures the correct versions of CMake and Ninja are installed, matching the CI configuration.

## Licensing

This project is distributed under the terms of the CeCILL License. See `CECILL-LICENSE.txt` for details.

## Acknowledgements

- [Chromium Embedded Framework (CEF)](https://bitbucket.org/chromiumembedded/cef)
- [Kitware CMake](https://cmake.org/)
- [Ninja Build](https://ninja-build.org/)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)

---

For academic or industrial use, please cite the relevant upstream projects and adhere to their respective licences.
