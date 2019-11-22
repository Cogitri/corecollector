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
import corectl.options;

import hunt.Exceptions : ConfigurationException;
import hunt.util.Argument;

import std.algorithm;
import std.algorithm.mutation : copy;
import std.array;
import std.file;
import std.path;
import std.stdio;

private class CoreCtl {
    CoredumpDir coredumpDir;

    this(CoredumpDir coreDir) {
        this.coredumpDir = coreDir;
    }

    void listCoredumps() {
        writeln("Executable\tSignal\tUID\tGID\tPID\tTimestamp");
        foreach(x; this.coredumpDir.coredumps)
        {
            writef(
                "%s\t\t%d\t%d\t%d\t%d\t%s\t\n",
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

private immutable usage = usageString!Options("corecollector");
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

    Configuration conf;

    try {
        conf = new Configuration(configPath);
    } catch (ConfigurationException e) {
        stderr.writef("Couldn't read configuration at path %s due to error %s\n", configPath, e);
        return 1;
    }

    auto coreDir = new CoredumpDir(conf.targetPath);

    auto coreCtl = new CoreCtl(coreDir);

    switch (options.mode) {
        case "list":
            coreCtl.listCoredumps();
            break;
        default:
            stderr.writef("Unknown operation %s\n", options.mode);
            break;
    }

    return 0;
}
