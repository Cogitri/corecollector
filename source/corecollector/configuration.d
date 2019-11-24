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

import hunt.util.Configuration;

import std.algorithm;
import std.file;
import std.path;
import std.stdio;

/// Path to where the configuration file is located at
immutable configPath = buildPath("@CONF_PATH@", "corecollector.conf");

/// The `Configuration` class, which holds the configuration options
/// both corehelper and corectl need to know
class Configuration
{
    /// How the user wants to compress coredumps
    @Value("compression")
    string compression = "none";

    /// The size limit for coredumps
    @Value("maxSize")
    uint maxSize = 0;

    /// The path to place coredumps at
    @Value("targetPath")
    string targetPath = "@COREDUMP_PATH@";

    /// Empty constructor used with hunt's `ConfigBuilder`
    private this() { }

    /// Construct a `Configuration` by supplying the `configPath`. You might want
    /// to supply the `configPath` which is defined in this module.
    this(string configPath) {
        auto path = relativePath(configPath, std.file.thisExePath.dirName);
        ConfigBuilder confManager = new ConfigBuilder(path);
        auto conf = confManager.build!Configuration();
        compression = move(conf.compression);
        maxSize = conf.maxSize;
        targetPath = move(conf.targetPath);
    }
}
