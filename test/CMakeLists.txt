cmake_minimum_required(VERSION 3.15)
project(cef_test LANGUAGES CXX)

add_executable(cef_sanity_test main.cpp)
target_include_directories(cef_sanity_test PRIVATE ${CEF_INCLUDE_DIR})
target_link_directories(cef_sanity_test PRIVATE ${CEF_LIBRARY_DIR})
target_link_libraries(cef_sanity_test PRIVATE ${CEF_LIBRARY_DIR}/libcef.so ${CMAKE_BINARY_DIR}/_deps/cef-build/libcef_dll_wrapper/libcef_dll_wrapper.a)

# For CEF, also link to required system libraries
find_package(Threads REQUIRED)
target_link_libraries(cef_sanity_test PRIVATE Threads::Threads dl X11)

add_test(NAME cef_sanity_test COMMAND cef_sanity_test)
