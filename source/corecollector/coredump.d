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

module corecollector.coredump;

import corecollector.lz4;

import hunt.logging;
static import hunt.serialization.JsonSerializer;

import std.algorithm;
import std.conv;
import std.datetime;
import std.file;
import std.json;
import std.outbuffer;
import std.path;
import std.stdio;
import std.uuid;

/// How the coredump is compressed
enum Compression {
    None,
    Lz4,
}

/// A class describing a single coredump
class Coredump {
    /// The PID of the program which crashed
    long pid;
    /// The UID of the user running the program which crashed
    long uid;
    /// The GID of the user running the program which crashed
    long gid;
    /// The signal which the program threw when crashing
    long sig;
    /// The name of the executable that crashed
    string exe;
    /// The path of the executable
    string exePath;
    /// The UNIX timestamp at which the program crashed
    SysTime timestamp;
    /// The uncompressed size of this coredump, required for decompression
    uint uncompressedSize;
    /// The name under which we're going to save the coredump
    private string filename;
    /// How this coredump is compressed
    private Compression compression;

    /// ctor to construct a `Coredump`
    this(
        const long uid,
        const long gid,
        const long pid,
        const long sig,
        const SysTime timestamp,
        const string exe,
        const string exePath,
        const Compression compression,
        )
        {
            this.uid = uid;
            this.pid = pid;
            this.gid = gid;
            this.sig = sig;
            this.exe = exe;
            this.exePath = exePath;
            this.timestamp = timestamp;
            this.compression = compression;
        }

    /// ctor to construct a `Coredump` from a JSON value
    this(const JSONValue json)
    {
        logDebugf("Constructing Coredump from JSON: %s", json);
        auto core = this(
            json["uid"].integer,
            json["gid"].integer,
            json["pid"].integer,
            json["sig"].integer,
            SysTime(json["timestamp"].integer),
            json["exe"].str,
            json["exePath"].str,
            cast(Compression)json["compression"].integer,
        );

        core.filename = generateCoredumpName();
    }

    /// Generate a unique filename for a coredump.
    const final string generateCoredumpName()
    {
        string compression;

        switch(this.compression) with (Compression) {
            case Lz4:
                compression = ".lz4";
                break;
            default:
                break;
        }

        auto filename =  this.exe ~ "-"
            ~ this.sig.to!string ~ "-"
            ~ this.pid.to!string ~ "-"
            ~ this.uid.to!string ~ "-"
            ~ this.gid.to!string ~ "-"
            ~ this.timestamp.toISOString
            ~ compression;
        auto filenameFinal = filename ~ sha1UUID(filename).to!string;
        logDebugf("Generated filename for coredump %s: %s", this, filenameFinal);
        return filenameFinal;
    }
}

/// The `CoredumpDir` holds information about all collected `Coredump`s
class CoredumpDir {
    /// All known `Coredump`s
    Coredump[] coredumps;
    private string targetPath;
    /// The name of the configuration file in which data about the coredumps is saved.
    immutable configName = "coredumps.json";

    private this() {
        coredumps = new Coredump[0];
    }

    /// ctor to directly construct a `CoredumpDir` from a JSON value containing multiple `Coredump`s.
    this(const JSONValue json) {
        logDebugf("Constructing CoredumpDir from JSON %s", json);
        foreach(x; json["coredumps"].array) {
            coredumps ~= new Coredump(x);
        }
    }

    /// ctor to construct a `CoredumpDir` from a `targetPath` in which a `coredumps.json` is contained
    this(const string targetPath) {
        this.targetPath = targetPath;
        auto configPath = buildPath(targetPath, this.configName);
        this.ensureDir(configPath);

        logDebugf("Reading coredump file from path '%s'...", configPath);
        auto coredump_text = readText(configPath);
        logDebugf("Parsing text '%s' as JSON...", coredump_text);
        auto coredump_json = parseJSON(coredump_text);
        this(coredump_json);
    }

    /// Add a `Coredump` to the `CoredumpDir` and write it from the stdin to its target location.
    void addCoredump(Coredump coredump) {
        logDebugf("Adding coredump '%s'", coredump);
        this.coredumps ~= coredump;

        auto coredumpPath = buildPath(this.targetPath, coredump.generateCoredumpName());
        auto target = File(coredumpPath, "w");
        scope (exit)
            target.close();

        logDebugf("Writing coredump to path '%s'", coredumpPath);

        switch(coredump.compression) with (Compression) {
            case None:
                foreach (ubyte[] buffer; stdin.byChunk(new ubyte[4096])) {
                    target.rawWrite(buffer);
                }
                break;
            case Lz4:
                ubyte[] uncompressedData;
                foreach (ubyte[] buffer; stdin.byChunk(new ubyte[4096])) {
                    uncompressedData ~= buffer;
                }
                coredump.uncompressedSize = cast(int)uncompressedData.length * cast(int)ubyte.sizeof;
                const auto compressedData = compressData(uncompressedData);
                target.rawWrite(compressedData);
                break;
            default:
                assert(0);
        }
    }

