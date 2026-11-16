---
type: guide
updated: 2026-11-15
---

# Development

## Supported scope

The port is based on Pragtical 3.14.0 and SDL3 3.4.12. The current targets are:

| Target | Selector used by the scripts | Verification scope |
|---|---|---|
| `aros-x86_64-abiv1-pc` | `AROS_TARGET=mainline` | Pragtical 3.14.0 built on 2026-11-15. Startup, editing, Save As, overwrite, volume-root paths, command-line reopen and collected-byte checks passed. Native Intuition New, Select All, About and Quit commands passed. All 15 focused Lua cases, 6 shared-memory tests, 43 tokenizer tests and both language fixture tests passed. The released archive passed start, open, edit, save, external file changes, launcher and quit. |
| `aros-x86_64-abiv11-pc` | `AROS_TARGET=one` | Pragtical 3.14.0 built on 2026-11-15. The released archive passed start, open, edit, save, external file changes, launcher and quit on AROS One 1.3. The Lua test suites were not rerun on this target. |
| `aros-aarch64-abiv1-raspi` | `AROS_TARGET=raspi` | Pragtical 3.14.0 built on 2026-11-15 with the Clang toolchain. Start, open, edit, save, external file changes and quit passed under QEMU `raspi3b` (non-SMP system). Not run on a physical Raspberry Pi or on the SMP system. |

A hosted Apple Silicon build is a separate later target. No Pragtical build or runtime result is claimed for it.

The selectors are retained for compatibility with the existing build recipe. New release artifacts should use the full target names shown above.

## Prerequisites

The host needs Bash, Python 3, Ninja, `curl`, `patch`, `shasum` and a matching AROS cross-compiler and SDK for each target: GCC for the two x86_64 targets, Clang for the Raspberry Pi. The Raspberry Pi target also needs a libc++ built for it (`AROS_RASPI_CXXRT`), because HarfBuzz is C++ and that toolchain has no C++ standard library of its own. Install Meson in the repository's ignored virtual environment:

```sh
python3 -m venv .venv
.venv/bin/pip install 'meson>=0.63'
```

Copy `local.env.example` to `local.env` and set the toolchain and SDK locations. Generic `AROS_GCC_ROOT` and `AROS_SDK` values take precedence, followed by target-specific values in `local.env`. Relative paths in `local.env` resolve from its own directory.

Prepare the pinned source and patched work copy:

```sh
scripts/bootstrap.sh
```

Do not edit `upstream/pragtical/`. The bootstrap script refuses to recreate a dirty work tree; inspect any existing work before using `--recreate`.

## Build

Build each target separately:

```sh
AROS_TARGET=mainline scripts/fetch-sdl3.sh
AROS_TARGET=mainline scripts/build-sdl3.sh
AROS_TARGET=mainline scripts/build.sh

AROS_TARGET=one scripts/fetch-sdl3.sh
AROS_TARGET=one scripts/build-sdl3.sh
AROS_TARGET=one scripts/build.sh

AROS_TARGET=raspi scripts/fetch-sdl3.sh
AROS_TARGET=raspi scripts/build-sdl3.sh
AROS_TARGET=raspi scripts/build.sh
```

`scripts/fetch-sdl3.sh` leaves an existing SDL3 source directory alone. After the SDL3 patch list changes, remove `deps/<selector>/src/SDL3-3.4.12` and fetch again, otherwise that target keeps building the old sources.

The current editor profile is:

```text
-Djit=false
-Dportable=true
-Drenderer=true
-Drenderer_backend=surface
-Ddirmonitor_backends=aros,dummy
-Dppm=false
-Drepl_history=false
-Dnet=false
-Dopus:hardening=false
-Dopus:rtcd=disabled     (Raspberry Pi only)
```

The `aros` directory monitor uses dos.library file notification on the RAM disk and on SFS. FAT accepts a notification request for a directory but does not report changes to the entries inside it, so every other file system keeps the modification-time check of the `dummy` path. Opus cannot detect CPU features at run time on AArch64 AROS, hence the fixed code paths there.

The build writes the editor beneath `build/<selector>/meson/` and target-specific dependencies beneath `deps/<selector>/`. The existing selector-based output directories are retained for compatibility.

Pragtical 3.14.0 adds HarfBuzz and SDL3_mixer. `scripts/build.sh` applies the versioned HarfBuzz and Opus patches after Meson downloads them. The Opus hardening option is disabled because the target runtime does not provide the stack-check symbols. Reapplying these dependency patches is a no-op.

