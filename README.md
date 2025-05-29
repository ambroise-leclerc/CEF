# CEF CMake Package

[![CI](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml)

This project packages the Chromium Embedded Framework (CEF) for use in CMake projects via CPM.cmake or FetchContent.

## Usage

Add this package to your project using CPM:

```cmake
CPMAddPackage("gh:ambroise-leclerc/CEF")
target_link_libraries(your_target PRIVATE cef)
```

This will download the CEF binary distribution for Linux and provide variables:

- `CEF_INCLUDE_DIR`: Path to CEF headers
- `CEF_LIBRARY_DIR`: Path to CEF libraries (Release)

You should use these variables in your target:

```cmake
target_include_directories(your_target PRIVATE ${CEF_INCLUDE_DIR})
target_link_directories(your_target PRIVATE ${CEF_LIBRARY_DIR})
target_link_libraries(your_target PRIVATE cef)
```

## Notes
- Only Linux is supported for now.
- The CEF version and platform are set in `CMakeLists.txt`.
- The SHA256 hash is currently skipped for demonstration. For production, set the correct hash.

## References
- [CEF Downloads](https://cef-builds.spotifycdn.com/index.html)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)
