/*
    Copyright (c) 2019 Rasmus Thomsen

    This file is part of corecollector (see https://github.com/Cogitri/corecollector).

    corecollector is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    corecollector is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with corecollector.  If not, see <https://www.gnu.org/licenses/>.
*/

module corectl.corectl;

import corecollector.coredump;

import hunt.logging;

import std.exception;
import std.datetime;
import std.file;
import std.format;
import std.path;
import std.stdio;

/// Class holding the logic of the `corectl` executable.
class CoreCtl {
    /// The `CoredumpDir` holding existing coredumps.
    immutable CoredumpDir coredumpDir;

    /// ctor to construct with an existing `CoredumpDir`.
    this(immutable CoredumpDir coreDir) {
        this.coredumpDir = coreDir;
        this.ensureCorrectSysctl();
    }

    /// Make sure that `corehelper` is set as the kernel's corecollector server
    void ensureCorrectSysctl() {
        string sysctlVal = readText("/proc/sys/kernel/core_pattern");

        string expectedVal = "|"
            ~ buildPath("@LIBEXECDIR@", "corehelper")
            ~ " -e=%e -E=%E -p=%P -s=%s -t=%t -u=%u -g=%g\n";

        if (sysctlVal != expectedVal) {
            errorf(
                "The sysctl value for 'kernel.core_pattern' is wrong!
                As such corehelper won't receive any coredumps from the kernel.
                Expected %s, got %s",
                expectedVal,
                sysctlVal,
            );
        }
    }

    /// Write all available coredumps to the stdout
    void listCoredumps() {
        writeln("Executable\tPath\t\tSignal\tUID\tGID\tPID\tTimestamp");
        foreach(x; this.coredumpDir.coredumps)
        {
            writef(
                "%s\t\t%s\t%d\t%d\t%d\t%d\t%s\t\n",
                x.exe,
                x.exePath,
                x.sig,
                x.uid,
                x.gid,
                x.pid,
                x.timestamp.toSimpleString(),
            );
        }
    }
}