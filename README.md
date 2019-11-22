# Corecollector

Corecollector is an application that collects the coredumps of applications which have crashed, aiding
you in debugging crashes.

## Building

```sh
meson --buildtype=release build
ninja -C build install
```