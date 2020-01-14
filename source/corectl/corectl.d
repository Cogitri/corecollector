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

import corecollector.configuration : Compression;
import corecollector.coredump;
import corecollector.globals;

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

class NoSuchCoredumpException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}
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

    /// Decompresses the coredump to a temporary directory. Returns the
    /// path to the coredump
    string decompressCore(in uint coreNum) const
    {
        auto coredump = coredumpDir.coredumps[coreNum];
        const auto coreFileName = coredump.generateCoredumpName();
        const auto corePath = buildPath(tempDir(), coreFileName);
        auto coreFile = File(corePath, "w");
        scope (exit)
            coreFile.close();
        this.decompressCore(coreNum, coreFile);
        return corePath;
    }

    /// Decompresses the coredump to a set `File`. The `File` must be in
    /// writeable
    void decompressCore(in uint coreNum, File targetFile) const
    {
        auto coredump = coredumpDir.coredumps[coreNum];
        coredump.decompressCore(coredumpDir.getTargetPath(), targetFile);
    }

    /// Dump coredump `coreNum` to `targetPath`
    void dumpCore(in uint coreNum, in string targetPath) const
    {

        enforce!NoSuchCoredumpException(ensureCoredump(coreNum),
                format("Coredump number %s doesn't exist!", coreNum + humansCountFromOne));

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

        try
        {
            this.decompressCore(coreNum, targetFile);
        }
        catch (NoCompressionException e)
        {
            auto sourceFile = File(getCorePath(coreNum), "r");

            foreach (ubyte[] buffer; sourceFile.byChunk(new ubyte[4096]))
            {
                targetFile.rawWrite(buffer);
            }
        }
    }

    /// Open coredump `coreNum` in debugger
    void debugCore(in uint coreNum) const
    {
        enforce!NoSuchCoredumpException(ensureCoredump(coreNum),
                format("Coredump number %s doesn't exist!", coreNum + humansCountFromOne));

        string corePath;

        try
        {
            corePath = this.decompressCore(coreNum);
        }
        catch (NoCompressionException e)
        {
            corePath = this.getCorePath(coreNum);
        }

        const auto exePath = this.getExePath(coreNum);
        auto debuggerPid = spawnProcess(["gdb", exePath, corePath]);

        scope (exit)
            wait(debuggerPid);
    }

    /// Print the backtrace of the coredump `coreNum` to stdout
    void backtraceCore(in uint coreNum) const
    {
        enforce!NoSuchCoredumpException(ensureCoredump(coreNum),
                format("Coredump number %s doesn't exist!", coreNum + humansCountFromOne));

        string corePath;

        try
        {
            corePath = this.decompressCore(coreNum);
        }
        catch (NoCompressionException e)
        {
            corePath = this.getCorePath(coreNum);
        }

        auto exePath = this.getExePath(coreNum);
        immutable auto gdbArgs = [
            "--batch", "-ex", "set width 0", "-ex", "set height 0", "-ex",
            "set verbose off", "-ex", "bt"
        ];
        auto gdb = execute(["gdb"] ~ gdbArgs ~ [exePath, corePath]);
        if (gdb.status != 0)
        {
            errorf("Failed to get backtrace via gdb %s", gdb.output);
        }
        else
        {
            import std.regex : regex, replaceAll;

            auto removeLWPRegex = regex(".*New LWP [0-9].*");
            auto outputWithoutLWP = gdb.output.replaceAll(removeLWPRegex, "");
            string output;
            foreach (line; outputWithoutLWP.split('\n'))
            {
                if (line != "")
                {
                    output ~= line ~ "\n";
                }
            }
            writeln(output);
        }
    }

    /// Print information about coredump `coreNum`
    void infoCore(in uint coreNum) const @safe
    {
        enforce!NoSuchCoredumpException(ensureCoredump(coreNum),
                format("Coredump number %s doesn't exist!", coreNum + humansCountFromOne));

        writefln("Info about coredump: %d\n" ~ "Coredump path:       %s",
                coreNum + humansCountFromOne, this.getCorePath(coreNum));
    }
}

