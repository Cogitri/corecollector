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
