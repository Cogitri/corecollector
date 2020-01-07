corectl(1)

# NAME

corectl - User binary for interacting with corecollector

# SYNOPSIS
*corectl* [options...] [command]

# DESCRIPTION

Corectl allows you to interact with previously collected coredumps, e.g.
by showing additional information or opening the coredump in a debugger.

# OPTIONS
The corectl application accepts the following command line parameters:

*-h, --help*
	Show help options.

*-v,--version*
	Print program version.

*-d, --debug=[0-2]*
	Set the debug level, -1 being the lowest (and default), only printing errors.
	0 also prints warnings, 1 prints informational log messages and 2 enables
	trace log messages.

# COMMANDS
The corectl application also expects users to supply one of the following commands:

*backtrace* [ID]
	Print the backtrace of the coredump identified by ID.

*debug* [ID]
	Open the coredump identified by ID in a debugger.

*dump* [ID] [FILE]
	Dump the coredump identified by ID to a file denoted by FILE. Defaults to
	stdout.

*info* [ID]
	Print ore detailed information for the coredump identified by ID.

*list*
	List all available coredumps.

# SEE ALSO
*corecollector.conf*(5)

# BUGS
See bugs at https://github.com/Cogitri/corecollector

# AUTHOR
Rasmus Thomsen
