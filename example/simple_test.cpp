#include <iostream>
#include <filesystem>

int main() {
    std::cout << "CEF Deployment Test" << std::endl;

    // Check if CEF DLLs were deployed
    std::filesystem::path exe_dir = std::filesystem::current_path();

    std::vector<std::string> expected_files = {
        "libcef.dll",
        "chrome_elf.dll",
        "d3dcompiler_47.dll",
        "libEGL.dll",
        "libGLESv2.dll",
        "vk_swiftshader.dll",
        "vulkan-1.dll"
    };

    std::cout << "Checking for deployed CEF files in: " << exe_dir << std::endl;

    int found_count = 0;
    for (const auto& file : expected_files) {
        if (std::filesystem::exists(exe_dir / file)) {
            std::cout << "[OK] Found: " << file << std::endl;
            found_count++;
        } else {
            std::cout << "[MISSING] Missing: " << file << std::endl;
        }
    }

    std::cout << "\nDeployment test result: " << found_count << "/" << expected_files.size() << " files found" << std::endl;

    if (found_count == expected_files.size()) {
        std::cout << "SUCCESS: CEF deployment is working correctly!" << std::endl;
        return 0;
    } else {
        std::cout << "FAILURE: Some CEF files are missing" << std::endl;
        return 1;
    }
}