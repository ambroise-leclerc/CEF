#include "include/cef_app.h"
#include "include/cef_browser.h"
#include "include/cef_client.h"

#ifdef _WIN32
#include <windows.h>
#endif

// Simple CEF client implementation
class SimpleClient : public CefClient, public CefLifeSpanHandler {
public:
    SimpleClient() {}

    // CefClient methods
    virtual CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override {
        return this;
    }

    // CefLifeSpanHandler methods
    virtual void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
        // Browser created successfully
    }

    virtual bool DoClose(CefRefPtr<CefBrowser> browser) override {
        return false;
    }

    virtual void OnBeforeClose(CefRefPtr<CefBrowser> browser) override {
        // Browser is closing
    }

private:
    IMPLEMENT_REFCOUNTING(SimpleClient);
};

// Simple CEF app implementation
class SimpleApp : public CefApp {
public:
    SimpleApp() {}

private:
    IMPLEMENT_REFCOUNTING(SimpleApp);
};

#ifdef _WIN32
int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow) {
    CefMainArgs main_args(hInstance);
#else
int main(int argc, char* argv[]) {
    CefMainArgs main_args(argc, argv);
#endif

    // Create the application instance
    CefRefPtr<SimpleApp> app(new SimpleApp);

    // Execute the secondary process, if any
    int exit_code = CefExecuteProcess(main_args, app, nullptr);
    if (exit_code >= 0) {
        return exit_code;
    }

    // Initialize CEF settings
    CefSettings settings;
    settings.no_sandbox = true;

    // Use paths compatible with automated deployment
    #ifdef _WIN32
        CefString(&settings.resources_dir_path) = ".\\Resources";
        CefString(&settings.locales_dir_path) = ".\\Resources\\locales";
    #else
        CefString(&settings.resources_dir_path) = "./Resources";
        CefString(&settings.locales_dir_path) = "./Resources/locales";
    #endif

    // Initialize CEF
    if (!CefInitialize(main_args, settings, app, nullptr)) {
        return 1;
    }

    // Create browser window info
    CefWindowInfo window_info;
    CefBrowserSettings browser_settings;

#ifdef _WIN32
    // On Windows, use the default window
    window_info.SetAsPopup(nullptr, "CEF Simple Example");
#else
    // On Linux/Mac, use default settings
    window_info.SetAsChild(0, CefRect(0, 0, 800, 600));
#endif

    // Create the browser
    CefRefPtr<SimpleClient> client(new SimpleClient);
    CefBrowserHost::CreateBrowser(window_info, client, "https://www.google.com", browser_settings, nullptr, nullptr);

    // Run the CEF message loop
    CefRunMessageLoop();

    // Shutdown CEF
    CefShutdown();

    return 0;
}