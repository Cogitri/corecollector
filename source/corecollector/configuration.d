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

module corecollector.configuration;

import corecollector.globals;

import std.algorithm;
import std.conv;
import std.exception;
import std.experimental.logger;
import std.file;
import std.path;
import std.stdio;
import std.string;

/// Path to where the configuration file is located at
immutable configPath = buildPath(confPath, "corecollector.conf");

class ConfigurationException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

/// The `Configuration` class, which holds the configuration options
/// both corehelper and corectl need to know
class Configuration
{
    /// How the user wants to compress coredumps
    string compression = "none";
    /// The size limit for coredumps
    uint maxSize = 0;
    /// The path to place coredumps at
    string targetPath = coredumpPath;
    /// Where to log to
    string logPath = "/var/log/corecollector.log";

    /// Construct a `Configuration` by supplying the `configPath`. You might want
    /// to supply the `configPath` which is defined in this module.
    this()
    {
        tracef("Loading configuration from path %s.", configPath);
        auto configFile = File(configPath, "r");
        foreach (line; configFile.byLine())
        {
            const auto lineWithoutWhitespace = toLower(text(line));
            if (lineWithoutWhitespace.startsWith('#') || lineWithoutWhitespace.empty())
            {
                continue;
            }
            auto keyValueArr = lineWithoutWhitespace.split('=');
            switch (strip(text(keyValueArr[0])))
            {
            case "compression":
                this.compression = strip(text(keyValueArr[1]));
                break;
            case "maxsize":
                this.maxSize = strip(text(keyValueArr[1])).to!uint;
                break;
            case "targetpath":
                this.targetPath = strip(text(keyValueArr[1]));
                break;
            case "logpath":
                this.logPath = strip(text(keyValueArr[1]));
                break;
            default:
                errorf("Unknown configuration key '%s'!", keyValueArr[0]);
                assert(0);
            }
        }
        tracef("Configuration: %s", this);
    }
}
