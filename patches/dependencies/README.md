# Dependency patches

These patches are separate from the Pragtical source series.

## SDL3 3.4.12

`scripts/fetch-sdl3.sh` applies the pinned contrib AROS patch first, then:

- `sdl3-3.4.12-langinfo-guard.diff` includes `langinfo.h` only when the corresponding feature is configured;
- `sdl3-3.4.12-aros-text-input.diff` translates AROS raw keys into SDL text-input events;
- `sdl3-3.4.12-hidden-window-framebuffer.diff` provides the CPU framebuffer while a window is still hidden, before Intuition creates its native window;
- `sdl3-3.4.12-application-menu.diff` lets an application supply an Intuition menu and receive its menu selections as SDL user events;
- `sdl3-3.4.12-optional-iconv.diff` lets a build without libiconv define `SDL_AROS_NO_ICONV`, so SDL3 uses its own character-set converter. The Raspberry Pi SDK has no libiconv; the x86_64 builds do not set the macro and are unchanged.

Applications that do not define `SDL_ArosMenu` retain the stock SDL menu. Pragtical's native New, Select All, About and Quit commands passed on x86_64 ABIv1.

## Meson wrap dependencies

`scripts/build.sh` applies these patches after Meson has downloaded the matching subproject. Applying an already applied patch is a no-op.

- `harfbuzz-13.0.1-aros-pthread.diff` finds `libpthread` directly on AROS instead of using the generic threads dependency that adds the unsupported `-pthread` driver option.
- `opus-1.6.1-hardening-stack-protector.diff` makes `-fstack-protector-strong` follow Opus's `hardening` option. The AROS profile sets `-Dopus:hardening=false` because the target runtime does not provide the stack-check symbols.

A patch is applied only when its versioned subproject directory exists. A future wrap update needs its own review instead of forcing an old patch onto new sources.
