# CEF 154 upgrade (#31)

The package pins `154.0.34+g14c5a08+chromium-154.0.8037.98`, the newest
stable CEF version common to all seven supported platform/architecture variants
in the [upstream index](https://cef-builds.spotifycdn.com/index.json) checked on
2026-10-15. CEF 156 was listed as beta.

## Consumer changes

- Use CMake 3.24+ and a C++20 compiler. Both exported library targets propagate
  the C++20 requirement. Upstream recommends GCC 10+, Xcode 16+, or VS 2022.
- Reconfigure with a fresh build directory when migrating from CEF 137.
  A local archive or cached distribution with a different version is rejected.
- The wrapper's selected `CEF_API_VERSION` is propagated to consumers, including
  the upstream Windows default `CEF_API_VERSION_LAST`. An explicit
  `-Dapi_version=15400` selects the released 15400 API on every platform.
- Windows deployment follows the upstream runtime manifest: standalone
  `libEGL.dll` and `libGLESv2.dll` are no longer mandatory. Older distributions
  that contain them can still deploy them through the helper's optional list.
- The macOS ARM64 framework requires macOS 13.0 at runtime, as reported by its
  Mach-O load commands. Upstream recommends macOS 14.5+ as the build host.

## Validation performed locally (macOS ARM64)

- All 14 standard/minimal archive URLs for Linux x64/ARM64, macOS x64/ARM64,
  and Windows x86/x64/ARM64 returned HTTP 200.
- Downloaded the macOS ARM64 standard and minimal archives and Windows x64
  minimal archive; checked their SHA-1 values against the upstream index.
- Inspected the Windows x64 archive: its runtime files and resources match the
  new deployment list; standalone ANGLE DLLs are absent.
- Built the wrapper and all three tests against the minimal distribution;
  all three CTest tests passed, including the window integration test.
- Downloaded and configured the standard distribution through the default
  robust downloader, built with `api_version=15400`, and passed all three tests.
- Built `simple_app`, `simple_test` and `example_cef_app` through the example's
  CPM integration; passed `cef_example_deployment`.
- Verified rejection of a stale CEF 137 distribution at configure time.
- Configured successfully with CMake 3.24.3 and built/tested with CMake 4.3.1.
- Verified that a FetchContent source override reuses the downloaded distribution
  without downloading another archive.
- Validated the three GitHub Actions workflows with `actionlint`.

The sanity test now compares the loaded runtime's eight version components with
its build headers and fails if the macOS framework cannot be loaded.

## Release

The workflows cover standard and minimal distributions on Linux, macOS and
Windows, including compilation of the examples and their deployment test. They
passed on `main` for PR #37 and PR #38, which also fixed the window test's
subprocess dispatch on Windows (#37) and isolated its profile per run (#26).

The package is published as tag `v154.0.34`; the README references that tag.
