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