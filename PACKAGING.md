### Dependencies

Corecollector currently depends on the `gdb` binary during runtime for the
`backtrace` and `debug` subcommands.

### Users/Groups

Additionally, corecollector also expects the group and user set via the
`coredump_group` and `coredump_user` meson options to be available during runtime.
