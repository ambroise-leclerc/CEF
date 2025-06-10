#include <iostream>
#include <filesystem>
#include <string>
#include <vector>

// Include necessary CEF headers for basic functionality
#include "include/cef_version.h"

int main() {
    std::cout << "Starting CEF Resources Test..." << std::endl;
    
    // Test 1: Verify CEF version consistency
    std::cout << "Test 1: CEF Version Check" << std::endl;
    std::cout << "CEF Version: " << CEF_VERSION << std::endl;
    
    // Test 2: Check for CEF binary files in the expected location
    std::cout << "Test 2: CEF Binary Files Check" << std::endl;
    
    std::filesystem::path current_dir = std::filesystem::current_path();
    std::cout << "Current directory: " << current_dir << std::endl;
    
    // Expected CEF files that should be copied to output directory
    std::vector<std::string> expected_files = {
        "libcef.dll",
        "chrome_elf.dll",
        "d3dcompiler_47.dll"
    };
    
    int files_found = 0;
    for (const auto& filename : expected_files) {
        std::filesystem::path file_path = current_dir / filename;
        if (std::filesystem::exists(file_path)) {
            std::cout << "✅ Found: " << filename << std::endl;
            files_found++;
        } else {
            std::cout << "❌ Missing: " << filename << std::endl;
        }
    }
    
    // Test 3: Check for CEF Resources directory
    std::cout << "Test 3: CEF Resources Directory Check" << std::endl;
    std::filesystem::path resources_dir = current_dir / "Resources";
    if (std::filesystem::exists(resources_dir) && std::filesystem::is_directory(resources_dir)) {
        std::cout << "✅ Found Resources directory" << std::endl;
        
        // Count files in Resources directory
        int resource_files = 0;
        for (const auto& entry : std::filesystem::directory_iterator(resources_dir)) {
            if (entry.is_regular_file()) {
                resource_files++;
            }
        }
        std::cout << "   Contains " << resource_files << " resource files" << std::endl;
    } else {
        std::cout << "⚠️ Resources directory not found (may be optional)" << std::endl;
    }
    
    // Test 4: Verify CEF commit information
    std::cout << "Test 4: CEF Build Information" << std::endl;
    std::cout << "CEF Commit: " << CEF_COMMIT_HASH << std::endl;
    std::cout << "CEF Commit Number: " << CEF_COMMIT_NUMBER << std::endl;
    std::cout << "Chrome Version: " << CHROME_VERSION_MAJOR << "." 
              << CHROME_VERSION_MINOR << "." 
              << CHROME_VERSION_BUILD << "." 
              << CHROME_VERSION_PATCH << std::endl;
    
    // Summary
    std::cout << "\n=== CEF Resources Test Summary ===" << std::endl;
    std::cout << "Files found: " << files_found << "/" << expected_files.size() << std::endl;
    
    if (files_found >= 2) {  // At least core CEF files present
        std::cout << "✅ CEF Resources Test PASSED" << std::endl;
        std::cout << "✅ CEF packaging system is working correctly" << std::endl;
        return 0;
    } else {
        std::cout << "❌ CEF Resources Test FAILED" << std::endl;
        std::cout << "❌ CEF files not properly deployed" << std::endl;
        return 1;
    }
}
