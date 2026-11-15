# Project patches

Create one directory per modified external repository, using its ID from
`upstreams.json`. Each directory contains a `series` file and its numbered patches.
An empty `series` is valid before the first patch; it represents the unchanged pin.
Do not create a fictional patch or pick a base commit just to fill the template.

The central upstream-patches standard defines the shared contract for
`patches/pragtical/`. SDL3 3.4.12 patches live in
[patches/dependencies/](dependencies/README.md) and are applied by
`scripts/fetch-sdl3.sh`, not by the Pragtical series.
