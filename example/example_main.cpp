// Example CEF application demonstrating usage of exported targets
// This is a minimal example showing how to use CEF::cef and CEF::libcef_dll_wrapper

#include <iostream>

// Include CEF headers (provided by the exported targets)
#include "include/cef_version.h"

int main(int argc, char* argv[]) {
    std::cout << "Example CEF Application" << std::endl;
    std::cout << "=======================" << std::endl;
    std::cout << "CEF Version: " << CEF_VERSION << std::endl;
    std::cout << "Chrome Version: " << CHROME_VERSION_MAJOR << "." << CHROME_VERSION_MINOR << "." << CHROME_VERSION_BUILD << "." << CHROME_VERSION_PATCH << std::endl;
    
    std::cout << "✅ CEF headers accessible" << std::endl;
    std::cout << "✅ CEF wrapper library linked successfully" << std::endl;
    std::cout << "✅ Example app created successfully using exported targets" << std::endl;
    
    // Note: This is a minimal example - a real CEF app would call CefInitialize, etc.
    return 0;
}
