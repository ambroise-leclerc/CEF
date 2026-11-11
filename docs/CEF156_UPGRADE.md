# CEF 156 upgrade (#41)

The package pins `156.0.28+g57389f0+chromium-156.0.8078.88`, the newest
stable CEF version common to all seven supported platform/architecture variants
in the [upstream index](https://cef-builds.spotifycdn.com/index.json) checked on
2026-11-11. CEF 156 was still beta when the 154 upgrade (#31) was made.

## Consumer changes

Same as the CEF 154 upgrade: CMake 3.24+, a C++20 compiler, and a fresh build
directory when migrating (a cached distribution with another version is
rejected). `-Dapi_version=15600` selects the released 15600 API.

Platform detection now derives the archive from the target and sets
`PROJECT_ARCH` for the SDK (#40); `CEF_PLATFORM` can be overridden.

## Validation performed locally (Linux aarch64)

- All 14 standard/minimal archive URLs returned HTTP 200.
- Configured natively with the minimal distribution and `api_version=15600`,
  built the wrapper (210 units, no `-m64`) and all tests; `cef_sanity_test` and
  `cef_resources_test` passed. `cef_window_test` was built but not run (no display).
- Not run locally: macOS, Windows, standard distribution. CI covers them.
