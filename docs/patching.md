---
type: guide
updated: 2026-11-15
---

# Patch workflow

## Pinned source

`upstreams.json` records the upstream URL and full base commit. The current pin is Pragtical 3.14.0 at `5c05f09e081833b581fb5ecd10e64963dec87f03`.

The same repository ID, `pragtical`, is used in three places:

| Path | Purpose |
|---|---|
| `upstream/pragtical/` | Clean pinned checkout; never edited |
| `work/pragtical/` | Editable copy with the ordered patches applied |
| `patches/pragtical/` | Durable patches and the `series` file |

`upstreams.example.json` is only an unfilled example. The operational manifest is `upstreams.json`.

## Commands

Run these commands from the repository root:

| Operation | Command |
|---|---|
| Create or verify the source copies | `scripts/bootstrap.sh` |
| Rebuild the work copy after a pin or series change | `scripts/bootstrap.sh --recreate` |
| Save selected staged changes | `scripts/save-patch.sh <NNNN-name> --problem '…' --solution '…' --scope '…'` |
| Check reconstruction in an isolated temporary directory | `scripts/check-reproduction.sh` |

Read `scripts/save-patch.sh` before using it. Stage only the intended changes in `work/pragtical/`; do not add unrelated files. A successful save writes the patch and updates `series` before advancing the local baseline.

`bootstrap.sh --recreate` is not a routine cleanup command. Check the work tree, local files and Git state first. The script refuses a dirty tracked tree, but an ignored checkout can still contain material worth preserving.

## Patch series

`patches/pragtical/series` is the authoritative application order. The current series contains ten patches. Each patch records its base, rationale, scope and verification.

Patches 0005–0007 correct AROS volume-root handling in Save As, parent-directory selection and command-line startup. They are also included in [Pragtical PR #670](https://github.com/pragtical/pragtical/pull/670). The local port uses the patches regardless of that pull request's review state; do not submit a duplicate.

Patch 0008 fixes the Lua 5.4 language-test harness, patch 0009 adds native Intuition menu dispatch and patch 0010 fixes the native tokenizer's incomplete-result zero state. These patches remain local; no new public submission has been made.

SDL3 patches are separate from the Pragtical series. `scripts/fetch-sdl3.sh` applies the files in `patches/dependencies/` to the SDL3 source tree.

## Verification and base updates

`scripts/check-reproduction.sh` clones the local pinned checkout into a temporary directory and applies the complete series without modifying `upstream/` or `work/`. It proves clean application to the pin, not runtime behavior or the availability of every remote URL.

Run the Lua regressions in [the development guide](development.md#tests) after changing the path fixes. Rebuild and test both x86_64 ABIs after changing source code.

Treat an upstream version update as a separate change. Check which fixes have landed, adapt the remaining series, update the manifest, run reconstruction and regression checks, then rebuild and test the affected targets. Do not combine a version update with unrelated platform fixes.
