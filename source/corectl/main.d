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

import hunt.Exceptions : ConfigurationException;
import hunt.logging;
import hunt.util.Argument;

static import core.stdc.errno;

import std.algorithm;
import std.algorithm.mutation : copy;
import std.array;
import std.exception;
import std.file;
import std.format;
import std.path;
import std.stdio;

int main(string[] args)
{

    auto options = new Options(args);
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
    startLogging(options.debugLevel);

    Configuration conf;

    try
    {
        logDebugf("Loading configuration from path %s", configPath);
        conf = new Configuration(configPath);
    }
    catch (ConfigurationException e)
    {
        criticalf("Couldn't read configuration at path %s due to error %s\n", configPath, e);
        return 1;
    }

    ensureCorrectSysctl();
    ensureUserGroup();

    CoredumpDir coreDir;

    try
    {
        logDebugf("Opening CoredumpDir at path %s", conf.targetPath);
        coreDir = new CoredumpDir(conf.targetPath, true);
    }
    catch (NoCoredumpDir)
    {
        writeln("No coredumps collected yet.");
        return 0;
    }

    auto coreCtl = new CoreCtl(cast(immutable) coreDir);

    switch (options.mode)
    {
    case "list":
        coreCtl.listCoredumps();
        break;
    case "debug":
        coreCtl.debugCore(options.id);
        break;
    case "info":
        coreCtl.infoCore(options.id);
        break;
    case "dump":
        coreCtl.dumpCore(options.id, options.file);
        break;
    default:
        criticalf("Unknown operation %s\n", options.mode);
        return 1;
    }

    return 0;
}

/// Setup logging for this moduke, depending on user input
private void startLogging(int debugLevel)
{
    LogLevel logLevel;

    switch (debugLevel) with (LogLevel)
    {
    case -1:
        logLevel = LOG_ERROR;
        break;
    case 0:
        logLevel = LOG_WARNING;
        break;
    case 1:
        logLevel = LOG_INFO;
        break;
    case 2:
        logLevel = LOG_DEBUG;
        break;
    default:
        assert(0, format("Invalid loglevel '%s'", debugLevel));
    }

    setupLogging(logLevel);
}

/// Make sure that `corehelper` is set as the kernel's corecollector server
void ensureCorrectSysctl()
{
    string sysctlVal = readText("/proc/sys/kernel/core_pattern");

    string expectedVal = "|" ~ buildPath(corecollector.globals.libexecDir,
            "corehelper") ~ " -e=%e -E=%E -p=%P -s=%s -t=%t -u=%u -g=%g\n";

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
