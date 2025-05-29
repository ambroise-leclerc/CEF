#include <cef_version.h>
#include <iostream>

int main() {
    std::cout << "CEF Version: " << CEF_VERSION << std::endl;
    // Basic check: print version macro, return 0 if defined
    #ifdef CEF_VERSION
    return 0;
    #else
    return 1;
    #endif
}
