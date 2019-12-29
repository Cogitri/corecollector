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

import corecollector.globals;
import corecollector.coredump;

import core.stdc.stdlib;

import std.conv;
import std.exception;
import std.experimental.logger;
import std.datetime;
import std.file;
import std.format;
import std.path;
import std.process;
import std.stdio;
import std.string;

immutable humansCountFromOne = 1;

/// Class holding the logic of the `corectl` executable.
class CoreCtl
{
    /// The `CoredumpDir` holding existing coredumps.
    const CoredumpDir coredumpDir;

    /// ctor to construct with an existing `CoredumpDir`.
    this(in CoredumpDir coreDir) @safe
    {
        this.coredumpDir = coreDir;
    }

    /// Write all available coredumps to the stdout
    void listCoredumps() @safe
    {
        // All of these are the maximum length of the Data + the length of the string describing them (e.g. "ID", "SIGNAL")
        immutable auto maxIdLength = this.coredumpDir.coredumps.length.to!string.length + 2;
        immutable auto signalLength = 8;
        immutable auto allIDlength = 8;
        immutable auto timestampLength = 21;

        // No need to fill the last string up with spaces with leftJustify
        writef("%s %s %s %s %s %s EXE\n", leftJustify("ID", maxIdLength, ' '), leftJustify("SIGNAL ",
                signalLength, ' '), leftJustify("UID", allIDlength, ' '), leftJustify("GID", allIDlength, ' '),
                leftJustify("PID", allIDlength, ' '), leftJustify("TIMESTAMP",
                    timestampLength, ' '));
        int i;
        foreach (x; this.coredumpDir.coredumps)
        {
            i++;
            writef("%s %s %s %s %s %s %s\n", leftJustify(i.to!string, maxIdLength,
                    ' '), leftJustify(x.sig.to!string, signalLength, ' '),
                    leftJustify(x.uid.to!string, allIDlength, ' '), leftJustify(x.gid.to!string, allIDlength, ' '),
                    leftJustify(x.pid.to!string, allIDlength, ' '),
                    leftJustify(x.timestamp.toSimpleString(), timestampLength, ' '), x.exePath);
        }
    }

    /// Make sure the coredump exists. Starts counting from 0 being the first one.
    bool ensureCoredump(in uint coreNum) const @safe
    {
        return (coredumpDir.coredumps.length) >= coreNum + 1;
    }

    /// Return path to the coredump
    string getCorePath(in uint coreNum) const @safe
    {
        return buildPath(coredumpDir.getTargetPath(),
                coredumpDir.coredumps[coreNum].generateCoredumpName());
    }

    /// Return path to the executable
    string getExePath(in uint coreNum) const @safe
    {
        return buildPath(coredumpDir.coredumps[coreNum].exePath);
    }

    /// Dump coredump `coreNum` to `targetPath`
    void dumpCore(in uint coreNum, in string targetPath) const
    {
        if (!ensureCoredump(coreNum))
        {
            stderr.writefln("Coredump number %s doesn't exist!", coreNum + humansCountFromOne);
            exit(1);
        }

        File targetFile;

        tracef("Dumping core %d", coreNum);

        switch (targetPath)
        {
        case "":
        case "stdout":
            targetFile = stdout;
            break;
        default:
            targetFile = File(targetPath, "w");
            break;
        }

        auto sourceFile = File(getCorePath(coreNum), "r");

        foreach (ubyte[] buffer; sourceFile.byChunk(new ubyte[4096]))
        {
            targetFile.rawWrite(buffer);
        }
    }

    /// Open coredump `coreNum` in debugger
    void debugCore(in uint coreNum) const
    {
        if (!ensureCoredump(coreNum))
        {
            stderr.writefln("Coredump number %d doesn't exist!", coreNum + humansCountFromOne);
            exit(1);
        }
        auto corePath = getCorePath(coreNum);
        auto exePath = getExePath(coreNum);
        auto debuggerPid = spawnProcess(["gdb", exePath, corePath]);
        scope (exit)
            wait(debuggerPid);
    }

    /// Print information about coredump `coreNum`
    void infoCore(in uint coreNum) const
    {
        if (!ensureCoredump(coreNum))
        {
            stderr.writefln("Coredump number %d doesn't exist!", coreNum + humansCountFromOne);
            exit(1);
        }
        writefln("Info about coredump: %d\n" ~ "Coredump path:       %s",
                coreNum + humansCountFromOne, getCorePath(coreNum));
    }
}

version (unittest)
{
    CoreCtl setupCoreCtl(string corePath)
    {
        auto savedStdin = new RestoreFd(stdin);

        // Fix stdin and stdout again if things go south
        scope (exit)
        {
            savedStdin.restoreFd(stdin);
        }

        // Setup stdin so we can read from it in addCoredump()
        auto dummyDumpPath = deleteme() ~ "1";
        scope (exit)
            remove(dummyDumpPath);
        immutable auto dummyCoredump = "coredump";
        auto coredumpFile = File(dummyDumpPath, "w");
        coredumpFile.write(dummyCoredump);
        coredumpFile.close();
        stdin.reopen(dummyDumpPath, "r");

        mkdir(corePath);

        auto coredump = new Coredump(1000, 1000, 1000, 6,
                SysTime.fromISOExtString("2018-01-01T10:30:00Z"), "testExe", "/usr/bin/testExe");
        auto coredumpDir = new CoredumpDir(corePath, false);
        coredumpDir.addCoredump(coredump);
        auto coreCtl = new CoreCtl(coredumpDir);
        return coreCtl;
    }
}

unittest
{
    auto savedStdout = new RestoreFd(stdout);
    scope (exit)
        savedStdout.restoreFd(stdout);

    const auto corePath = deleteme() ~ "dir";
    auto coreCtl = setupCoreCtl(corePath);
    scope (exit)
        rmdirRecurse(corePath);

    // Setup stdout so we can verify the output.
    auto dummyStdoutPath = deleteme() ~ "2";
    stdout.reopen(dummyStdoutPath, "w");

    coreCtl.listCoredumps();

    // So we can print stuff again and don't have to abuse stderr
    savedStdout.restoreFd(stdout);

    immutable auto expectedVal = "ID  SIGNAL   UID      GID      PID      TIMESTAMP             EXE\n"
        ~ "1   6        1000     1000     1000     2018-Jan-01 10:30:00Z /usr/bin/testExe\n";
    const auto actualVal = readText(dummyStdoutPath);
    assert(expectedVal == actualVal, format("Expected \n%s, got \n%s", expectedVal, actualVal));
}

unittest
{
    const auto corePath = deleteme() ~ "dir";
    auto coreCtl = setupCoreCtl(corePath);
    assert(coreCtl.ensureCoredump(0));
    assert(!coreCtl.ensureCoredump(1));
}
