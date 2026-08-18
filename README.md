# NAPS2.Sane.Binaries

[![NuGet](https://img.shields.io/nuget/v/NAPS2.Sane.Binaries)](https://www.nuget.org/packages/NAPS2.Sane.Binaries/)

NAPS2.Sane.Binaries provides precompiled [SANE](https://sane-project.org/) binaries for use with [NAPS2.Sdk](https://github.com/cyanfish/naps2/tree/master/NAPS2.Sdk).

Supported platforms:
- Mac 11+ arm64
- Mac 10.15+ x64

Linux binaries are not included as the expectation is to use the system-installed SANE.

Windows binaries are a work in progress. There are some limitations as SANE depends on Cygwin as a POSIX emulation layer, but Cygwin can't live in the same process as the .NET runtime.

## Building

Binaries are no longer committed to the repository; the GitHub Actions workflow
([build-mac.yml](.github/workflows/build-mac.yml)) builds them on every push and
publishes the NuGet package to this repository's GitHub Packages feed — a
`-ci.<n>` prerelease for pushes to main, a stable version for `v*` tags.

To build locally:

```
./scripts/apply-patches.sh
./scripts/build-mac-arm64.sh   # or build-mac-x64.sh on Intel
./scripts/build-config.sh
dotnet pack NAPS2.Sane.Binaries -c Release
```