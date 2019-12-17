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
static import corecollector.globals;
import corecollector.logging;
import corehelper.corehelper;
import corehelper.options;

import std.conv : to;
import std.experimental.logger;
import std.file;
import std.path;
import std.stdio : writeln, File;

int main(string[] args)
{
    // Use /dev/null here, since we do log calls in Configuration's constructor
    // Once we have constructed the Configuration we re-run this with the proper log
    // path
    setupLogging(LogLevel.trace, File("/dev/null", "w"));

    Configuration conf;

    try
    {
        conf = new Configuration();
    }
    catch (ConfigurationException e)
    {
        errorf("Couldn't read configuration at path %s due to error %s\n", configPath, e);
        return 1;
    }

    setupLogging(LogLevel.trace, File(conf.logPath, "w"));

    const auto options = new Options(args);

    if (options.showHelp)
    {
        writeln(helpText);
    }
    else if (options.showVersion)
    {
        writeln(corecollector.globals.corecollectorVersion);
    }

    //setupLogging(LogLevel.trace, File(conf.logPath, "w"));
    info("Starting corehelper to collect coredump.");

    auto coreHelper = new CoreHelper(cast(immutable Configuration) conf, options);

    return coreHelper.writeCoredump();
}
