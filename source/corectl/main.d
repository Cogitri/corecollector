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

int main(string[] args)
{

    auto options = new Options(args);
    if (options.showHelp) {
        writeln(helpText);
        return 0;
    } else if (options.showVersion) {
        writeln("@VERSION@");
        return 0;
    }
    startLogging(options.debugLevel);

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
        coreDir = new CoredumpDir(conf.targetPath, true);
    } catch (NoCoredumpDir) {
        writeln("No coredumps collected yet.");
        return 0;
    }

    auto coreCtl = new CoreCtl(cast(immutable) coreDir);

    switch (options.mode) {
        case "list":
            coreCtl.listCoredumps();
            break;
        case "debug":
            coreCtl.debugCore(options.id);
            break;
        case "info":
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
private void startLogging(int debugLevel) {
    LogLevel logLevel;

    switch(debugLevel) with (LogLevel) {
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
