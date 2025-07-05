# Chromium Embedded Framework (CEF) Packaging

[![Linux Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/linux.yml)
[![macOS Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/macos.yml)
[![Windows Build](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml/badge.svg)](https://github.com/ambroise-leclerc/CEF/actions/workflows/windows.yml)

> :fr: **Ce README est disponible en français plus bas dans ce document.**

## Overview

This repository provides a packaging solution for the Chromium Embedded Framework (CEF) on Linux, macOS, and Windows, enabling seamless integration into C++ projects. The packaging is designed for use with [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake), allowing other projects to easily fetch and build CEF as a dependency.

## Usage

### With CPM.cmake (Recommended)
To use this CEF package in your own CMake project, simply add the following line to your `CMakeLists.txt`:

```cmake
CPMAddPackage("gh:ambroise-leclerc/CEF@137.0.4")

# Create your executable
add_executable(my_app main.cpp)

# Configure CEF application (links libraries + deploys runtime files)
cef_configure_app(my_app)
```

This will automatically download, configure, and build CEF as part of your project, ensuring all dependencies and minimal tests are handled as defined in this repository. The `cef_configure_app()` function provides automated runtime deployment, copying all necessary CEF files to your executable directory.

#### Manual Linking (Alternative)
If you prefer manual control over linking and deployment:

```cmake
CPMAddPackage("gh:ambroise-leclerc/CEF@137.0.4")

# Create your executable
add_executable(my_app main.cpp)

# Link CEF libraries manually
target_link_libraries(my_app PRIVATE cef)

# Optional: Deploy runtime files automatically
cef_deploy_runtime(my_app)
```

### Without CPM.cmake
If you do not use CPM.cmake, you may include this repository as a subdirectory or use CMake's FetchContent module:

**Option 1: Add as a subdirectory**
```cmake
git clone https://github.com/ambroise-leclerc/CEF.git
add_subdirectory(CEF)
```

**Option 2: Use FetchContent**
```cmake
include(FetchContent)
FetchContent_Declare(
  cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        main # or a specific release/tag
)
FetchContent_MakeAvailable(cef)
```

### Example: Advanced CPM.cmake usage with options

You can use the non-compact CPM.cmake notation to set CEF options such as `CEF_ROBUST_DOWNLOAD` and `CEF_USE_MINIMAL_DIST`:

```cmake
CPMAddPackage(
  NAME cef
  GITHUB_REPOSITORY ambroise-leclerc/CEF
  VERSION 137.0.4
  OPTIONS
    "CEF_ROBUST_DOWNLOAD ON"         # Enables robust download with retries and fallbacks (default: ON)
    "CEF_USE_MINIMAL_DIST ON"        # Download the minimal CEF distribution instead of the full one (default: OFF)
)
# Link CEF to your application target
# target_link_libraries(my_app PRIVATE cef)
```

- `CEF_ROBUST_DOWNLOAD`: If ON (default), enables a robust download strategy with retries and fallbacks for large files or unreliable networks.
- `CEF_USE_MINIMAL_DIST`: If ON, downloads the smaller _minimal CEF distribution. If OFF (default), downloads the full CEF package (includes more resources and tools).

## Features
- Provides a reproducible and automated packaging of CEF for Linux, macOS, and Windows
- **Automated Runtime Deployment**: Automatically copies CEF runtime files (DLLs, resources, locales) to your executable directory
- **Cross-Platform Deployment**: Handles platform-specific deployment requirements (Windows DLLs, Linux RPATH, macOS frameworks)
- **One-Function Setup**: Use `cef_configure_app()` for complete CEF application configuration
- Integrates with CMake and CPM.cmake for easy consumption
- Includes a minimal sanity test to verify correct integration
- Continuous Integration (CI) with GitHub Actions for reliability across all platforms

### Deployment Functions
- `cef_configure_app(target)`: Complete CEF application setup (linking + deployment)
- `cef_deploy_runtime(target)`: Deploy only runtime files to executable directory
- `cef_get_settings_paths(var)`: Get correct resource paths for CEF initialization

For detailed deployment documentation, see [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Platform Support

This CEF packaging supports the following platforms:
- **Linux (x64)**: Uses `cef_binary_*_linux64.tar.bz2` distribution
- **Linux (ARM64)**: Uses `cef_binary_*_linuxarm64.tar.bz2` distribution
- **macOS (x64)**: Uses `cef_binary_*_macosx64.tar.bz2` distribution
- **macOS (ARM64)**: Uses `cef_binary_*_macosarm64.tar.bz2` distribution
- **Windows (x64)**: Uses `cef_binary_*_windows64.tar.bz2` distribution
- **Windows (ARM64)**: Uses `cef_binary_*_windowsarm64.tar.bz2` distribution

### Build Requirements

#### Windows
- Visual Studio 2019 or later (with C++ tools)
- CMake 3.27 or later
- Windows 10 SDK

#### Linux
- GCC or Clang compiler
- CMake 3.27 or later

#### macOS
- Xcode or Command Line Tools
- CMake 3.27 or later

The platform is automatically detected during the CMake configuration phase, and the appropriate CEF binary distribution is downloaded and configured.

**Current CEF Version**: 137.0.4+g8614a8d+chromium-137.0.7151.6

This version is chosen for its stability and cross-platform availability. If you need a different CEF version, you can modify the `CEF_VERSION` variable in the main `CMakeLists.txt` file, but ensure that the version you choose has builds available for all platforms you intend to support.

## Prerequisites
- Operating system: Linux, macOS, or Windows (x64)
- C++ compiler:
  - **Linux**: GCC 11 or newer recommended
  - **macOS**: Xcode or Command Line Tools
  - **Windows**: Visual Studio 2019 or later
- [CMake](https://cmake.org/) version 3.27 or later (workflows use 3.27.9)
- Git

## Building and Testing (for maintainers)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ambroise-leclerc/CEF.git
   cd CEF
   ```
2. **Configure the project:**
   ```bash
   cmake -B build -S .
   ```
3. **Build the test target:**
   ```bash
   cmake --build build --config Release --target cef_sanity_test
   ```
4. **Run the CEF sanity test:**
   - **Linux/macOS:**
     ```bash
     ./build/test/cef_sanity_test
     ```
   - **Windows:**
     ```bash
     ./build/test/Release/cef_sanity_test.exe
     ```

## Continuous Integration

The project employs GitHub Actions for CI on Linux, macOS, and Windows. The workflows are defined in `.github/workflows/` with separate files for each platform:
- `linux.yml` - Ubuntu with Unix Makefiles (default)
- `macos.yml` - macOS with Unix Makefiles (default)
- `windows.yml` - Windows with Visual Studio 2022 (MSBuild)

Each workflow is triggered on every push and pull request and performs the following steps:
- Install required dependencies
- Configure the project using CMake
- Build the `cef_sanity_test` target
- Execute the test to ensure correct functionality
- Upload build artifacts

## Development Container

A development container is provided via `.devcontainer/` for a reproducible development environment. It ensures the correct versions of CMake and Ninja are installed, matching the CI configuration.

## Troubleshooting

### CEF Download Issues
If you encounter a 404 error when downloading CEF binaries, it usually means:
1. The specified CEF version doesn't have a build for your platform
2. The CEF version string format has changed

To resolve this:
1. Check the [CEF Builds](https://cef-builds.spotifycdn.com/) page for available versions
2. Update the `CEF_VERSION` in `CMakeLists.txt` to a version that supports your platform
3. Ensure the version string format matches what's available on the CDN

### Platform Detection Issues
The build system automatically detects your platform. If detection fails:
- Ensure you're running on a supported platform (Linux x64, macOS x64, or Windows x64)
- Check the CMake output for platform detection messages

## Licensing

This project is distributed under the terms of the CeCILL License. See `CECILL-LICENSE.txt` for details.

## Acknowledgements

- [Chromium Embedded Framework (CEF)](https://bitbucket.org/chromiumembedded/cef)
- [Kitware CMake](https://cmake.org/)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)

---

For academic or industrial use, please cite the relevant upstream projects and adhere to their respective licences.

---

## Présentation

Ce dépôt propose une solution de packaging automatisée pour Chromium Embedded Framework (CEF) sur Linux, macOS et Windows. Il permet une intégration de CEF dans des projets C++ modernes. L'intégration avec [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake) facilite la gestion des dépendances et l'automatisation du processus de build.

## Utilisation

### Avec CPM.cmake (recommandé)
Pour intégrer ce package CEF à votre projet CMake, ajoutez simplement la ligne suivante à votre `CMakeLists.txt` :

```cmake
CPMAddPackage("gh:ambroise-leclerc/CEF@137.0.4")

# Créez votre exécutable
add_executable(my_app main.cpp)

# Configurez l'application CEF (liaison + déploiement des fichiers runtime)
cef_configure_app(my_app)
```

Cette commande télécharge, configure et compile automatiquement CEF, en assurant la gestion des dépendances et l'exécution des tests de validation. La fonction `cef_configure_app()` fournit un déploiement automatisé des fichiers runtime, copiant tous les fichiers CEF nécessaires dans le répertoire de votre exécutable.

#### Liaison manuelle (alternative)
Si vous préférez un contrôle manuel sur la liaison et le déploiement :

```cmake
CPMAddPackage("gh:ambroise-leclerc/CEF@137.0.4")

# Créez votre exécutable
add_executable(my_app main.cpp)

# Liez les bibliothèques CEF manuellement
target_link_libraries(my_app PRIVATE cef)

# Optionnel : Déployez automatiquement les fichiers runtime
cef_deploy_runtime(my_app)
```

### Sans CPM.cmake
Vous pouvez également inclure ce dépôt comme sous-répertoire ou utiliser le module FetchContent de CMake :

**Option 1 : Sous-répertoire**
```cmake
git clone https://github.com/ambroise-leclerc/CEF.git
add_subdirectory(CEF)
```

**Option 2 : FetchContent**
```cmake
include(FetchContent)
FetchContent_Declare(
  cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        main # ou un tag spécifique
)
FetchContent_MakeAvailable(cef)
```

### Exemple : Utilisation avancée de CPM.cmake avec options

Vous pouvez utiliser la notation CPM.cmake non compacte pour définir des options CEF telles que `CEF_ROBUST_DOWNLOAD` et `CEF_USE_MINIMAL_DIST` :

```cmake
CPMAddPackage(
  NAME cef
  GITHUB_REPOSITORY ambroise-leclerc/CEF
  VERSION 137.0.4
  OPTIONS
    "CEF_ROBUST_DOWNLOAD ON"         # Active le téléchargement robuste avec réessais et solutions de repli (par défaut : ON)
    "CEF_USE_MINIMAL_DIST ON"        # Télécharge la distribution minimale de CEF au lieu de la version complète (par défaut : OFF)
)
# Liez CEF à votre cible applicative
# target_link_libraries(my_app PRIVATE cef)
```

- `CEF_ROBUST_DOWNLOAD` : Si activé (par défaut), active une stratégie de téléchargement robuste avec réessais et solutions de repli pour les fichiers volumineux ou les réseaux peu fiables.
- `CEF_USE_MINIMAL_DIST` : Si activé, télécharge la plus petite _distribution minimale de CEF. Si désactivé (par défaut), télécharge le package complet de CEF (inclut plus de ressources et d'outils).

## Fonctionnalités
- Packaging reproductible et automatisé de CEF pour Linux, macOS et Windows
- **Déploiement automatisé des fichiers runtime** : Copie automatiquement les fichiers runtime CEF (DLL, ressources, locales) dans le répertoire de votre exécutable
- **Déploiement multiplateforme** : Gère les exigences de déploiement spécifiques à chaque plateforme (DLL Windows, RPATH Linux, frameworks macOS)
- **Configuration en une fonction** : Utilisez `cef_configure_app()` pour une configuration complète d'application CEF
- Intégration transparente avec CMake et CPM.cmake
- Test de validation minimal pour garantir l'intégration
- Intégration continue (CI) via GitHub Actions sur toutes les plateformes

### Fonctions de déploiement
- `cef_configure_app(target)` : Configuration complète d'application CEF (liaison + déploiement)
- `cef_deploy_runtime(target)` : Déploie uniquement les fichiers runtime dans le répertoire de l'exécutable
- `cef_get_settings_paths(var)` : Obtient les chemins de ressources corrects pour l'initialisation CEF

Pour la documentation détaillée du déploiement, voir [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Plateformes supportées
- **Linux (x64)** : `cef_binary_*_linux64.tar.bz2`
- **Linux (ARM64)** : `cef_binary_*_linuxarm64.tar.bz2`
- **macOS (x64)** : `cef_binary_*_macosx64.tar.bz2`
- **macOS (ARM64)** : `cef_binary_*_macosarm64.tar.bz2`
- **Windows (x64)** : `cef_binary_*_windows64.tar.bz2`
- **Windows (ARM64)** : `cef_binary_*_windowsarm64.tar.bz2`

## Prérequis de compilation

### Windows
- Visual Studio 2019 ou ultérieur (outils C++)
- CMake 3.27 ou ultérieur
- Windows 10 SDK

### Linux
- GCC ou Clang
- CMake 3.27 ou ultérieur

### macOS
- Xcode ou Command Line Tools
- CMake 3.27 ou ultérieur

La détection de la plateforme est automatique lors de la configuration CMake, et la distribution binaire appropriée est téléchargée.

**Version CEF actuelle** : 137.0.4+g8614a8d+chromium-137.0.7151.6

Pour utiliser une autre version, modifiez la variable `CEF_VERSION` dans le fichier `CMakeLists.txt` principal, en veillant à la disponibilité multiplateforme.

## Prérequis
- Système : Linux, macOS ou Windows (x64)
- Compilateur C++ :
  - **Linux** : GCC 11 ou plus recommandé
  - **macOS** : Xcode ou Command Line Tools
  - **Windows** : Visual Studio 2019 ou ultérieur
- [CMake](https://cmake.org/) 3.27 ou ultérieur (workflows : 3.27.9)
- Git

## Compilation et tests (pour les mainteneurs)

1. **Cloner le dépôt :**
   ```bash
   git clone https://github.com/ambroise-leclerc/CEF.git
   cd CEF
   ```
2. **Configurer le projet :**
   ```bash
   cmake -B build -S .
   ```
3. **Compiler le test :**
   ```bash
   cmake --build build --config Release --target cef_sanity_test
   ```
4. **Exécuter le test :**
   - **Linux/macOS :**
     ```bash
     ./build/test/cef_sanity_test
     ```
   - **Windows :**
     ```bash
     ./build/test/Release/cef_sanity_test.exe
     ```

## Intégration continue

Les workflows GitHub Actions assurent la compilation, le test et la publication des artefacts sur Linux, macOS et Windows. Les fichiers de configuration sont situés dans `.github/workflows/`.

## Conteneur de développement

Un conteneur de développement est fourni via `.devcontainer/` pour garantir un environnement cohérent avec la CI (versions de CMake et Ninja).

## Dépannage

### Problèmes de téléchargement CEF
- Vérifiez la disponibilité de la version sur [CEF Builds](https://cef-builds.spotifycdn.com/)
- Modifiez `CEF_VERSION` si nécessaire
- Vérifiez le format de la chaîne de version

### Problèmes de détection de plateforme
- Assurez-vous d'utiliser une plateforme supportée (Linux x64, macOS x64, Windows x64)
- Consultez la sortie CMake pour les messages de détection

## Licence

Projet sous licence CeCILL. Voir `CECILL-LICENSE.txt`.

## Remerciements
- [Chromium Embedded Framework (CEF)](https://bitbucket.org/chromiumembedded/cef)
- [Kitware CMake](https://cmake.org/)
- [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake)

---

Pour tout usage académique ou industriel, merci de citer les projets amont concernés et de respecter leurs licences respectives.
