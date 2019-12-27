[![Github Actions](https://github.com/Cogitri/corecollector/workflows/Run%20Unittests/badge.svg)](https://github.com/Cogitri/corecollector/actions)
[![codecov](https://codecov.io/gh/Cogitri/corecollector/branch/master/graph/badge.svg)](https://codecov.io/gh/Cogitri/corecollector)

# Corecollector

Corecollector is an application that collects the coredumps of applications which have crashed, aiding
you in debugging crashes.

## Building

```sh
meson --buildtype=release build
ninja -C build install
```
