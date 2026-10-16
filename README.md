# Chromium Embedded Framework (CEF) Packaging

[![Linux Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml)
[![macOS Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml)
[![Windows Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml)

> :fr: **La version française de ce README se trouve [plus bas](#version-française).**

## Overview

This repository packages the [Chromium Embedded Framework (CEF)](https://bitbucket.org/chromiumembedded/cef)
for CMake projects on Linux, macOS and Windows. At configure time it downloads the
CEF binary distribution for the host platform, builds `libcef_dll_wrapper`, and
exposes CMake targets plus helper functions that copy the CEF runtime next to your
executable. It is designed for [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)
but also works with FetchContent, `add_subdirectory()` or an installed package.

## Current release

| | |
|---|---|
| Package tag | **`v154.0.34`** |
| CEF | `154.0.34+g14c5a08+chromium-154.0.8037.98` |
| Chromium | `154.0.8037.98` |
| C++ standard | **C++20** (propagated to consumers by both targets) |
| CMake | **3.24+** (CI uses 3.27.9) |

Pin a release tag for reproducible builds. Tags `v137.*` package CEF 137 (C++17).
Coming from CEF 137? Read the [CEF 154 upgrade notes](docs/CEF154_UPGRADE.md) and
reconfigure in a fresh build directory.

## Quick start

```cmake
cmake_minimum_required(VERSION 3.24)
project(my_app LANGUAGES CXX)

include(cmake/CPM.cmake)  # https://github.com/cpm-cmake/CPM.cmake
CPMAddPackage("gh:ambroise-leclerc/CEF#v154.0.34")

add_executable(my_app main.cpp)

# Links cef + libcef_dll_wrapper, deploys the CEF runtime next to my_app
# and sets the MSVC runtime library expected by CEF.
cef_configure_app(my_app)
```

For a complete application see [`example/`](example/) (`simple_app.cpp`,
`example_main.cpp`) and the window test [`test/cef_window_test.cpp`](test/cef_window_test.cpp).

## Integration options

### CPM.cmake with options

```cmake
CPMAddPackage(
  NAME cef
  GITHUB_REPOSITORY ambroise-leclerc/CEF
  GIT_TAG v154.0.34
  OPTIONS
    "CEF_USE_MINIMAL_DIST ON"     # smaller _minimal distribution (default OFF)
    "CEF_ROBUST_DOWNLOAD ON"      # download with curl/wget fallbacks (default ON)
)
```

| Option | Default | Effect |
|---|---|---|
| `CEF_USE_MINIMAL_DIST` | `OFF` | Download the `_minimal` distribution: Release binaries only, without debug builds or sample applications. |
| `CEF_ROBUST_DOWNLOAD` | `ON` | Retry the download with CMake, then curl, then wget. |
| `CEF_LOCAL_ARCHIVE_PATH` | empty | Use a CEF archive already on disk instead of downloading it. |
| `FETCHCONTENT_SOURCE_DIR_CEF_BINARIES` | empty | Reuse an already extracted CEF distribution (no download at all). |
| `CEF_WRAPPER_BUILD_SKIP` | `OFF` | Do not build `libcef_dll_wrapper`. |
| `api_version` | upstream default | CEF API version, e.g. `-Dapi_version=15400`. The wrapper's choice is propagated to consumers. |

The configured CEF version is checked against the distribution's headers: a
stale cached distribution or an archive of another version stops the configure
step with an explicit error.

### Manual linking

```cmake
add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
cef_deploy_runtime(my_app)  # optional: copy the runtime files only
```

### FetchContent or add_subdirectory

```cmake
include(FetchContent)
FetchContent_Declare(cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        v154.0.34)
FetchContent_MakeAvailable(cef)

target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
```

`add_subdirectory(path/to/CEF)` on a checkout of the tag works the same way.

### Installed package

`cmake --install` exports namespaced targets and the CEF headers:

```cmake
find_package(CEF REQUIRED)
target_link_libraries(my_app PRIVATE CEF::cef CEF::libcef_dll_wrapper)
```

The installed package does not ship the runtime files nor the deployment
functions below: deploy `libcef`, its resources and locales yourself.

## Targets

| CPM / FetchContent / subdirectory | Installed package | Content |
|---|---|---|
| `cef` | `CEF::cef` | CEF headers and the `libcef` library or macOS framework. |
| `libcef_dll_wrapper` | `CEF::libcef_dll_wrapper` | C++ wrapper (`CefRefPtr`, `IMPLEMENT_REFCOUNTING`, `CefPostTask`, …). Required by C++ applications. |

Both targets require C++20 and propagate the selected `CEF_API_VERSION`.

## Runtime deployment

| Function | Purpose |
|---|---|
| `cef_configure_app(target)` | Link both targets, deploy the runtime, set the static MSVC runtime on Windows. |
| `cef_deploy_runtime(target)` | Deploy the runtime only. |
| `cef_get_settings_paths(var)` | Return C++ lines setting `resources_dir_path` / `locales_dir_path` for the deployed layout. |

After the build, the executable directory contains:

- **Windows / Linux**: the binaries from the distribution's `Release/` directory
  (`libcef.dll` or `libcef.so`, `chrome_elf.dll`, `chrome-sandbox`,
  `v8_context_snapshot.bin`, ANGLE and SwiftShader/Vulkan files when present),
  the resources from `Resources/` (`icudtl.dat`, `*.pak`, `locales/`), and a copy
  of them in `Resources/`. CEF finds them with no path set; `cef_get_settings_paths()`
  points to the `Resources/` copy.
- **macOS**: `Chromium Embedded Framework.framework` in the bundle's `Frameworks/`.
  Load it at runtime with `CefScopedLibraryLoader`.
- **Linux sandbox**: the build prints the `sudo chown root:root` / `chmod 4755`
  command for `chrome-sandbox` but never runs it. Run it yourself or set
  `settings.no_sandbox = true`.

Details: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Writing a CEF application

```cpp
#include "include/cef_app.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
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

Two points that matter in practice:

- **Subprocesses**: without the `CefExecuteProcess` early return, each subprocess
  runs your `main()` and calls `CefInitialize` again. On Windows with CEF 154 this
  crashes the GPU process repeatedly until CEF aborts.
- **Profile directory**: two instances sharing one `root_cache_path` conflict.
  `CefString(std::string)` expects UTF-8: convert `std::filesystem::path` with
  `u8string()`, not `string()` (MSVC uses the local code page).

`test/cef_window_test.cpp` applies both: a unique profile per run under
`std::filesystem::temp_directory_path()`, removed after `CefShutdown()`.

## Supported platforms

| Platform | Distribution | CI |
|---|---|---|
| Linux x64 | `linux64` | ✅ Ubuntu 22.04 |
| Linux ARM64 | `linuxarm64` | — |
| macOS x64 | `macosx64` | — |
| macOS ARM64 | `macosarm64` | ✅ macos-latest |
| Windows x64 | `windows64` | ✅ Windows Server 2022 |
| Windows x86 | `windows32` | — |
| Windows ARM64 | `windowsarm64` | — |

The distribution is chosen from the host OS and architecture at configure time.
Archives for all seven variants were checked for this release; only the variants
marked ✅ are built and tested in CI.

Build requirements:

- **Linux**: GCC 10+ or a C++20 Clang; X11 development packages to run the window test.
- **macOS**: Xcode 16+ (macOS 14.5+ recommended as build host). The ARM64
  framework requires macOS 13.0+ at runtime.
- **Windows**: Visual Studio 2022 with the C++ workload and a Windows 10/11 SDK.

## Tests

| Test | Checks |
|---|---|
| `cef_sanity_test` | Loads the CEF library, checks that the runtime's version components match the headers, fills `CefMainArgs`/`CefSettings`. |
| `cef_resources_test` | Presence of the platform binaries (`libcef.*` or the framework) and of the resources. |
| `cef_window_test` | Opens a real CEF Views window, renders HTML and closes it after 3 s. Uses an isolated profile per run and dispatches subprocesses through `CefExecuteProcess`. |

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build/test -C Release --output-on-failure
```

On Linux without a display, start a virtual one first
(`Xvfb :99 & export DISPLAY=:99`); CTest sets `DISPLAY=:99` for the window test.

## Continuous integration

`.github/workflows/{linux,macos,windows}.yml` run on every push and pull request,
for both the full and the minimal distribution:

1. configure and build the package and its three tests;
2. run them with CTest;
3. build the [`example/`](example/) applications against the downloaded
   distribution and run their deployment test (`cef_example_deployment`);
4. upload the build artifacts.

## Maintainers

- **Changing the CEF version**: update `CEF_VERSION` in `CMakeLists.txt`, check that
  the [CEF build index](https://cef-builds.spotifycdn.com/index.json) lists standard
  and minimal archives for every platform, then reconfigure from a clean build directory.
- **Releasing**: once CI passes on `main`, tag `v<CEF major>.<minor>.<patch>` and
  publish a GitHub release; update the tag in this README.
- **Dev container**: `.devcontainer/` provides a Linux environment matching CI.

## Troubleshooting

- **Download fails or stalls**: keep `CEF_ROBUST_DOWNLOAD=ON`, try
  `CEF_USE_MINIMAL_DIST=ON`, or download the archive manually and pass
  `-DCEF_LOCAL_ARCHIVE_PATH=/path/to/cef_binary_….tar.bz2`.
- **`CEF distribution version mismatch`**: the build directory or archive holds
  another CEF version. Delete the build directory or provide the matching archive.
- **HTTP 404 on download**: the configured version has no build for this platform;
  check the [CEF builds](https://cef-builds.spotifycdn.com/index.html) page.
- **`GPU process isn't usable` / repeated subprocess crashes**: subprocesses are
  not dispatched; see [Writing a CEF application](#writing-a-cef-application).
- **Linux: `chrome-sandbox` error at startup**: apply the SUID command printed by
  the build or disable the sandbox.

## Licensing

This project is distributed under the CeCILL Free Software License Agreement v2.1;
see [`CECILL-LICENSE.txt`](CECILL-LICENSE.txt). CEF and Chromium are distributed
under their own licences, included in the downloaded distribution.

## Acknowledgements

- [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef)
- [CMake](https://cmake.org/)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)

---

## Version française

### Présentation

Ce dépôt empaquette le [Chromium Embedded Framework (CEF)](https://bitbucket.org/chromiumembedded/cef)
pour les projets CMake sous Linux, macOS et Windows. À la configuration, il
télécharge la distribution binaire CEF de la plateforme, compile
`libcef_dll_wrapper` et fournit des cibles CMake ainsi que des fonctions qui
copient le runtime CEF à côté de votre exécutable. Il est conçu pour
[CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) mais fonctionne aussi avec
FetchContent, `add_subdirectory()` ou un paquet installé.

### Version actuelle

| | |
|---|---|
| Tag du paquet | **`v154.0.34`** |
| CEF | `154.0.34+g14c5a08+chromium-154.0.8037.98` |
| Chromium | `154.0.8037.98` |
| Standard C++ | **C++20** (propagé aux consommateurs par les deux cibles) |
| CMake | **3.24+** (la CI utilise 3.27.9) |

Fixez un tag de version pour des compilations reproductibles. Les tags `v137.*`
empaquettent CEF 137 (C++17). Si vous venez de CEF 137, lisez les
[notes de migration vers CEF 154](docs/CEF154_UPGRADE.md) et reconfigurez dans un
répertoire de compilation vierge.

### Démarrage rapide

```cmake
cmake_minimum_required(VERSION 3.24)
project(my_app LANGUAGES CXX)

include(cmake/CPM.cmake)  # https://github.com/cpm-cmake/CPM.cmake
CPMAddPackage("gh:ambroise-leclerc/CEF#v154.0.34")

add_executable(my_app main.cpp)

# Lie cef + libcef_dll_wrapper, déploie le runtime CEF à côté de my_app
# et choisit le runtime MSVC attendu par CEF.
cef_configure_app(my_app)
```

Pour une application complète, voir [`example/`](example/) (`simple_app.cpp`,
`example_main.cpp`) et le test de fenêtre [`test/cef_window_test.cpp`](test/cef_window_test.cpp).

### Options d'intégration

#### CPM.cmake avec options

```cmake
CPMAddPackage(
  NAME cef
  GITHUB_REPOSITORY ambroise-leclerc/CEF
  GIT_TAG v154.0.34
  OPTIONS
    "CEF_USE_MINIMAL_DIST ON"     # distribution _minimal, plus légère (OFF par défaut)
    "CEF_ROBUST_DOWNLOAD ON"      # téléchargement avec repli curl/wget (ON par défaut)
)
```

| Option | Défaut | Effet |
|---|---|---|
| `CEF_USE_MINIMAL_DIST` | `OFF` | Télécharge la distribution `_minimal` : binaires Release uniquement, sans builds de débogage ni applications d'exemple. |
| `CEF_ROBUST_DOWNLOAD` | `ON` | Réessaie le téléchargement avec CMake, puis curl, puis wget. |
| `CEF_LOCAL_ARCHIVE_PATH` | vide | Utilise une archive CEF déjà présente au lieu de la télécharger. |
| `FETCHCONTENT_SOURCE_DIR_CEF_BINARIES` | vide | Réutilise une distribution CEF déjà extraite (aucun téléchargement). |
| `CEF_WRAPPER_BUILD_SKIP` | `OFF` | Ne compile pas `libcef_dll_wrapper`. |
| `api_version` | défaut amont | Version de l'API CEF, par ex. `-Dapi_version=15400`. Le choix du wrapper est propagé aux consommateurs. |

La version CEF configurée est comparée aux en-têtes de la distribution : une
distribution en cache périmée ou une archive d'une autre version arrête la
configuration avec une erreur explicite.

#### Liaison manuelle

```cmake
add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
cef_deploy_runtime(my_app)  # optionnel : copie seulement les fichiers runtime
```

#### FetchContent ou add_subdirectory

```cmake
include(FetchContent)
FetchContent_Declare(cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        v154.0.34)
FetchContent_MakeAvailable(cef)

target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
```

`add_subdirectory(chemin/vers/CEF)` sur une copie du tag fonctionne de la même façon.

#### Paquet installé

`cmake --install` exporte des cibles préfixées et les en-têtes CEF :

```cmake
find_package(CEF REQUIRED)
target_link_libraries(my_app PRIVATE CEF::cef CEF::libcef_dll_wrapper)
```

Le paquet installé ne contient ni les fichiers runtime ni les fonctions de
déploiement ci-dessous : déployez vous-même `libcef`, ses ressources et ses locales.

### Cibles

| CPM / FetchContent / sous-répertoire | Paquet installé | Contenu |
|---|---|---|
| `cef` | `CEF::cef` | En-têtes CEF et bibliothèque `libcef` ou framework macOS. |
| `libcef_dll_wrapper` | `CEF::libcef_dll_wrapper` | Wrapper C++ (`CefRefPtr`, `IMPLEMENT_REFCOUNTING`, `CefPostTask`…). Indispensable aux applications C++. |

Les deux cibles exigent C++20 et propagent la valeur de `CEF_API_VERSION` retenue.

### Déploiement du runtime

| Fonction | Rôle |
|---|---|
| `cef_configure_app(cible)` | Lie les deux cibles, déploie le runtime, choisit le runtime MSVC statique sous Windows. |
| `cef_deploy_runtime(cible)` | Déploie seulement le runtime. |
| `cef_get_settings_paths(var)` | Renvoie les lignes C++ qui fixent `resources_dir_path` / `locales_dir_path` pour la disposition déployée. |

Après la compilation, le répertoire de l'exécutable contient :

- **Windows / Linux** : les binaires du répertoire `Release/` de la distribution
  (`libcef.dll` ou `libcef.so`, `chrome_elf.dll`, `chrome-sandbox`,
  `v8_context_snapshot.bin`, fichiers ANGLE et SwiftShader/Vulkan s'ils existent),
  les ressources de `Resources/` (`icudtl.dat`, `*.pak`, `locales/`), et une copie
  de celles-ci dans `Resources/`. CEF les trouve sans chemin configuré ;
  `cef_get_settings_paths()` pointe vers la copie dans `Resources/`.
- **macOS** : `Chromium Embedded Framework.framework` dans le dossier `Frameworks/`
  du bundle. Chargez-le à l'exécution avec `CefScopedLibraryLoader`.
- **Sandbox Linux** : la compilation affiche la commande `sudo chown root:root` /
  `chmod 4755` pour `chrome-sandbox` mais ne l'exécute jamais. Lancez-la
  vous-même ou utilisez `settings.no_sandbox = true`.

Détails : [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

### Écrire une application CEF

```cpp
#include "include/cef_app.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_window.h"
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

Deux points importants en pratique :

- **Sous-processus** : sans le retour anticipé via `CefExecuteProcess`, chaque
  sous-processus exécute votre `main()` et rappelle `CefInitialize`. Sous Windows
  avec CEF 154, le processus GPU plante alors en boucle jusqu'à l'arrêt de CEF.
- **Répertoire de profil** : deux instances qui partagent le même `root_cache_path`
  entrent en conflit. `CefString(std::string)` attend de l'UTF-8 : convertissez un
  `std::filesystem::path` avec `u8string()`, pas `string()` (MSVC utilise la page
  de code locale).

`test/cef_window_test.cpp` applique les deux : un profil unique par exécution
sous `std::filesystem::temp_directory_path()`, supprimé après `CefShutdown()`.

### Plateformes supportées

| Plateforme | Distribution | CI |
|---|---|---|
| Linux x64 | `linux64` | ✅ Ubuntu 22.04 |
| Linux ARM64 | `linuxarm64` | — |
| macOS x64 | `macosx64` | — |
| macOS ARM64 | `macosarm64` | ✅ macos-latest |
| Windows x64 | `windows64` | ✅ Windows Server 2022 |
| Windows x86 | `windows32` | — |
| Windows ARM64 | `windowsarm64` | — |

La distribution est choisie selon le système et l'architecture de la machine au
moment de la configuration. Les archives des sept variantes ont été vérifiées pour
cette version ; seules les variantes marquées ✅ sont compilées et testées en CI.

Prérequis de compilation :

- **Linux** : GCC 10+ ou Clang compatible C++20 ; paquets de développement X11
  pour exécuter le test de fenêtre.
- **macOS** : Xcode 16+ (macOS 14.5+ recommandé pour compiler). Le framework
  ARM64 exige macOS 13.0+ à l'exécution.
- **Windows** : Visual Studio 2022 avec la charge de travail C++ et un SDK Windows 10/11.

### Tests

| Test | Vérifie |
|---|---|
| `cef_sanity_test` | Charge la bibliothèque CEF, vérifie que les composantes de version du runtime correspondent aux en-têtes, remplit `CefMainArgs`/`CefSettings`. |
| `cef_resources_test` | Présence des binaires de la plateforme (`libcef.*` ou le framework) et des ressources. |
| `cef_window_test` | Ouvre une vraie fenêtre CEF Views, affiche du HTML et la ferme au bout de 3 s. Utilise un profil isolé par exécution et redirige les sous-processus vers `CefExecuteProcess`. |

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build/test -C Release --output-on-failure
```

Sous Linux sans écran, démarrez d'abord un affichage virtuel
(`Xvfb :99 & export DISPLAY=:99`) ; CTest fixe `DISPLAY=:99` pour le test de fenêtre.

### Intégration continue

`.github/workflows/{linux,macos,windows}.yml` s'exécutent à chaque push et pull
request, pour la distribution complète et la distribution minimale :

1. configuration et compilation du paquet et de ses trois tests ;
2. exécution des tests avec CTest ;
3. compilation des applications de [`example/`](example/) avec la distribution
   téléchargée et exécution de leur test de déploiement (`cef_example_deployment`) ;
4. publication des artefacts de compilation.

### Mainteneurs

- **Changer de version de CEF** : modifiez `CEF_VERSION` dans `CMakeLists.txt`,
  vérifiez que l'[index des builds CEF](https://cef-builds.spotifycdn.com/index.json)
  propose les archives standard et minimale pour chaque plateforme, puis
  reconfigurez depuis un répertoire de compilation vierge.
- **Publier une version** : une fois la CI au vert sur `main`, créez le tag
  `v<majeure CEF>.<mineure>.<correctif>` et publiez une release GitHub ;
  mettez à jour le tag dans ce README.
- **Conteneur de développement** : `.devcontainer/` fournit un environnement
  Linux identique à la CI.

### Dépannage

- **Téléchargement en échec ou bloqué** : gardez `CEF_ROBUST_DOWNLOAD=ON`, essayez
  `CEF_USE_MINIMAL_DIST=ON`, ou téléchargez l'archive vous-même et passez
  `-DCEF_LOCAL_ARCHIVE_PATH=/chemin/vers/cef_binary_….tar.bz2`.
- **`CEF distribution version mismatch`** : le répertoire de compilation ou
  l'archive contient une autre version de CEF. Supprimez le répertoire de
  compilation ou fournissez l'archive correspondante.
- **HTTP 404 au téléchargement** : la version configurée n'existe pas pour cette
  plateforme ; consultez la page des [builds CEF](https://cef-builds.spotifycdn.com/index.html).
- **`GPU process isn't usable` / plantages répétés des sous-processus** : les
  sous-processus ne sont pas redirigés ; voir [Écrire une application CEF](#écrire-une-application-cef).
- **Linux : erreur `chrome-sandbox` au démarrage** : appliquez la commande SUID
  affichée par la compilation ou désactivez la sandbox.

### Licence

Ce projet est distribué sous la licence de logiciel libre CeCILL v2.1 ;
voir [`CECILL-LICENSE.txt`](CECILL-LICENSE.txt). CEF et Chromium sont distribués
sous leurs propres licences, incluses dans la distribution téléchargée.

### Remerciements

- [Chromium Embedded Framework](https://bitbucket.org/chromiumembedded/cef)
- [CMake](https://cmake.org/)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)
