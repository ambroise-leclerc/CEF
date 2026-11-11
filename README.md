# Chromium Embedded Framework (CEF) Packaging

[![Linux Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml)
[![macOS Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml)
[![Windows Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml)

> :fr: **La version française de ce README se trouve [plus bas](#version-française).**

Embed a Chromium browser in your C++ application with a few lines of CMake.
This repository packages the [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef)
for Linux, macOS and Windows: it downloads the right CEF binaries, builds the
C++ wrapper and copies the runtime next to your executable.

**Current release:** `v156.0.28` · CEF 156.0.28 · Chromium 156.0.8078.88 · C++20 · CMake 3.24+

## Quick start

With [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake):

```cmake
cmake_minimum_required(VERSION 3.24)
project(my_app LANGUAGES CXX)

include(cmake/CPM.cmake)
CPMAddPackage("gh:ambroise-leclerc/CEF#v156.0.28")

add_executable(my_app main.cpp)
cef_configure_app(my_app)   # link CEF, deploy the runtime, set up MSVC
```

That is all: configure and build as usual. The first configure downloads CEF
(a few hundred MB). Pin a release tag for reproducible builds.

FetchContent, `add_subdirectory()`, an installed package and all build options
(minimal download, local archive, platform override, …) are described in
[`docs/CONFIGURATION.md`](docs/CONFIGURATION.md).

## Supported platforms

| Platform | Status |
|---|---|
| Linux x64 | ✅ Built and tested in CI (Ubuntu 22.04) |
| macOS ARM64 | ✅ Built and tested in CI (macos-latest) |
| Windows x64 | ✅ Built and tested in CI (Windows Server 2022) |
| Linux ARM64 | ☑️ Built and tested natively (aarch64), not in CI |
| macOS x64 | ⚠️ Archive available, untested |
| Windows ARM64 | ⚠️ Archive available, untested |
| Windows x86 | ⚠️ Archive available, untested |

The platform is chosen from the **target** architecture, so cross-compiling
works; override it with `-DCEF_PLATFORM=…` if needed. Compiler requirements:
GCC 10+ or a C++20 Clang on Linux, Xcode 16+ on macOS, Visual Studio 2022 on Windows.

## A minimal application

```cpp
#include "include/cef_app.h"
#include "include/wrapper/cef_helpers.h"

int main(int argc, char* argv[]) {
#if defined(__APPLE__)
    CefScopedLibraryLoader loader;          // include/wrapper/cef_library_loader.h
    if (!loader.LoadInMain()) return 1;
#endif
#ifdef _WIN32
    CefMainArgs main_args(GetModuleHandle(nullptr));
#else
    CefMainArgs main_args(argc, argv);
#endif
    CefRefPtr<MyApp> app(new MyApp);

    // CEF relaunches this executable for its renderer, GPU and utility
    // processes: let them exit here instead of running the browser code.
    if (int exit_code = CefExecuteProcess(main_args, app, nullptr); exit_code >= 0)
        return exit_code;

    CefSettings settings;
    CefString(&settings.root_cache_path) = profile_dir_utf8;  // one directory per instance
    if (!CefInitialize(main_args, settings, app, nullptr)) return 1;
    CefRunMessageLoop();
    CefShutdown();
}
```

Two things trip people up:

- **Call `CefExecuteProcess` first.** Otherwise every subprocess runs your `main()` again
  and, on Windows, the GPU process crashes repeatedly.
- **One profile directory per instance** (`root_cache_path`), given as UTF-8:
  use `std::filesystem::path::u8string()`, not `string()`.

Complete examples: [`example/`](example/) and [`test/cef_window_test.cpp`](test/cef_window_test.cpp).

## Run the tests

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build/test -C Release --output-on-failure
```

Three tests: a version/sanity check, a check that the runtime files are present, and a
window test that opens a real CEF window. Without a display on Linux, run
`Xvfb :99 & export DISPLAY=:99` first.

## More documentation

- [Configuration, integration options, deployment, troubleshooting](docs/CONFIGURATION.md)
- [Runtime deployment details](docs/DEPLOYMENT.md)
- [Upgrading from CEF 137 or 154](docs/CEF156_UPGRADE.md): tags `v137.*` and `v154.*` package older CEF versions

## Licensing

Distributed under the CeCILL Free Software License Agreement v2.1; see
[`CECILL-LICENSE.txt`](CECILL-LICENSE.txt). CEF and Chromium keep their own
licences, included in the downloaded distribution.

Thanks to [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef),
[CMake](https://cmake.org/) and [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake).

---

## Version française

Intégrez un navigateur Chromium dans votre application C++ avec quelques lignes
de CMake. Ce dépôt empaquette le [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef)
pour Linux, macOS et Windows : il télécharge les bons binaires CEF, compile le
wrapper C++ et copie le runtime à côté de votre exécutable.

**Version actuelle :** `v156.0.28` · CEF 156.0.28 · Chromium 156.0.8078.88 · C++20 · CMake 3.24+

### Démarrage rapide

Avec [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) :

```cmake
cmake_minimum_required(VERSION 3.24)
project(my_app LANGUAGES CXX)

include(cmake/CPM.cmake)
CPMAddPackage("gh:ambroise-leclerc/CEF#v156.0.28")

add_executable(my_app main.cpp)
cef_configure_app(my_app)   # lie CEF, déploie le runtime, configure MSVC
```

C'est tout : configurez et compilez comme d'habitude. La première configuration
télécharge CEF (quelques centaines de Mo). Fixez un tag de version pour des
compilations reproductibles.

FetchContent, `add_subdirectory()`, le paquet installé et toutes les options
(téléchargement minimal, archive locale, forçage de plateforme…) sont décrits dans
[`docs/CONFIGURATION.md`](docs/CONFIGURATION.md).

### Plateformes supportées

| Plateforme | Statut |
|---|---|
| Linux x64 | ✅ Compilé et testé en CI (Ubuntu 22.04) |
| macOS ARM64 | ✅ Compilé et testé en CI (macos-latest) |
| Windows x64 | ✅ Compilé et testé en CI (Windows Server 2022) |
| Linux ARM64 | ☑️ Compilé et testé nativement (aarch64), hors CI |
| macOS x64 | ⚠️ Archive disponible, non testé |
| Windows ARM64 | ⚠️ Archive disponible, non testé |
| Windows x86 | ⚠️ Archive disponible, non testé |

La plateforme est choisie selon l'architecture **cible** : la compilation croisée
fonctionne ; forcez-la avec `-DCEF_PLATFORM=…` si besoin. Compilateurs requis :
GCC 10+ ou Clang compatible C++20 sous Linux, Xcode 16+ sous macOS, Visual Studio 2022 sous Windows.

### Une application minimale

```cpp
#include "include/cef_app.h"
#include "include/wrapper/cef_helpers.h"

int main(int argc, char* argv[]) {
#if defined(__APPLE__)
    CefScopedLibraryLoader loader;          // include/wrapper/cef_library_loader.h
    if (!loader.LoadInMain()) return 1;
#endif
#ifdef _WIN32
    CefMainArgs main_args(GetModuleHandle(nullptr));
#else
    CefMainArgs main_args(argc, argv);
#endif
    CefRefPtr<MyApp> app(new MyApp);

    // CEF relance cet exécutable pour ses processus de rendu, GPU et
    // utilitaires : ils doivent s'arrêter ici au lieu d'exécuter le navigateur.
    if (int exit_code = CefExecuteProcess(main_args, app, nullptr); exit_code >= 0)
        return exit_code;

    CefSettings settings;
    CefString(&settings.root_cache_path) = profile_dir_utf8;  // un répertoire par instance
    if (!CefInitialize(main_args, settings, app, nullptr)) return 1;
    CefRunMessageLoop();
    CefShutdown();
}
```

Deux pièges classiques :

- **Appelez `CefExecuteProcess` en premier.** Sinon chaque sous-processus réexécute votre
  `main()` et, sous Windows, le processus GPU plante en boucle.
- **Un répertoire de profil par instance** (`root_cache_path`), en UTF-8 :
  utilisez `std::filesystem::path::u8string()`, pas `string()`.

Exemples complets : [`example/`](example/) et [`test/cef_window_test.cpp`](test/cef_window_test.cpp).

### Lancer les tests

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build/test -C Release --output-on-failure
```

Trois tests : un contrôle de version, un contrôle de présence des fichiers runtime, et
un test qui ouvre une vraie fenêtre CEF. Sous Linux sans écran, lancez d'abord
`Xvfb :99 & export DISPLAY=:99`.

### Pour aller plus loin

- [Configuration, options d'intégration, déploiement, dépannage](docs/CONFIGURATION.md)
- [Détails du déploiement du runtime](docs/DEPLOYMENT.md)
- [Migrer depuis CEF 137 ou 154](docs/CEF156_UPGRADE.md) : les tags `v137.*` et `v154.*` empaquettent des versions plus anciennes de CEF

### Licence

Distribué sous la licence de logiciel libre CeCILL v2.1 ; voir
[`CECILL-LICENSE.txt`](CECILL-LICENSE.txt). CEF et Chromium gardent leurs propres
licences, incluses dans la distribution téléchargée.

Merci à [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef),
[CMake](https://cmake.org/) et [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake).