Use a fresh Meson configuration directory or a controlled `meson setup --wipe` after changing the SDK, compiler or link flags. Inspect the generated cross file and the actual compile and link commands; setting `AROS_SDK` alone does not prove that every tool uses that SDK.

Do not perform a full strip on the AROS executable; that variant caused a failure on x86_64 ABIv1. The packaging step below uses only `--strip-unneeded --remove-section .comment`. HarfBuzz selects `debugoptimized` in its own Meson file, so its debug sections can remain large even when the editor uses another top-level build type.

## Tests

Run the source-series and focused Lua checks from the repository root:

```sh
scripts/check-reproduction.sh
lua tests/save-as-volume-root.lua
lua tests/dirname-volume-root.lua
lua tests/argument-project-directory.lua
```

The three Lua scripts contain 15 cases covering AROS volume roots, nested paths, parentless relative paths, Linux paths and Windows paths. They exercise the path functions and handlers without a graphics display; they do not replace runtime testing.

The 3.14.0 runtime acceptance also ran `scripts/lua/tests/shmem.lua` through Pragtical's `test` command. All six tests passed, including two handles to one namespace, region growth and last-close cleanup. The tokenizer suite passed 43/43 and the language fixture suite passed 2/2 with 126 samples. On AROS, use `>` to capture their stdout; `*>` redirects stderr.

Native Intuition `File > New`, `Edit > Select All`, `Help > About` and `File > Quit` were exercised with the same commands as the application menu. Menu coverage does not qualify every command or dialog.

Runtime acceptance needs to cover each ABI separately:

- launch from a Shell, with and without a file argument;
- typing, selection, basic shortcuts and clipboard behavior;
- opening an existing file and creating a new one;
- Save As, repeated saving and overwriting;
- paths on `RAM:`, at a volume root, in a subdirectory and with spaces in the filename;
- closing and reopening a document, then exiting and relaunching the editor;
- byte-for-byte comparison of collected files.

Use writable storage for persistence checks and set an adequate Shell stack, such as `Stack 8000000`, until launcher stack handling has been verified in the test environment. A window opening is not evidence that editing or saving works.

## Renderer selection

`surface` is the default and is the only backend qualified by the current document tests. Pragtical also compiles `sdlrenderer` and `sdlgpu`; compilation alone does not establish that they work.

On the tested x86_64 ABIv1 system, SDL reported `software` as the default renderer, with `opengl` and `software` available. `SDL_GPUSupportsProperties()` returned false, so the `sdlgpu` backend is unavailable. Pragtical's `sdlrenderer` path remains unqualified. An OpenGL probe made the guest unresponsive and required a power-off; no working GPU acceleration is claimed.

Pragtical's `user/renderer` file and `PRAGTICAL_RENDERER` select a backend at process startup. Do not change the default without a working fallback and evidence for the selected driver.

## Portable package contents

A portable drawer needs the `pragtical` executable, its upstream `data/` and `doc/` directories, the initial `user/` data, the upstream license and `BUILD-MANIFEST.json`. Do not include the SDK, build trees, test reports or the installed development `usr/` hierarchy.

Assemble the drawer from a finished build and create its archive with:

```sh
AROS_TARGET=mainline scripts/make-drawer.sh 3.14.0-aros4
AROS_TARGET=mainline scripts/package.sh \
  build/mainline/drawer/Pragtical \
  dist/3.14.0-aros4/pragtical-3.14.0-aros4-aros-x86_64-abiv1-pc.zip
```

`make-drawer.sh` takes the program and its data from `meson install`, adds the licence, `packaging/README-AROS.txt`, the launcher, the icons (`scripts/make-icon.py`, stack 8000000 in the program icon), a `BUILD-MANIFEST.json` without machine paths and the apkg package description. The number after `-aros` in the release name is the package revision. `package.sh` needs `APKG_PACK` to point at `apkg-pack.pyz`.

The script applies `--strip-unneeded --remove-section .comment`, records the stripped and unstripped hashes in the manifest, writes `SHA256SUMS`, and checks the archive through an independent extraction. It does not change compiler optimization or runtime-test claims.

Test the extracted package rather than only the build directory. Check document open, edit, save, reopen and clean exit from that extracted copy.

Release `3.14.0-aros4` in `dist/3.14.0-aros4/` holds one archive per target, built by apkg-pack with an embedded package description, icons and `application.json`. Each was tested from the archive on its target; the stripped programs and the archive contents were scanned for build-machine paths. A full strip fails on x86_64; the safe strip form above also runs on the Raspberry Pi.
