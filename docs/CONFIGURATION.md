# Configuration reference / Référence de configuration

[English](#english) · [Français](#français)

## English

### Options

Pass options through CPM (`OPTIONS "NAME VALUE"`) or on the command line (`-DNAME=VALUE`).

| Option | Default | Effect |
|---|---|---|
| `CEF_USE_MINIMAL_DIST` | `OFF` | Download the `_minimal` distribution: Release binaries only, no debug builds or sample applications. |
| `CEF_ROBUST_DOWNLOAD` | `ON` | Retry the download with CMake, then curl, then wget. |
| `CEF_LOCAL_ARCHIVE_PATH` | empty | Use a CEF archive already on disk instead of downloading it. |
| `FETCHCONTENT_SOURCE_DIR_CEF_BINARIES` | empty | Reuse an already extracted CEF distribution (no download at all). |
| `CEF_WRAPPER_BUILD_SKIP` | `OFF` | Do not build `libcef_dll_wrapper`. |
| `CEF_PLATFORM` | from the target | Force the archive platform: `linux64`, `linuxarm64`, `macosx64`, `macosarm64`, `windows64`, `windowsarm64` or `windows32`. |
| `PROJECT_ARCH` | from `CEF_PLATFORM` | Architecture given to the CEF SDK (`x86_64`, `arm64`, `x86`). A value you set is kept. |
| `api_version` | upstream default | CEF API version, e.g. `-Dapi_version=15600`. Propagated to consumers. |

The platform is derived from the **target** (`CMAKE_SYSTEM_PROCESSOR`,
`CMAKE_OSX_ARCHITECTURES`, the generator platform or compiler architecture on
Windows), not from the host, so cross-compiling selects the right archive.

The configured CEF version is checked against the distribution's headers: a stale
cached distribution or an archive of another version stops the configure step.

### Other ways to integrate

**CPM with options**

```cmake
CPMAddPackage(
  NAME cef
  GITHUB_REPOSITORY ambroise-leclerc/CEF
  GIT_TAG v156.0.28
  OPTIONS "CEF_USE_MINIMAL_DIST ON"
)
```

**Manual linking**

```cmake
target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
cef_deploy_runtime(my_app)  # optional: copy the runtime files only
```

**FetchContent / add_subdirectory**

```cmake
include(FetchContent)
FetchContent_Declare(cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        v156.0.28)
FetchContent_MakeAvailable(cef)
target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
```

`add_subdirectory(path/to/CEF)` on a checkout of the tag works the same way.

**Installed package**

```cmake
find_package(CEF REQUIRED)
target_link_libraries(my_app PRIVATE CEF::cef CEF::libcef_dll_wrapper)
```

The installed package ships neither the runtime files nor the deployment
functions: deploy `libcef`, its resources and locales yourself.

### Targets

| Build from source | Installed package | Content |
|---|---|---|
| `cef` | `CEF::cef` | CEF headers and the `libcef` library or macOS framework. |
| `libcef_dll_wrapper` | `CEF::libcef_dll_wrapper` | C++ wrapper (`CefRefPtr`, `CefPostTask`, …). Required by C++ applications. |

Both require C++20 and propagate the selected `CEF_API_VERSION`.

### Runtime deployment

| Function | Purpose |
|---|---|
| `cef_configure_app(target)` | Link both targets, deploy the runtime, set the static MSVC runtime on Windows. |
| `cef_deploy_runtime(target)` | Deploy the runtime only. |
| `cef_get_settings_paths(var)` | Return C++ lines setting `resources_dir_path` / `locales_dir_path` for the deployed layout. |

- **Windows / Linux**: the binaries from the distribution's `Release/` directory,
  the resources (`icudtl.dat`, `*.pak`, `locales/`) and a copy of them in `Resources/`.
- **macOS**: `Chromium Embedded Framework.framework` in the bundle's `Frameworks/`;
  load it with `CefScopedLibraryLoader`.
- **Linux sandbox**: the build prints the `chown`/`chmod 4755` command for
  `chrome-sandbox` but never runs it. Run it yourself or set `settings.no_sandbox = true`.

More in [`DEPLOYMENT.md`](DEPLOYMENT.md).

### Build requirements

- **Linux**: GCC 10+ or a C++20 Clang; X11 development packages for the window test.
- **macOS**: Xcode 16+ (macOS 14.5+ recommended as build host). The ARM64 framework needs macOS 13.0+ at runtime.
- **Windows**: Visual Studio 2022 with the C++ workload and a Windows 10/11 SDK.

### Continuous integration

`.github/workflows/{linux,macos,windows}.yml` run on every push and pull request,
for the full and the minimal distribution: build, run the tests with CTest, build
the [`example/`](../example/) applications and run their deployment test.

### Maintainers

- **Changing the CEF version**: update `CEF_VERSION` in `CMakeLists.txt`, check that the
  [CEF build index](https://cef-builds.spotifycdn.com/index.json) lists standard and
  minimal archives for every platform, then reconfigure from a clean build directory.
- **Releasing**: once CI passes on `main`, tag `v<CEF major>.<minor>.<patch>`, publish
  a GitHub release and update the tag in the README.
- **Dev container**: `.devcontainer/` provides a Linux environment matching CI.

### Troubleshooting

- **Download fails or stalls**: keep `CEF_ROBUST_DOWNLOAD=ON`, try `CEF_USE_MINIMAL_DIST=ON`,
  or pass `-DCEF_LOCAL_ARCHIVE_PATH=/path/to/cef_binary_….tar.bz2`.
- **`CEF distribution version mismatch`**: the build directory or archive holds another
  CEF version. Delete the build directory or provide the matching archive.
- **HTTP 404 on download**: the configured version has no build for this platform;
  see the [CEF builds](https://cef-builds.spotifycdn.com/index.html).
- **`unrecognized command-line option '-m64'` on ARM**: use a tag containing the
  target-based platform detection, or pass `-DPROJECT_ARCH=arm64`.
- **`GPU process isn't usable` / repeated subprocess crashes**: subprocesses are not
  dispatched; call `CefExecuteProcess` first in `main()`.
- **Linux: `chrome-sandbox` error at startup**: apply the SUID command printed by the
  build or disable the sandbox.

## Français

### Options

Passez les options via CPM (`OPTIONS "NOM VALEUR"`) ou en ligne de commande (`-DNOM=VALEUR`).

| Option | Défaut | Effet |
|---|---|---|
| `CEF_USE_MINIMAL_DIST` | `OFF` | Télécharge la distribution `_minimal` : binaires Release uniquement, sans builds de débogage ni applications d'exemple. |
| `CEF_ROBUST_DOWNLOAD` | `ON` | Réessaie le téléchargement avec CMake, puis curl, puis wget. |
| `CEF_LOCAL_ARCHIVE_PATH` | vide | Utilise une archive CEF déjà présente au lieu de la télécharger. |
| `FETCHCONTENT_SOURCE_DIR_CEF_BINARIES` | vide | Réutilise une distribution CEF déjà extraite (aucun téléchargement). |
| `CEF_WRAPPER_BUILD_SKIP` | `OFF` | Ne compile pas `libcef_dll_wrapper`. |
| `CEF_PLATFORM` | selon la cible | Force la plateforme de l'archive : `linux64`, `linuxarm64`, `macosx64`, `macosarm64`, `windows64`, `windowsarm64` ou `windows32`. |
| `PROJECT_ARCH` | selon `CEF_PLATFORM` | Architecture transmise au SDK CEF (`x86_64`, `arm64`, `x86`). Une valeur que vous fixez est conservée. |
| `api_version` | défaut amont | Version de l'API CEF, par ex. `-Dapi_version=15600`. Propagée aux consommateurs. |

La plateforme est déduite de la **cible** (`CMAKE_SYSTEM_PROCESSOR`,
`CMAKE_OSX_ARCHITECTURES`, plateforme du générateur ou architecture du compilateur
sous Windows), pas de la machine hôte : la compilation croisée choisit la bonne archive.

La version CEF configurée est comparée aux en-têtes de la distribution : une
distribution en cache périmée ou une archive d'une autre version arrête la configuration.

### Autres modes d'intégration

**CPM avec options**

```cmake
CPMAddPackage(
  NAME cef
  GITHUB_REPOSITORY ambroise-leclerc/CEF
  GIT_TAG v156.0.28
  OPTIONS "CEF_USE_MINIMAL_DIST ON"
)
```

**Liaison manuelle**

```cmake
target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
cef_deploy_runtime(my_app)  # optionnel : copie seulement les fichiers runtime
```

**FetchContent / add_subdirectory**

```cmake
include(FetchContent)
FetchContent_Declare(cef
  GIT_REPOSITORY https://github.com/ambroise-leclerc/CEF.git
  GIT_TAG        v156.0.28)
FetchContent_MakeAvailable(cef)
target_link_libraries(my_app PRIVATE cef libcef_dll_wrapper)
```

`add_subdirectory(chemin/vers/CEF)` sur une copie du tag fonctionne de la même façon.

**Paquet installé**

```cmake
find_package(CEF REQUIRED)
target_link_libraries(my_app PRIVATE CEF::cef CEF::libcef_dll_wrapper)
```

Le paquet installé ne contient ni les fichiers runtime ni les fonctions de
déploiement : déployez vous-même `libcef`, ses ressources et ses locales.

### Cibles

| Compilation depuis les sources | Paquet installé | Contenu |
|---|---|---|
| `cef` | `CEF::cef` | En-têtes CEF et bibliothèque `libcef` ou framework macOS. |
| `libcef_dll_wrapper` | `CEF::libcef_dll_wrapper` | Wrapper C++ (`CefRefPtr`, `CefPostTask`…). Indispensable aux applications C++. |

Les deux exigent C++20 et propagent la valeur de `CEF_API_VERSION` retenue.

### Déploiement du runtime

| Fonction | Rôle |
|---|---|
| `cef_configure_app(cible)` | Lie les deux cibles, déploie le runtime, choisit le runtime MSVC statique sous Windows. |
| `cef_deploy_runtime(cible)` | Déploie seulement le runtime. |
| `cef_get_settings_paths(var)` | Renvoie les lignes C++ qui fixent `resources_dir_path` / `locales_dir_path` pour la disposition déployée. |

- **Windows / Linux** : les binaires du répertoire `Release/` de la distribution,
  les ressources (`icudtl.dat`, `*.pak`, `locales/`) et une copie de celles-ci dans `Resources/`.
- **macOS** : `Chromium Embedded Framework.framework` dans le dossier `Frameworks/`
  du bundle ; chargez-le avec `CefScopedLibraryLoader`.
- **Sandbox Linux** : la compilation affiche la commande `chown`/`chmod 4755` pour
  `chrome-sandbox` mais ne l'exécute jamais. Lancez-la vous-même ou utilisez `settings.no_sandbox = true`.

Plus de détails dans [`DEPLOYMENT.md`](DEPLOYMENT.md).

### Prérequis de compilation

- **Linux** : GCC 10+ ou Clang compatible C++20 ; paquets de développement X11 pour le test de fenêtre.
- **macOS** : Xcode 16+ (macOS 14.5+ recommandé pour compiler). Le framework ARM64 exige macOS 13.0+ à l'exécution.
- **Windows** : Visual Studio 2022 avec la charge de travail C++ et un SDK Windows 10/11.

### Intégration continue

`.github/workflows/{linux,macos,windows}.yml` s'exécutent à chaque push et pull
request, pour la distribution complète et la minimale : compilation, tests CTest,
compilation des applications de [`example/`](../example/) et test de déploiement.

### Mainteneurs

- **Changer de version de CEF** : modifiez `CEF_VERSION` dans `CMakeLists.txt`, vérifiez que l'
  [index des builds CEF](https://cef-builds.spotifycdn.com/index.json) propose les archives
  standard et minimale pour chaque plateforme, puis reconfigurez depuis un répertoire vierge.
- **Publier une version** : une fois la CI au vert sur `main`, créez le tag
  `v<majeure CEF>.<mineure>.<correctif>`, publiez une release GitHub et mettez à jour le tag dans le README.
- **Conteneur de développement** : `.devcontainer/` fournit un environnement Linux identique à la CI.

### Dépannage

- **Téléchargement en échec ou bloqué** : gardez `CEF_ROBUST_DOWNLOAD=ON`, essayez
  `CEF_USE_MINIMAL_DIST=ON`, ou passez `-DCEF_LOCAL_ARCHIVE_PATH=/chemin/vers/cef_binary_….tar.bz2`.
- **`CEF distribution version mismatch`** : le répertoire de compilation ou l'archive
  contient une autre version de CEF. Supprimez le répertoire ou fournissez l'archive correspondante.
- **HTTP 404 au téléchargement** : la version configurée n'existe pas pour cette plateforme ;
  consultez les [builds CEF](https://cef-builds.spotifycdn.com/index.html).
- **`unrecognized command-line option '-m64'` sur ARM** : utilisez un tag contenant la
  détection de plateforme basée sur la cible, ou passez `-DPROJECT_ARCH=arm64`.
- **`GPU process isn't usable` / plantages répétés des sous-processus** : les sous-processus
  ne sont pas redirigés ; appelez `CefExecuteProcess` en premier dans `main()`.
- **Linux : erreur `chrome-sandbox` au démarrage** : appliquez la commande SUID affichée
  par la compilation ou désactivez la sandbox.
