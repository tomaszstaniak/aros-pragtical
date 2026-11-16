# Dependency patches

These patches are separate from the Pragtical source series.

## SDL3 3.4.12

`scripts/fetch-sdl3.sh` applies the pinned contrib AROS patch first, then:

- `sdl3-3.4.12-langinfo-guard.diff` includes `langinfo.h` only when the corresponding feature is configured;
- `sdl3-3.4.12-aros-text-input.diff` translates AROS raw keys into SDL text-input events;
- `sdl3-3.4.12-hidden-window-framebuffer.diff` provides the CPU framebuffer while a window is still hidden, before Intuition creates its native window;
- `sdl3-3.4.12-application-menu.diff` lets an application supply an Intuition menu and receive its menu selections as SDL user events;
- `sdl3-3.4.12-optional-iconv.diff` lets a build without libiconv define `SDL_AROS_NO_ICONV`, so SDL3 uses its own character-set converter. The Raspberry Pi SDK has no libiconv; the x86_64 builds do not set the macro and are unchanged;
- `sdl3-3.4.12-aros-charset-clipboard.diff` makes typed characters and clipboard text follow the system character set, and makes copying work. A typed byte was taken to be ISO 8859-1, so a Polish keymap (ISO 8859-2) gave wrong letters; the set now comes from the `CHARSET` variable through codesets.library, with ISO 8859-1 as the fallback. The clipboard writer stored its IFF header as C integers, which is unreadable on little-endian processors; it now writes through iffparse.library. Reading a clip without a UTF8 chunk converts from the system set instead of passing the bytes through.
- `sdl3-3.4.12-aros-minimize-fullscreen.diff` makes a minimised window recoverable and keeps fullscreen on the Workbench screen. Minimising closed the window and left nothing to bring it back; it now puts the program's icon on the Workbench, and a double click there opens the window again. The iconify gadget in the title bar does the same. Fullscreen without a display mode opened a separate screen without a title bar or depth gadget; it is now a borderless window on the public screen below the screen bar, so the screen's depth gadget and the menus stay reachable. A window that asks for a display mode still gets its own screen. Restoring a bordered window no longer shrinks it by the border size, and the AppWindow registration is removed with its window. The zoom gadget switches between the window's size and the screen below the bar, and the application's minimum size is applied when the window opens; before, the zoom gadget shrank the window to nothing and the editor stopped. Closing a window to reopen it drops its queued messages and resets the key state, so a key released in between does not stay held. Every AppMessage is replied: Workbench waits for that reply, and without it a file dropped on the window froze the desktop (the same defect was fixed in the SDL2 port, deadwood2/contrib abdd0267).

Applications that do not define `SDL_ArosMenu` retain the stock SDL menu. Pragtical's native New, Select All, About and Quit commands passed on x86_64 ABIv1.

## Meson wrap dependencies

`scripts/build.sh` applies these patches after Meson has downloaded the matching subproject. Applying an already applied patch is a no-op.

- `harfbuzz-13.0.1-aros-pthread.diff` finds `libpthread` directly on AROS instead of using the generic threads dependency that adds the unsupported `-pthread` driver option.
- `opus-1.6.1-hardening-stack-protector.diff` makes `-fstack-protector-strong` follow Opus's `hardening` option. The AROS profile sets `-Dopus:hardening=false` because the target runtime does not provide the stack-check symbols.

A patch is applied only when its versioned subproject directory exists. A future wrap update needs its own review instead of forcing an old patch onto new sources.
