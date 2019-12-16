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

module corehelper.main;

import corecollector.configuration;
import corecollector.coredump;
import corecollector.logging;
import corehelper.corehelper;
import corehelper.options;

import hunt.logging;
import hunt.util.Argument;
import hunt.Exceptions : ConfigurationException;

import std.conv : to;
import std.file;
import std.path;

private immutable usage = usageString!Options("corehelper");
private immutable help = helpString!Option;

int main(string[] args)
{
    setupLogging(LogLevel.LOG_DEBUG);
    // We ignore this exception - the kernel should always pass us the correct args.
    immutable auto options = parseArgs!Options(args[1 .. $]);

    Configuration conf;

    logDebugf("Loading configuration from path '%s'...", configPath);
    try
    {
        conf = new Configuration(configPath);
    }
    catch (ConfigurationException e)
    {
        errorf("Couldn't read configuration at path %s due to error %s\n", configPath, e);
        return 1;
    }

    auto coreHelper = new CoreHelper(cast(immutable Configuration) conf, options);

    return coreHelper.writeCoredump();
}
