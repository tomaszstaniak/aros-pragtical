# Workflow scripts

Run commands from the repository root. Bash is required.

| Command | Purpose |
|---|---|
| `scripts/bootstrap.sh` | Create or verify the pinned upstream and patched work copy |
| `scripts/bootstrap.sh --recreate` | Rebuild the work copy after checking preservation requirements |
| `scripts/save-patch.sh` | Save selected staged work changes with patch metadata |
| `scripts/check-reproduction.sh` | Apply the complete series in an isolated temporary directory |
| `scripts/fetch-sdl3.sh` | Fetch and patch SDL3 3.4.12 for the selected target |
| `scripts/build-sdl3.sh` | Build the static SDL3 library and headers |
| `scripts/build.sh` | Configure and build Pragtical |
| `scripts/make-drawer.sh` | Assemble the portable drawer from a finished build |
| `scripts/make-icon.py` | Write an AROS PNG icon from a PNG picture |
| `scripts/package.sh` | Safely strip a prepared drawer, update its manifest and verify the package ZIP |
| `scripts/write-meson-cross.sh` | Generate a Meson cross file from the selected environment |

`env.sh` is the shared configuration loader. Copy `local.env.example` to ignored `local.env` for machine-specific values. Explicit environment values take precedence, followed by `local.env` and then portable defaults.

See `docs/development.md` for target selection and build commands, and `docs/patching.md` for source preservation rules.
