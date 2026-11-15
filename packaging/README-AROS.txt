Pragtical 3.14.0 for AROS
=========================

Pragtical is a lightweight code editor written in C and Lua. This is an
AROS build of upstream version 3.14.0:
https://github.com/pragtical/pragtical

Archives
--------

  x86_64, ABIv11 distributions       ...-aros-x86_64-abiv11-pc.zip
  x86_64, mainline AROS (ABIv1)      ...-aros-x86_64-abiv1-pc.zip
  Raspberry Pi, mainline AROS        ...-aros-aarch64-abiv1-raspi.zip

A program built for one of these systems does not run on the others.

Installation
------------

Extract the archive anywhere on a writable disk. Keep the data, doc and
user drawers beside the program.

Start it with a double-click on the pragtical icon; the icon sets the
stack the editor needs. From a Shell opened in the Pragtical drawer:

  Execute run-pragtical

To open a file or a project directory from a Shell, raise the stack
yourself and pass the path:

  Stack 8000000
  pragtical Work:myproject

Settings, key bindings and plugins you add live in the user drawer. When
you update, copy your user drawer into the new version.

What works
----------

- Editing, syntax highlighting for 116 languages, 79 colour themes.
- Project tree, find in files, autocompletion, code folding, diff view,
  line wrapping, macros, workspaces, the settings window.
- Native AROS menus.
- Text is UTF-8. Characters typed on the keyboard follow the system
  character set chosen in the Locale preferences, so a Polish keymap
  gives Polish letters.
- Copy and paste through the system clipboard.
- Files and drawers changed outside the editor: on the RAM disk and on
  SFS volumes the project tree follows such changes at once, and the
  editor offers to reload an open document that was changed. On other
  file systems, such as FAT, the editor checks the watched drawers
  periodically instead.

Limitations
-----------

- External programs cannot be started from the editor. Plugins that rely
  on them (language servers, linters, formatters, a terminal) do not work.
- No networking and no plugin manager. Plugins can be installed by
  copying them into user/plugins.
- Drawing uses the software renderer. Hardware acceleration is not used.

Licence
-------

Pragtical is distributed under the MIT licence, see LICENSE. The licences
of the bundled libraries are in doc/licenses.md.
