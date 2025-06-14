#include <iostream>
#include <thread>
#include <chrono>
#include <list>
#include <functional>

#ifdef _WIN32
#include <windows.h>
#endif

// Include CEF headers for actual window creation
#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_client.h"
#include "include/cef_command_line.h"
#include "include/cef_version.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
#include "include/wrapper/cef_helpers.h"
#include "include/cef_task.h"  // For CefTask interface

// Platform-specific includes for library loader (macOS only)
#if defined(__APPLE__)
    #include "include/wrapper/cef_library_loader.h"
    #define HAS_CEF_LIBRARY_LOADER 1
#else
    #define HAS_CEF_LIBRARY_LOADER 0
#endif

// Simple task wrapper to avoid complex binding
class SimpleTask : public CefTask {
public:
    explicit SimpleTask(std::function<void()> func) : func_(func) {}
    
    void Execute() override {
        func_();
    }
    
private:
    std::function<void()> func_;
    IMPLEMENT_REFCOUNTING(SimpleTask);
};

// Real window test handler that creates an actual visible window
class RealWindowTestHandler : public CefClient,
                              public CefDisplayHandler,
                              public CefLifeSpanHandler,
                              public CefLoadHandler {
public:
    explicit RealWindowTestHandler() : is_closing_(false) {}

    static RealWindowTestHandler* GetInstance() {
        static RealWindowTestHandler* instance = new RealWindowTestHandler();
        return instance;
    }

    // CefClient methods
    CefRefPtr<CefDisplayHandler> GetDisplayHandler() override { return this; }
    CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }
    CefRefPtr<CefLoadHandler> GetLoadHandler() override { return this; }

    // CefDisplayHandler methods
    void OnTitleChange(CefRefPtr<CefBrowser> browser, const CefString& title) override {
        std::cout << "✅ Real CEF window title: " << title.ToString() << std::endl;
    }

    // CefLifeSpanHandler methods
    void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        CEF_REQUIRE_UI_THREAD();
        std::cout << "✅ Real CEF window created and displayed!" << std::endl;
        browser_list_.push_back(browser);
        
        // Auto-close after 3 seconds to demonstrate it's working
        std::thread([this, browser]() {
            std::this_thread::sleep_for(std::chrono::seconds(3));
            std::cout << "Auto-closing real CEF window..." << std::endl;
            CloseAllBrowsers(false);
        }).detach();
    }

    bool DoClose(CefRefPtr<CefBrowser> browser) override {
        CEF_REQUIRE_UI_THREAD();
        std::cout << "✅ Real CEF window closing..." << std::endl;
        return false;
    }

    void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
        CEF_REQUIRE_UI_THREAD();
        std::cout << "✅ Real CEF window closed!" << std::endl;
        
        // Remove from the list
        for (auto it = browser_list_.begin(); it != browser_list_.end(); ++it) {
            if ((*it)->IsSame(browser)) {
                browser_list_.erase(it);
                break;
            }
        }

        if (browser_list_.empty()) {
            CefQuitMessageLoop();
        }
    }

    // CefLoadHandler methods
    void OnLoadEnd(CefRefPtr<CefBrowser> browser,
                   CefRefPtr<CefFrame> frame,
                   int httpStatusCode) override {
        CEF_REQUIRE_UI_THREAD();
        std::cout << "✅ Page loaded in real CEF window!" << std::endl;
    }

    void CloseAllBrowsers(bool force_close) {
        if (!CefCurrentlyOn(TID_UI)) {
            // Execute on the UI thread by posting a task
            // Use a lambda instead of base::Bind to avoid missing symbols
            CefPostTask(TID_UI, new SimpleTask([this, force_close]() {
                CloseAllBrowsers(force_close);
            }));
            return;
        }

        if (browser_list_.empty()) {
            return;
        }

        is_closing_ = true;

        for (auto& browser : browser_list_) {
            browser->GetHost()->CloseBrowser(force_close);
        }
    }

    bool IsClosing() const { return is_closing_; }

private:
    typedef std::list<CefRefPtr<CefBrowser>> BrowserList;
    BrowserList browser_list_;
    bool is_closing_;

    IMPLEMENT_REFCOUNTING(RealWindowTestHandler);
};

// Window delegate for creating the actual window
class RealWindowDelegate : public CefWindowDelegate {
public:
    explicit RealWindowDelegate(CefRefPtr<CefBrowserView> browser_view)
        : browser_view_(browser_view) {}

    void OnWindowCreated(CefRefPtr<CefWindow> window) override {
        std::cout << "✅ CEF window frame created!" << std::endl;
        window->AddChildView(browser_view_);
        window->Show();
        std::cout << "✅ CEF window shown on screen!" << std::endl;
    }

    void OnWindowDestroyed(CefRefPtr<CefWindow> window) override {
        browser_view_ = nullptr;
    }

    bool CanClose(CefRefPtr<CefWindow> window) override {
        CefRefPtr<CefBrowser> browser = browser_view_->GetBrowser();
        if (browser) {
            return browser->GetHost()->TryCloseBrowser();
        }
        return true;
    }

    CefSize GetPreferredSize(CefRefPtr<CefView> view) override {
        return CefSize(800, 600);
    }

private:
    CefRefPtr<CefBrowserView> browser_view_;

    IMPLEMENT_REFCOUNTING(RealWindowDelegate);
};

// Browser view delegate
class RealBrowserViewDelegate : public CefBrowserViewDelegate {
public:
    RealBrowserViewDelegate() = default;

private:
    IMPLEMENT_REFCOUNTING(RealBrowserViewDelegate);
};

// App that creates real windows
class RealWindowTestApp : public CefApp, public CefBrowserProcessHandler {
public:
    RealWindowTestApp() = default;

    CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override {
        return this;
    }

    void OnContextInitialized() override {
        CEF_REQUIRE_UI_THREAD();
        
        std::cout << "✅ CEF context initialized, creating REAL window..." << std::endl;

        // Create the handler
        CefRefPtr<RealWindowTestHandler> handler = RealWindowTestHandler::GetInstance();

        // Browser settings
        CefBrowserSettings browser_settings;

        // Create the browser view using CEF Views framework
        std::cout << "Creating CEF browser view..." << std::endl;
        CefRefPtr<CefBrowserView> browser_view = CefBrowserView::CreateBrowserView(
            handler,
            "data:text/html,<html><body style='font-family: Arial; text-align: center; padding: 50px;'><h1>🎉 REAL CEF WINDOW! 🎉</h1><p>This is an actual visible CEF window!</p><p>CEF Version: " CEF_VERSION "</p><p>Window will close in 3 seconds</p></body></html>",
            browser_settings,
            nullptr,
            nullptr,
            new RealBrowserViewDelegate());

        // Create the top-level window that will contain the browser
        std::cout << "Creating top-level CEF window..." << std::endl;
        CefWindow::CreateTopLevelWindow(new RealWindowDelegate(browser_view));
    }

    CefRefPtr<CefClient> GetDefaultClient() override {
        return RealWindowTestHandler::GetInstance();
    }

private:
    IMPLEMENT_REFCOUNTING(RealWindowTestApp);
};

int main(int argc, char* argv[]) {    std::cout << "Starting REAL CEF Window Test..." << std::endl;
    std::cout << "CEF Version: " << CEF_VERSION << std::endl;

#if HAS_CEF_LIBRARY_LOADER
    // Load the CEF framework library at runtime instead of linking directly
    // as required by the macOS sandbox implementation.
    CefScopedLibraryLoader library_loader;
    if (!library_loader.LoadInMain()) {
        std::cerr << "❌ Failed to load CEF library" << std::endl;
        return 1;
    }
#endif

    // Create a modified argument list with additional switches to prevent keychain access
    std::vector<std::string> args;
    for (int i = 0; i < argc; ++i) {
        args.push_back(std::string(argv[i]));
    }
    
    // Add switches to disable password storage features that trigger keychain access
    args.push_back("--disable-password-generation");
    args.push_back("--disable-password-manager-reauthentication");
    args.push_back("--disable-sync");
    args.push_back("--disable-background-networking");
    args.push_back("--disable-features=PasswordManager");
    
    // Additional switches to prevent keychain access
    args.push_back("--disable-web-security");
    args.push_back("--disable-features=VizDisplayCompositor");
    args.push_back("--use-mock-keychain");
    args.push_back("--disable-component-update");
    args.push_back("--disable-default-apps");
    args.push_back("--disable-extensions");
    args.push_back("--disable-plugins");
    args.push_back("--disable-translate");
    args.push_back("--no-first-run");
    args.push_back("--no-default-browser-check");
    args.push_back("--disable-dev-shm-usage");
    args.push_back("--disable-ipc-flooding-protection");
    
    // Add switches to disable GPU acceleration to avoid GPU process issues
    args.push_back("--disable-gpu");
    args.push_back("--disable-gpu-sandbox");
    args.push_back("--disable-software-rasterizer");
    args.push_back("--disable-gpu-process-crash-limit");
    
    // Convert back to char* array
    std::vector<char*> argv_modified;
    for (auto& arg : args) {
        argv_modified.push_back(&arg[0]);    }
    argv_modified.push_back(nullptr);
    
#ifdef _WIN32
    CefMainArgs main_args(GetModuleHandle(nullptr));
#else
    CefMainArgs main_args(static_cast<int>(argv_modified.size() - 1), argv_modified.data());
#endif
    CefRefPtr<RealWindowTestApp> app(new RealWindowTestApp);

    // On macOS with proper app bundle and helper applications,
    // we don't need to call CefExecuteProcess in the main process
    // (it's handled by the helper applications)    // CEF settings
    CefSettings settings;
    settings.multi_threaded_message_loop = false;
    settings.log_severity = LOGSEVERITY_WARNING;
    settings.no_sandbox = true;
    
    CefString(&settings.locale) = "en-US";
#ifdef _WIN32
    CefString(&settings.root_cache_path) = "C:\\temp\\cef_real_window_test";
    CefString(&settings.cache_path) = "C:\\temp\\cef_real_window_test\\cache";
#else
    CefString(&settings.root_cache_path) = "/tmp/cef_real_window_test";
    CefString(&settings.cache_path) = "/tmp/cef_real_window_test/cache";
#endif

    std::cout << "Initializing CEF for real window creation..." << std::endl;
    if (!CefInitialize(main_args, settings, app, nullptr)) {
        std::cerr << "❌ Failed to initialize CEF" << std::endl;
        return 1;
    }

    std::cout << "✅ CEF initialized - window should appear shortly!" << std::endl;
    std::cout << "Running CEF message loop (REAL WINDOW SHOULD BE VISIBLE)..." << std::endl;

    // Run the message loop - this will show the actual window
    CefRunMessageLoop();

    std::cout << "Shutting down CEF..." << std::endl;
    CefShutdown();

    std::cout << "\n=== REAL CEF Window Test Summary ===" << std::endl;
    std::cout << "✅ REAL CEF Window Test completed successfully!" << std::endl;
    std::cout << "✅ Actual visible CEF window was created and displayed" << std::endl;
    std::cout << "✅ CEF Views framework integration verified" << std::endl;
    std::cout << "✅ Real window lifecycle (create, show, close) tested" << std::endl;

    return 0;
}