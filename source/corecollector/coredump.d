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

static import hunt.serialization.JsonSerializer;

import std.conv;
import std.file;
import std.json;
import std.outbuffer;
import std.path;
import std.stdio;
import std.uuid;

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
    long timestamp;
    /// The name under which we're going to save the coredump
    private string filename;

    /// ctor to construct a `Coredump`
    this(long uid, long gid, long pid, long sig, long timestamp, string exe, string exePath) {
        this.uid = uid;
        this.pid = pid;
        this.gid = gid;
        this.sig = sig;
        this.exe = exe;
        this.exePath = exePath;
        this.timestamp = timestamp;
    }

    /// ctor to construct a `Coredump` from a JSON value
    this(JSONValue json) {
        auto core = this(
            json["uid"].integer,
            json["gid"].integer,
            json["pid"].integer,
            json["sig"].integer,
            json["timestamp"].integer,
            json["exe"].str,
            json["exePath"].str,
        );

        core.filename = generateCoredumpName();
    }

    /// Generate a unique filename for a coredump.
    final string generateCoredumpName() {
        auto filename =  this.exePath
            ~ this.exe ~ "-"
            ~ this.sig.to!string ~ "-"
            ~ this.pid.to!string ~ "-"
            ~ this.uid.to!string ~ "-"
            ~ this.gid.to!string ~ "-"
            ~ this.timestamp.to!string;
        return filename ~ sha1UUID(filename).to!string;
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
    this(JSONValue json) {
        foreach(x; json["coredumps"].array) {
            coredumps ~= new Coredump(x);
        }
    }

    /// ctor to construct a `CoredumpDir` from a `targetPath` in which a `coredumps.json` is contained
    this(string targetPath) {
        this.targetPath = targetPath;
        auto configPath = buildPath(targetPath, this.configName);
        this.ensureDir(configPath);

        auto coredump_text = readText(configPath);
        auto coredump_json = parseJSON(coredump_text);
        this(coredump_json);
    }

    /// Add a `Coredump` to the `CoredumpDir` and write it from the stdin to its target location.
    void addCoredump(Coredump coredump) {
        this.coredumps ~= coredump;

        auto coredumpPath = buildPath(this.targetPath, coredump.generateCoredumpName());
        auto target = File(coredumpPath, "w");
        scope (exit)
            target.close();

        foreach (ubyte[] buffer; stdin.byChunk(new ubyte[4096]))
        {
            target.rawWrite(buffer);
        }
    }

    /// Make sure the `CoredumpDir` exists already and if it doesn't put a default, empty config in there.
    private void ensureDir(string configPath) {
        if (!configPath.exists) {
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

    private void writeConfig(string JSONConfig) {
        auto configFile = File(buildPath(targetPath, configName), "w");
        auto buf = new OutBuffer();
        buf.write(JSONConfig);
        configFile.write(buf.toString());
    }
}

unittest {
    import std.format : format;

    auto core = new Coredump(1000, 1000, 14_948, 6, 1_574_450_085, "Xwayland", "/usr/bin/");

    auto validString =
        `{"exe":"Xwayland","exePath":"\/usr\/bin\/","filename":[],"gid":1000,"pid":14948,"sig":6,"timestamp":1574450085,"uid":1000}`;
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

    auto core1 = new Coredump(1, 1, 1, 1, 1970, "test", "/usr/bin/");
    auto core2 = new Coredump(1, 1, 1, 1, 1971, "test", "/usr/bin/");
    auto coredumpDir = new CoredumpDir();
    coredumpDir.coredumps ~= core1;
    coredumpDir.coredumps ~= core2;

    auto validString = `{"configName":"coredumps.json","coredumps":`
        ~ `[{"exe":"test","exePath":"\/usr\/bin\/","filename":[],"gid":1,"pid":1,"sig":1, "timestamp":1970,"uid":1},`
        ~ `{"exe":"test","exePath":"\/usr\/bin\/","filename":[],"gid":1,"pid":1,"sig":1,"timestamp":1971,"uid":1}],"targetPath":[]}`;
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
