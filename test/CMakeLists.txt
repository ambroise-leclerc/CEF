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

add_test(NAME cef_sanity_test COMMAND cef_sanity_test)
