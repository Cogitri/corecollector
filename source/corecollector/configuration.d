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

immutable configPath = buildPath("@CONF_PATH@", "corecollector.conf");

class Configuration
{
    @Value("compression")
    string compression = "none";

    @Value("maxSize")
    uint maxSize = 0;

    @Value("targetPath")
    string targetPath = "@COREDUMP_PATH@";

    this() { }

    this(string configPath) {
        auto path = relativePath(configPath, std.file.thisExePath.dirName);
        ConfigBuilder confManager = new ConfigBuilder(path);
        auto conf = confManager.build!Configuration();
        compression = move(conf.compression);
        maxSize = conf.maxSize;
        targetPath = move(conf.targetPath);
    }
}