version (unittest)
{
    CoreCtl setupCoreCtl(string corePath, Compression compression = Compression.None)
    {
        auto savedStdin = new RestoreFd(stdin);

        // Fix stdin and stdout again if things go south
        scope (exit)
        {
            savedStdin.restoreFd(stdin);
        }

        // Setup stdin so we can read from it in addCoredump()
        auto dummyDumpPath = tempFile();
        scope (exit)
            remove(dummyDumpPath);
        immutable auto dummyCoredump = "coredump";
        auto coredumpFile = File(dummyDumpPath, "w");
        coredumpFile.write(dummyCoredump);
        coredumpFile.close();
        stdin.reopen(dummyDumpPath, "r");

        mkdir(corePath);

        auto coredump = new Coredump(1000, 1000, 1000, 6, SysTime.fromISOExtString(
                "2018-01-01T10:30:00Z"), "testExe", "/usr/bin/testExe", compression);
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

    const auto corePath = tempFile();
    auto coreCtl = setupCoreCtl(corePath);
    scope (exit)
        executeShell(format("rm -rf %s", corePath));

    // Setup stdout so we can verify the output.
    auto dummyStdoutPath = tempFile();
    scope (exit)
        remove(dummyStdoutPath);
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
    const auto corePath = tempFile();
    scope (exit)
        executeShell(format("rm -rf %s", corePath));
    auto coreCtl = setupCoreCtl(corePath);
    assert(coreCtl.ensureCoredump(0));
    assert(!coreCtl.ensureCoredump(1));
}

unittest
{
    const auto corePath = tempFile();
    const auto coreCtl = setupCoreCtl(corePath);
    scope (exit)
        executeShell(format("rm -rf %s", corePath));

    auto dumpPath = tempFile();
    scope (exit)
        remove(dumpPath);

    coreCtl.dumpCore(0, dumpPath);
    immutable auto expectedVal = "coredump";
    const auto actualVal = readText(dumpPath);
    assert(expectedVal == actualVal, format("Expected %s, got %s", expectedVal, actualVal));

    auto savedStdout = new RestoreFd(stdout);
    scope (exit)
        savedStdout.restoreFd(stdout);

    // Setup stdout so we can verify the output.
    auto dummyStdoutPath = tempFile();
    scope (exit)
        remove(dummyStdoutPath);
    stdout.reopen(dummyStdoutPath, "w");

    coreCtl.dumpCore(0, "stdout");

    savedStdout.restoreFd(stdout);

    const auto actualValStdout = readText(dummyStdoutPath);
    assert(expectedVal == actualValStdout, format("Expected %s, got %s",
            expectedVal, actualValStdout));

    assertThrown!NoSuchCoredumpException(coreCtl.dumpCore(1, "stdout"));
}

unittest
{
    auto savedStdout = new RestoreFd(stdout);
    scope (exit)
        savedStdout.restoreFd(stdout);

    const auto corePath = tempFile();
    const auto coreCtl = setupCoreCtl(corePath);
    scope (exit)
        executeShell(format("rm -rf %s", corePath));

    // Setup stdout so we can verify the output.
    auto dummyStdoutPath = tempFile();
    scope (exit)
        remove(dummyStdoutPath);
    stdout.reopen(dummyStdoutPath, "w");

    coreCtl.infoCore(0);

    savedStdout.restoreFd(stdout);

    immutable auto expectedVal = format("Info about coredump: 1\nCoredump path:       %s\n",
            buildPath(corePath, coreCtl.coredumpDir.coredumps[0].generateCoredumpName()));

    const auto actualVal = readText(dummyStdoutPath);
    assert(expectedVal == actualVal, format("Expected %s, got %s", expectedVal, actualVal));

    assertThrown!NoSuchCoredumpException(coreCtl.infoCore(1));
}

unittest
{
    auto savedStdout = new RestoreFd(stdout);
    scope (exit)
        savedStdout.restoreFd(stdout);

    const auto corePath = tempFile();
    const auto coreCtl = setupCoreCtl(corePath, Compression.Zlib);
    scope (exit)
        executeShell(format("rm -rf %s", corePath));

    const auto coredumpPath = coreCtl.decompressCore(0);
    // Set in setupCoreCtl
    immutable expectedVal = "coredump";
    auto generatedVal = readText(coredumpPath);
    assert(expectedVal == generatedVal, format("Expected %s, got %s", expectedVal, generatedVal));
}
