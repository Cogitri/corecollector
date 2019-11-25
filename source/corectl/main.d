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

private immutable usage = usageString!Options("corectl");
private immutable help = helpString!Options;

int main(string[] args)
{
    Options options;

    try
    {
        options = parseArgs!Options(args[1 .. $]);
    }
    catch (ArgParseError e)
    {
        stderr.writeln(e.msg);
        stderr.write(usage);
        return 1;
    }
    catch (ArgParseHelp e)
    {
        // Help was requested
        stderr.writeln(usage);
        stderr.write(help);
        return 0;
    }

    LogLevel logLevel;

    switch(options.debugLevel) with (LogLevel) {
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
            assert(0, format("Invalid loglevel '%s'", options.debugLevel));
    }

    setupLogging(logLevel);

    Configuration conf;

    try {
        logDebugf("Loading configuration from path %s", configPath);
        conf = new Configuration(configPath);
    } catch (ConfigurationException e) {
        criticalf("Couldn't read configuration at path %s due to error %s\n", configPath, e);
        return 1;
    }

    CoredumpDir coreDir;

    try {
        logDebugf("Opening CoredumpDir at path %s", conf.targetPath);
        coreDir = new CoredumpDir(conf.targetPath);
    } catch (ErrnoException e) with (core.stdc.errno) {
        switch(e.errno) {
            case EACCES:
                writeln("No coredumps collected yet.");
                return 0;
            default:
                throw e;
        }
    }

    auto coreCtl = new CoreCtl(coreDir);

    switch (options.mode) {
        case "list":
            coreCtl.listCoredumps();
            break;
        default:
            criticalf("Unknown operation %s\n", options.mode);
            break;
    }

    return 0;
}
