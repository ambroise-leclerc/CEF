cmake_minimum_required(VERSION 3.15)
project(example_cef_app LANGUAGES CXX)

# Example using the CEF package with exported wrapper library
# This demonstrates how to build a CEF window application using the packaged CEF

# Add the CEF package (using the installed package)
find_package(CEF REQUIRED PATHS "F:/CEF/install" NO_DEFAULT_PATH)

# Create your executable
add_executable(example_cef_app 
    example_main.cpp
)

# Set C++ standard (CEF requires C++17)
set_property(TARGET example_cef_app PROPERTY CXX_STANDARD 17)
set_property(TARGET example_cef_app PROPERTY CXX_STANDARD_REQUIRED ON)

# Platform-specific configuration
if(WIN32 AND MSVC)
    # Use static runtime to match CEF
    set_property(TARGET example_cef_app PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Link CEF libraries - both main CEF and wrapper library
target_link_libraries(example_cef_app PRIVATE 
    CEF::cef                    # Main CEF interface
    CEF::libcef_dll_wrapper     # CEF C++ wrapper library (essential for C++ apps)
)

# Find threading library
find_package(Threads REQUIRED)
target_link_libraries(example_cef_app PRIVATE Threads::Threads)

message(STATUS "Example CEF app configured with exported targets:")
if(TARGET CEF::cef)
    message(STATUS "  - CEF::cef target is available")
endif()
if(TARGET CEF::libcef_dll_wrapper)
    message(STATUS "  - CEF::libcef_dll_wrapper target is available")
endif()
