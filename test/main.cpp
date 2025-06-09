#include <iostream>
#include <string>

// Include necessary CEF headers
#include "include/cef_version.h"

int main() {
    std::cout << "Starting CEF Sanity Test..." << std::endl;
    
    // Get CEF version info using macros from cef_version.h
    std::cout << "CEF Version: " << CEF_VERSION << std::endl;
    std::cout << "CEF Major.Minor.Patch: " << CEF_VERSION_MAJOR << "." << CEF_VERSION_MINOR << "." << CEF_VERSION_PATCH << std::endl;
    std::cout << "Chrome Version: " << CHROME_VERSION_MAJOR << "." << CHROME_VERSION_MINOR << "." << CHROME_VERSION_BUILD << "." << CHROME_VERSION_PATCH << std::endl;
    std::cout << "CEF Commit Hash: " << CEF_COMMIT_HASH << std::endl;
    
    std::cout << "✅ CEF Sanity Test completed successfully!" << std::endl;
    std::cout << "✅ CEF headers are accessible" << std::endl;
    std::cout << "✅ CEF version information retrieved" << std::endl;
    
    return 0;
}
