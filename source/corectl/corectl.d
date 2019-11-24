module corectl.corectl;

import corecollector.coredump;

import std.exception;
import std.file;
import std.format;
import std.path;
import std.stdio;

/// Class holding the logic of the `corectl` executable.
class CoreCtl {
    /// The `CoredumpDir` holding existing coredumps.
    CoredumpDir coredumpDir;

    /// ctor to construct with an existing `CoredumpDir`.
    this(CoredumpDir coreDir) {
        this.coredumpDir = coreDir;
        this.ensureCorrectSysctl();
    }

    /// Make sure that `corehelper` is set as the kernel's corecollector server
    void ensureCorrectSysctl() {
        string sysctlVal = readText("/proc/sys/kernel/core_pattern");

        string expectedVal = "|"
            ~ buildPath("@LIBEXECDIR@", "corehelper")
            ~ " -e=%e -p=%P -s=%s -t=%t";

        enforce(
            sysctlVal == expectedVal,
            format(
                "The sysctl value for 'kernel.core_pattern' is wrong!
                As such corehelper won't receive any coredumps from the kernel.
                Expected %s, got %s",
                expectedVal,
                sysctlVal,
            ),
        );
    }

    /// Write all available coredumps to the stdout
    void listCoredumps() {
        writeln("Executable\tSignal\tUID\tGID\tPID\tTimestamp");
        foreach(x; this.coredumpDir.coredumps)
        {
            writef(
                "%s\t\t%d\t%d\t%d\t%d\t%d\t\n",
                x.exe,
                x.sig,
                x.uid,
                x.gid,
                x.pid,
                x.timestamp,
            );
        }
    }
}