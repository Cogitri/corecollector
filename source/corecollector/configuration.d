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
version (unittest_manual)
{
    alias configPath = testConfigPath;
}
else
{
    immutable auto configPath = buildPath(confPath, "corecollector.conf");
}

class MissingFileConfigurationException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

class UnknownKeyConfigurationException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

class BadCompressionConfigurationException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

/// The different ways to compress coredumps.
enum Compression
{
    None,
    Zlib,
}

/// The `Configuration` class, which holds the configuration options
/// both corehelper and corectl need to know
class Configuration
{
    /// How the user wants to compress coredumps
    Compression compression = compression.None;
    /// The size limit for coredumps
    uint maxSize = 0;
    /// The path to place coredumps at
    string targetPath = coredumpPath;
    /// Where to log to
    string logPath = "/var/log/corecollector.log";
    /// The maximum size of the corecollector dir
    ulong maxDirSize = 0;
    /// Whether to print debugging messages or not
    bool debugEnabled;

    /// Construct a `Configuration` with the default `configPath`
    this()
    {
        this(configPath);
    }

    /// Construct a `Configuration` by supplying the `configPath`.
    this(in string configPath)
    {
        if (!configPath.exists())
        {
            throw new MissingFileConfigurationException(
                    format("Configuration path '%s' doesn't exist!", configPath));
        }
        tracef("Loading configuration from path %s.", configPath);
        auto configFile = File(configPath, "r");
        foreach (line; configFile.byLine())
        {
            const auto lineWithoutWhitespace = text(line);
            if (lineWithoutWhitespace.startsWith('#') || lineWithoutWhitespace.empty())
            {
                continue;
            }
            auto keyValueArr = lineWithoutWhitespace.split('=');

            // Allow comments after the value, e.g. 'val = something # comment'
            const auto val = strip(text(keyValueArr[1]).split('#')[0]);

            switch (toLower(strip(text(keyValueArr[0]))))
            {
            case "compression":
                switch (toLower(val))
                {
                case "zlib":
                    this.compression = Compression.Zlib;
                    break;
                case "none":
                    this.compression = Compression.None;
                    break;
                default:
                    throw new BadCompressionConfigurationException(format("Unknown compression '%s'",
                            val));
                }
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
            case "enabledebug":
                this.debugEnabled = val.to!bool;
                break;
            default:
                throw new UnknownKeyConfigurationException(format("Unknown configuration key '%s'!",
                        val));
            }
        }
    }
}

unittest
{
    import corecollector.coredump : tempFile;

    immutable auto testConfig = import("configTest01.conf");
    auto testConfigPath = tempFile();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    auto configTest = new Configuration(testConfigPath);
    assert(configTest.compression == Compression.None,
            format("Expected %s, got %s", Compression.None, configTest.compression));
    assert(configTest.maxSize == 0, format("Expected %d, got %d", 0, configTest.maxSize));
    assert(configTest.targetPath == "/Path/to/CoreCoreDumps",
            format("Expected %s, got %s", "/Path/to/CoreCoreDumps", configTest.targetPath));
    assert(configTest.logPath == "/var/log/corecollector.log",
            format("Expected %s, got %s", "/var/log/corecollector.log", configTest.logPath));
    assert(configTest.maxDirSize == 0, format("Expected %d, got %d", 0, configTest.maxDirSize));
    assert(configTest.debugEnabled);
}

unittest
{
    import corecollector.coredump : tempFile;

    immutable auto testConfig = import("configTest02.conf");
    auto testConfigPath = tempFile();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    auto configTest = new Configuration(testConfigPath);
    assert(configTest.compression == Compression.None,
            format("Expected %s, got %s", Compression.None, configTest.compression));
    assert(configTest.maxSize == 0, format("Expected %d, got %d", 0, configTest.maxSize));
    assert(configTest.targetPath == "test", format("Expected %s, got %s",
            "test", configTest.targetPath));
    assert(configTest.logPath == "/var/log/corecollector.log",
            format("Expected %s, got %s", "/var/log/corecollector.log", configTest.logPath));
    assert(configTest.maxDirSize == 0, format("Expected %d, got %d", 0, configTest.maxDirSize));
    assert(!configTest.debugEnabled);
}

unittest
{
    import corecollector.coredump : tempFile;

    auto testConfigPath = tempFile();
    assertThrown!MissingFileConfigurationException(new Configuration(testConfigPath));
}

unittest
{
    import corecollector.coredump : tempFile;

    immutable auto testConfig = "unknownKey = unknownValue";
    auto testConfigPath = tempFile();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    assertThrown!UnknownKeyConfigurationException(new Configuration(testConfigPath));
}

unittest
{
    import corecollector.coredump : tempFile;

    immutable auto testConfig = "compression = zlib";
    auto testConfigPath = tempFile();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    new Configuration(testConfigPath);
}

unittest
{
    import corecollector.coredump : tempFile;

    immutable auto testConfig = "compression = none";
    auto testConfigPath = tempFile();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    new Configuration(testConfigPath);
}

unittest
{
    import corecollector.coredump : tempFile;

    immutable auto testConfig = "compression = bad";
    auto testConfigPath = tempFile();
    auto configFile = File(testConfigPath, "w");
    scope (exit)
        remove(testConfigPath);
    configFile.write(testConfig);
    configFile.close();
    assertThrown!BadCompressionConfigurationException(new Configuration(testConfigPath));
}
