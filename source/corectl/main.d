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

module corecollector.corecollector;

import corecollector.configuration;
import corecollector.coredump;
static import corecollector.globals;
import corecollector.logging;
import corectl.corectl;
import corectl.options;

static import core.stdc.errno;

import std.algorithm;
import std.algorithm.mutation : copy;
import std.array;
import std.exception;
import std.experimental.logger;
import std.file;
import std.format;
import std.path;
import std.stdio;

int main(string[] args)
{
    Options options;
    auto exMsg = collectExceptionMsg(options = new Options(args));
    if (exMsg)
    {
        stderr.writeln(exMsg);
        return 1;
    }

    if (options.showHelp)
    {
        writeln(helpText);
        return 0;
    }
    else if (options.showVersion)
    {
        writeln(corecollector.globals.corecollectorVersion);
        return 0;
    }

    try
    {
        startLogging(options.debugLevel, stderr);
    }
    catch (InvalidLogLevelException e)
    {
        stderr.writeln(e.msg);
        return 1;
    }

    Configuration conf;

    try
    {
        conf = new Configuration();
    }
    catch (MissingFileConfigurationException e)
    {
        fatalf("%s", e);
    }
    catch (UnknownKeyConfigurationException e)
    {
        fatalf("Couldn't read configuration at path '%s' due to error: %s", configPath, e);
    }

    ensureCorrectSysctl();
    ensureUserGroup();

    CoredumpDir coreDir;

    try
    {
        tracef("Opening CoredumpDir at path %s", conf.targetPath);
        coreDir = new CoredumpDir(conf.targetPath, true);
    }
    catch (NoCoredumpDir)
    {
        writeln("No coredumps collected yet.");
        return 0;
    }
    catch (NoPermsCoredumpDir)
    {
        writefln(
                "You don't appear to have access to the coredumpdir. Only root and members of the %s group can access it.",
                corecollector.globals.group);
        return 1;
    }

    auto coreCtl = new CoreCtl(coreDir);

    switch (options.mode)
    {
    case "list":
        coreCtl.listCoredumps();
        break;
    case "debug":
        try
        {
            coreCtl.debugCore(options.id);
        }
        catch (NoSuchCoredumpException e)
        {
            stderr.writeln(e.msg);
            return 1;
        }
        break;
    case "info":
        try
        {
            coreCtl.infoCore(options.id);
        }
        catch (NoSuchCoredumpException e)
        {
            stderr.writeln(e.msg);
            return 1;
        }
        break;
    case "dump":
        try
        {
            coreCtl.dumpCore(options.id, options.file);
        }
        catch (NoSuchCoredumpException e)
        {
            stderr.writeln(e.msg);
            return 1;
        }
        break;
    case "backtrace":
        try
        {
            coreCtl.backtraceCore(options.id);
        }
        catch (NoSuchCoredumpException e)
        {
            stderr.writeln(e.msg);
            return 1;
        }
        break;
    default:
        stderr.writefln("Unknown operation %s\n", options.mode);
        return 1;
    }

    return 0;
}

/// Setup logging for this moduke, depending on user input
private void startLogging(int debugLevel, File logFile) @safe
{
    LogLevel logLevel;

    switch (debugLevel) with (LogLevel)
    {
    case -1:
        logLevel = LogLevel.error;
        break;
    case 0:
        logLevel = LogLevel.warning;
        break;
    case 1:
        logLevel = LogLevel.info;
        break;
    case 2:
        logLevel = LogLevel.trace;
        break;
    default:
        throw new InvalidLogLevelException(format("Invalid loglevel '%s'", debugLevel));
    }

    setupLogging(cast(const) logLevel, logFile);
}

/// Make sure that `corehelper` is set as the kernel's corecollector server
void ensureCorrectSysctl() @safe
{
    string sysctlVal = readText("/proc/sys/kernel/core_pattern");

    string expectedVal = "|" ~ buildPath(corecollector.globals.libexecDir,
            "corehelper") ~ " -e=%e -x=%E -p=%P -s=%s -t=%t -u=%u -g=%g\n";

    if (sysctlVal != expectedVal)
    {
        errorf("The sysctl value for 'kernel.core_pattern' is wrong!
            As such corehelper won't receive any coredumps from the kernel.
            Expected: '%s'
            Got:      '%s'", expectedVal, sysctlVal);
    }
}

/// Make sure the user and group we want to drop privileges to exist
void ensureUserGroup()
{
    try
    {
        getUid();
    }
    catch (Exception)
    {
        errorf("Couldn't get UID for user '%s'. Please make sure it exists!",
                corecollector.globals.user);
    }

    try
    {
        getGid();
    }
    catch (Exception)
    {
        errorf("Couldn't get GID for group '%s'. Please make sure it exists!",
                corecollector.globals.group);
    }
}
