# FFmpeg Static Builds

Automation scripts and GitHub Actions workflows for producing statically linked FFmpeg archives across desktop and mobile platforms.
Artifacts are meant to be consumed by downstream apps (e.g., the music desktop/mobile clients) that need a predictable FFmpeg toolchain without compiling from source each time.

---

## Supported Targets

| Workflow                    | Platforms (matrix)                                                                               | Output archive name              | Trigger                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------ | -------------------------------- | ------------------------------------------------ |
| `ffmpeg-desktop-build.yaml` | `linux-x86_64`, `macos-x86_64`, `macos-arm64`, `windows-x86_64`                                  | `ffmpeg-<tag>-<platform>.tar.gz` | `workflow_dispatch`, push tags `ffmpeg-*`        |
| `ffmpeg-mobile-build.yaml`  | `android-arm64-v8a`, `android-armeabi-v7a`, `android-x86_64`, `ios-arm64`, `ios-simulator-arm64` | `ffmpeg-<tag>-<platform>.tar.gz` | `workflow_dispatch`, push tags `ffmpeg-mobile-*` |
| Desktop release stage       | collects all desktop artifacts & SHA256 checksums                                                | Release assets                   | automatic on tag                                 |

> Default FFmpeg tag (`FFMPEG_VERSION`) is `n7.0.2`, but can be overridden when launching the workflow manually.

---

## Repository Structure

```
.github/workflows/
  ffmpeg-desktop-build.yaml   # Linux, macOS (Intel/ARM), Windows static builds
  ffmpeg-mobile-build.yaml    # Android NDK + iOS toolchains
  ...                         # (Release workflow on tags)
```

Each workflow is self-contained and installs the platform-specific toolchain before compiling FFmpeg.

---

## How the Builds Work

### Desktop (Linux/macOS/Windows)

* Clones the FFmpeg source tag (`FFMPEG_SOURCE_URL`).
* Configures FFmpeg with static linking (`--disable-shared --enable-static`) plus DASH/HTTP support.
* Linux/macOS rely on system POSIX toolchains (autotools, nasm, yasm, openssl).
* Windows uses MSYS2 with MinGW64, exporting LLVM-compatible binutils (gcc-ar, strip, etc.) and `pkg-config` to pick up static OpenSSL.

### Mobile (Android/iOS)

* **Android**: installs NASM/YASM, uses Android NDK r26d. Targets three ABIs (arm64, armeabi-v7a, x86_64) with the LLVM toolchain and sysroot.
* **iOS**: builds arm64 (device) and arm64 simulator. Uses xcrun toolchain, embeds bitcode, and disables shared libs/programs for smaller archives.

---

## Usage

### Manual run

Go to the **Actions** tab → choose **Build FFmpeg Desktop** or **Build FFmpeg Mobile** → click **Run workflow** → optionally override the FFmpeg version.

### Tag-triggered

* Push a tag like `ffmpeg-n7.0.2` to build desktop binaries.
* Push `ffmpeg-mobile-n7.0.2` (or any `ffmpeg-mobile-*` tag) to build mobile binaries.

### Artifacts

Each matrix job uploads `ffmpeg-<ffmpeg-version>-<platform>.tar.gz` to the workflow run.
Desktop workflow also aggregates a `checksums.txt`.

### Release assets

On `ffmpeg-*` tags the release job attaches all desktop archives + checksums to the GitHub release.

---

## Customizing the Build

* **Configure flags**: Edit the respective `CONFIG_ARGS` (desktop) or `CONFIGURE_FLAGS` (mobile) arrays to enable/disable codecs, protocols, or add hardware acceleration.
* **Toolchain tweaks**: Update the package lists inside each workflow to add platform-specific dependencies.
* **FFmpeg source**: Change `FFMPEG_SOURCE_URL` if you need a fork or mirror.

---

## Local Development (Optional)

To reproduce builds locally:

### Linux / macOS

```bash
sudo apt-get install autoconf automake build-essential cmake git pkg-config \
     libtool nasm yasm texinfo zlib1g-dev libssl-dev
# or use Homebrew on macOS with similar packages

./configure --disable-shared --enable-static ...
make -j$(nproc)
```

### Windows

Install MSYS2 and run:

```bash
pacman -Syu
pacman -S mingw-w64-x86_64-toolchain mingw-w64-x86_64-binutils \
        mingw-w64-x86_64-pkg-config mingw-w64-x86_64-openssl \
        mingw-w64-x86_64-cmake
```

Export `PATH=/mingw64/bin:$PATH` and run the configure script with `--cross-prefix=x86_64-w64-mingw32-`.

### Android

* Install Android NDK r26d and set `ANDROID_NDK_HOME`.
* Ensure NASM/YASM are installed.
* Use the same configure flags as in the workflow.

### iOS

* Requires Xcode command-line tools (`xcrun`) and an Apple developer toolchain.

---

## Contributing

1. Fork the repository.
2. Modify workflows or build scripts.
3. Test via manual workflow runs (keep an eye on matrix outputs).
4. Submit a PR explaining the change (e.g., new codec, updated FFmpeg tag).
5. Use Conventional Commit messages (e.g., `build: enable opus`).

Please keep changes minimal and focused; each addition affects multiple platforms.

---

## Maintainers & License

The project is currently private/internal. Update this section when a license or public roadmap is finalized.

---

*This README should give anyone cloning the `ffmpeg-static-builds` repo a clear understanding of what the project does, how to trigger the builds, and how to customize or extend them.*