    /// Make sure the `CoredumpDir` exists already and if it doesn't put a default, empty config in there.
    private void ensureDir(const string configPath) {
        if (!configPath.exists) {
            infof("Config path '%s' doesn't exist, creating it and writing default config to it...", configPath);
            if(!this.targetPath.exists) {
                this.targetPath.mkdir;
            }

            immutable auto defaultConfig = `{"coredumps": [], "targetPath": "` ~ this.targetPath ~ `"}\n`;
            this.writeConfig(defaultConfig);
        }
    }

    /// Write the configuration file of the `CoredumpDir` to the `configPath`.
    void writeConfig() {
        auto coredump_json = hunt.serialization.JsonSerializer.toJson(this).toString();
        writeConfig(coredump_json);
    }

    private void writeConfig(const string JSONConfig) {
        auto path = buildPath(targetPath, configName);
        logDebugf("Writing CoredumpDir config '%s' to path '%s'", JSONConfig, path);
        auto configFile = File(path, "w");
        auto buf = new OutBuffer();
        buf.write(JSONConfig);
        configFile.write(buf.toString());
    }

    const string getTargetPath() {
        return this.targetPath;
    }
}

unittest {
    import std.format : format;

    auto core = new Coredump(1000, 1000, 14_948, 6, SysTime(1_574_450_085), "Xwayland", "/usr/bin/", Compression.None);

    auto validString =
        `{"compression":0,"exe":"Xwayland","exePath":"\/usr\/bin\/","filename":[],`
        ~ `"gid":1000,"pid":14948,"sig":6,"timestamp":1574450085,"uid":1000}`;
    auto validJSON = parseJSON(validString);
    auto generatedJSON = hunt.serialization.JsonSerializer.toJson(core);
    assert(generatedJSON == validJSON, format("Expected %s, got %s", validJSON, generatedJSON));

    auto parsedCore = new Coredump(generatedJSON);
    assert(parsedCore.exe == core.exe);
    assert(parsedCore.uid == core.uid);
    assert(parsedCore.pid == core.pid);
    assert(parsedCore.sig == core.sig);
    assert(parsedCore.timestamp == core.timestamp);
    assert(parsedCore.gid == core.gid);
}

unittest {
    import std.format : format;

    auto core1 = new Coredump(1, 1, 1, 1, SysTime(1970), "test", "/usr/bin/", Compression.None);
    auto core2 = new Coredump(1, 1, 1, 1, SysTime(1971), "test", "/usr/bin/", Compression.None);
    auto coredumpDir = new CoredumpDir();
    coredumpDir.coredumps ~= core1;
    coredumpDir.coredumps ~= core2;

    auto validString = `{"configName":"coredumps.json","coredumps":`
        ~ `[{"compression":0,"exe":"test","exePath":"\/usr\/bin\/","filename":[],"gid":1,"pid":1,"sig":1, "timestamp":1970,"uid":1},`
        ~ `{"compression":0,"exe":"test","exePath":"\/usr\/bin\/","filename":[],"gid":1,"pid":1,"sig":1,"timestamp":1971,"uid":1}],`
        ~ `"targetPath":[]}`;
    auto validJSON = parseJSON(validString);
    auto generatedJSON = hunt.serialization.JsonSerializer.toJson(coredumpDir);
    assert(generatedJSON == validJSON, format("Expected %s, got %s", validJSON, generatedJSON));

    auto coredumpDirParsed = new CoredumpDir(generatedJSON);
    assert(coredumpDirParsed.targetPath == coredumpDir.targetPath,
        format("Expected %s, got %s", coredumpDir.targetPath, coredumpDirParsed.targetPath));
    assert(coredumpDirParsed.coredumps[0].exe == coredumpDir.coredumps[0].exe,
        format("Expected %s, got %s", coredumpDir.coredumps[0].exe, coredumpDirParsed.coredumps[0].exe));
    assert(coredumpDirParsed.coredumps[1].timestamp == coredumpDir.coredumps[1].timestamp,
        format("Expected %s, got %s", coredumpDir.coredumps[1].timestamp, coredumpDirParsed.coredumps[1].timestamp));
}
