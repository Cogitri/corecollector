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
import std.process;
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
        writeln("ID\tExecutable\tPath\t\tSignal\tUID\tGID\tPID\tTimestamp");
        int i;
        foreach(x; this.coredumpDir.coredumps)
        {
            i++;
            writef(
                "%d\t%s\t\t%s\t%d\t%d\t%d\t%d\t%s\t\n",
                i,
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

    /// Return path to the coredump
    string getCorePath(uint coreNum) {
        return buildPath(
            coredumpDir.getTargetPath(),
            coredumpDir.coredumps[coreNum].generateCoredumpName(),
        );
    }

    /// Return path to the executable
    string getExePath(uint coreNum) {
        return buildPath(
            coredumpDir.coredumps[coreNum].exePath,
            coredumpDir.coredumps[coreNum].exe,
        );
    }

    /// Dump coredump `coreNum` to `targetPath`
    void dumpCore(uint coreNum, string targetPath) {
        File targetFile;

        switch(targetPath) {
            case "":
            case "stdout":
                targetFile = stdout;
                break;
            default:
                targetFile = File(targetPath, "w");
                break;
        }


        auto sourceFile = File(getCorePath(coreNum), "r");

        foreach (ubyte[] buffer; sourceFile.byChunk(new ubyte[4096])) {
            targetFile.rawWrite(buffer);
        }
    }

    /// Open coredump `coreNum` in debugger
    void debugCore(uint coreNum) {
        auto corePath = getCorePath(coreNum);
        auto exePath = getExePath(coreNum);
        auto debuggerPid = spawnProcess(["gdb", exePath, corePath]);
        scope(exit)
            wait(debuggerPid);
    }
}