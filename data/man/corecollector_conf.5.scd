corecollector.conf(5)

# NAME

corecollector.conf - configuration for corecollector

# DESCRIPTION

The *corecollector.conf* file is used to configure corecollector. As of now it
supports the following, not case sensitive, keywords:

*compression*
	This sets what compression algorithm should be used for compression.
	Zlib is supported, while no compression is the default.

*maxSize*
	This sets the maximum size (in KByte) of a coredump. If the coredump
	is bigger than this, then it will be discarded.

*targetPath*
	This sets the path to where to save coredumps to.

*logPath*
	This sets the path to where corehelper logs to when run to collect
	a coredump. Do note that corecollector also logs to syslog, so setting
	this to /dev/null disable logging to a file and will lead to corecollector
	only logging to syslog.

*enableDebug*
	Whether to enable debugging for corehelper, the binary run to collect
	a coredump.

*maxDirSize*
	Sets the maximum size the entire coredump directory specified by
	targetPath may grow to before corehelper starts deleting old coredumps.

# FILES

_/etc/corecollector/corecollector.conf_++
	Configuration for corecollector, a coredump collector.

# EXAMPLES

\# What compression to use for coredumps.++
\# Available choices: none zlib++
compression = none++
\# The maximum size of coredumps.++
\# Unset or set to 0 to set no size limit.++
\# Measured in KByte, must be whole numbers.++
maxSize = 0++
\# The path to save coredumps to.++
targetPath = /var/lib/corecollector++
\# Where to log to. Pass /dev/null to only log to syslog++
logPath = /var/log/corecollector.log++
\# Enable debugging++
enableDebug = false++
\# The maximum size of the coredumpdir.++
\# Unset or set to 0 to set no size limit.++
\# Measured in KByte, must be whole numbers.++
maxDirSize = 0

# SEE ALSO

*corectl*(1)

# BUGS

See bugs at https://github.com/Cogitri/corecollector

# AUTHORS

Rasmus Thomsen
