#include <iostream>
#include <filesystem>
#include <string>
#include <vector>

int main() {
    std::cout << "CEF Deployment Test" << std::endl;

    // Check the current platform's CEF runtime deployment
    std::filesystem::path exe_dir = std::filesystem::current_path();

    const std::vector<std::string> expected_files = {
#if defined(_WIN32)
        "libcef.dll", "chrome_elf.dll", "d3dcompiler_47.dll",
        "v8_context_snapshot.bin", "vk_swiftshader.dll",
        "vk_swiftshader_icd.json", "vulkan-1.dll",
#elif defined(__APPLE__)
        "../Frameworks/Chromium Embedded Framework.framework/Chromium Embedded Framework",
        "../Frameworks/Chromium Embedded Framework.framework/Resources/icudtl.dat"
#else
        "libcef.so", "chrome-sandbox", "v8_context_snapshot.bin",
        "libvk_swiftshader.so", "libvulkan.so.1", "vk_swiftshader_icd.json",
#endif
#if !defined(__APPLE__)
        "Resources/icudtl.dat", "Resources/resources.pak", "Resources/locales"
#endif
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

    if (static_cast<std::size_t>(found_count) == expected_files.size()) {
        std::cout << "SUCCESS: CEF deployment is working correctly!" << std::endl;
        return 0;
    } else {
        std::cout << "FAILURE: Some CEF files are missing" << std::endl;
        return 1;
    }
}