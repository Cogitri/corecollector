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
immutable auto configPath = buildPath(confPath, "corecollector.conf");

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
    /// The maximum size of the corecollector dir
    ulong maxDirSize = 0;

    /// Construct a `Configuration` with the default `configPath`
    this()
    {
        this(configPath);
    }

    /// Construct a `Configuration` by supplying the `configPath`.
    this(in string configPath)
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

            // Allow comments after the value, e.g. 'val = something # comment'
            const auto val = strip(text(keyValueArr[1]).split('#')[0]);

            switch (strip(text(keyValueArr[0])))
            {
            case "compression":
                this.compression = val;
                break;
            case "maxsize":
                this.maxSize = val.to!uint;
                break;
            case "targetpath":
                this.targetPath = val;
                break;
            case "logpath":
                this.logPath = val;
                break;
            case "maxdirsize":
                this.maxDirSize = val.to!ulong;
                break;
            default:
                enforce(0, "Unknown configuration key '%s'!", val);
            }
        }
    }
}

unittest
{
    immutable auto testConfig = import("configTest01.conf");
    auto testConfigPath = deleteme();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    auto configTest = new Configuration(testConfigPath);
    assert(configTest.compression == "none", format("Expected %s, got %s",
            "none", configTest.compression));
    assert(configTest.maxSize == 0, format("Expected %d, got %d", 0, configTest.maxSize));
    assert(configTest.targetPath == "test", format("Expected %s, got %s",
            "test", configTest.targetPath));
    assert(configTest.logPath == "/var/log/corecollector.log",
            format("Expected %s, got %s", "/var/log/corecollector.log", configTest.logPath));
    assert(configTest.maxDirSize == 0, format("Expected %d, got %d", 0, configTest.maxDirSize));
}

unittest
{
    immutable auto testConfig = import("configTest02.conf");
    auto testConfigPath = deleteme();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    auto configTest = new Configuration(testConfigPath);
    assert(configTest.compression == "none", format("Expected %s, got %s",
            "none", configTest.compression));
    assert(configTest.maxSize == 0, format("Expected %d, got %d", 0, configTest.maxSize));
    assert(configTest.targetPath == "test", format("Expected %s, got %s",
            "test", configTest.targetPath));
    assert(configTest.logPath == "/var/log/corecollector.log",
            format("Expected %s, got %s", "/var/log/corecollector.log", configTest.logPath));
    assert(configTest.maxDirSize == 0, format("Expected %d, got %d", 0, configTest.maxDirSize));
}
