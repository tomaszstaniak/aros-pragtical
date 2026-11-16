# Pragtical for AROS

This repository contains the build recipe, tests and patch series for a Pragtical 3.14.0 port to AROS with SDL3. Release 3.14.0-aros3 covers x86_64 ABIv11 distributions, x86_64 mainline AROS (ABIv1) and the Raspberry Pi.

Pragtical 3.14.0 has passed bounded checks on each target covering start, editing, saving, changes made outside the editor and the extracted package; the Raspberry Pi build was run under QEMU only. These checks do not qualify the full plugin ecosystem or every editor feature.

## Downloads

Built archives for each system are on the [Releases](https://github.com/tomaszstaniak/aros-pragtical/releases) page, with their SHA-256 sums.

## Source

Everything that differs from upstream Pragtical is in this repository:

- `patches/pragtical/`: the ordered changes to the editor, applied to the upstream commit pinned in `upstreams.json`;
- `patches/dependencies/`: the changes to SDL3, HarfBuzz and Opus;
- `scripts/`: the commands that fetch the pinned sources, apply the patches, build and package;
- `packaging/`: the files added to the released drawer.

`scripts/bootstrap.sh` recreates the complete patched editor source in `work/pragtical/`.

## Documentation

- [Build and test](docs/development.md): prerequisites, target selection, commands and current limitations.
- [Patch workflow](docs/patching.md): pinned sources, editable work copy and durable patches.

## Source layout

```text
upstreams.json          pinned Pragtical source identity
upstream/pragtical/     clean checkout; never edited
work/pragtical/         editable source with the patch series applied
patches/pragtical/      ordered Pragtical patches
patches/dependencies/   SDL3 platform patches
scripts/                reproduction and build commands
tests/                  focused Lua regressions
build/, deps/, dist/    local generated output
```

The clean upstream checkout and editable work copy are local material. The durable source changes are the versioned patches in this repository.
