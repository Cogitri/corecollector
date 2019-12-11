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

import hunt.logging;

import std.algorithm;
import std.array;
import std.conv;
import std.datetime;
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
    SysTime timestamp;
    /// The name under which we're going to save the coredump
    private string filename;

    /// ctor to construct a `Coredump`
    this(
        in long uid,
        in long gid,
        in long pid,
        in long sig,
        in SysTime timestamp,
        in string exe,
        in string exePath,
        ) pure nothrow
        {
            this.uid = uid;
            this.pid = pid;
            this.gid = gid;
            this.sig = sig;
            this.exe = exe;
            this.exePath = exePath;
            this.timestamp = timestamp;
        }

    /// ctor to construct a `Coredump` from a JSON value
    this(in JSONValue json)
    {
        logDebugf("Constructing Coredump from JSON: %s", json);

        SysTime time = std.datetime.SysTime.fromISOString(json["timestamp"].str);
        auto core = this(
            json["uid"].integer,
            json["gid"].integer,
            json["pid"].integer,
            json["sig"].integer,
            time,
            json["exe"].str,
            json["exePath"].str,
        );

        core.filename = generateCoredumpName();
    }

    /// Generate a unique filename for a coredump.
    final string generateCoredumpName() const
    {
        auto filename =  this.exe ~ "-"
            ~ this.sig.to!string ~ "-"
            ~ this.pid.to!string ~ "-"
            ~ this.uid.to!string ~ "-"
            ~ this.gid.to!string ~ "-"
            ~ this.timestamp.toISOString;
        auto filenameFinal = filename ~ sha1UUID(filename).to!string;
        logDebugf("Generated filename for coredump %s: %s", this, filenameFinal);
        return filenameFinal;
    }

    /// Convert the `Coredump` to a `JSONValue`
    JSONValue toJson() const {
        return JSONValue([
            "exe": JSONValue(this.exe),
            "exePath": JSONValue(this.exePath),
            "filename": JSONValue(this.filename),
            "gid": JSONValue(this.gid),
            "pid": JSONValue(this.pid),
            "sig": JSONValue(this.sig),
            "timestamp": JSONValue(this.timestamp.toISOString),
            "uid": JSONValue(this.uid),
            ]);
    }
}

/// Exception thrown if there's no CoredumpDir created yet and we're not in readOnly mode.
class NoCoredumpDir : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) {
        super(msg, file, line);
    }
}

/// The `CoredumpDir` holds information about all collected `Coredump`s
class CoredumpDir {
    /// All known `Coredump`s
    Coredump[] coredumps;
    private string targetPath;
    /// The name of the configuration file in which data about the coredumps is saved.
    immutable configName = "coredumps.json";
    /// Wheter we want to do changes to the coredumpDir (corehelper) or not (corectl).
    immutable bool readOnly = false;

    private this() {
        this.coredumps = new Coredump[0];
    }

    /// ctor to directly construct a `CoredumpDir` from a JSON value containing multiple `Coredump`s.
    this(in JSONValue json) {
        logDebugf("Constructing CoredumpDir from JSON %s", json);
        foreach(x; json["coredumps"].array) {
            coredumps ~= new Coredump(x);
        }
    }

    /// ctor to construct a `CoredumpDir` from a `targetPath` in which a `coredumps.json` is contained
    this(in string targetPath, bool readOnly) {
        this.readOnly = readOnly;
        this.targetPath = targetPath;
        auto configPath = buildPath(targetPath, this.configName);
        this.ensureDir(configPath);

        logDebugf("Reading coredump file from path '%s'...", configPath);
        auto coredump_text = readText(configPath);
        logDebugf("Parsing text '%s' as JSON...", coredump_text);
        auto coredump_json = parseJSON(coredump_text);
        this(coredump_json);
    }

    /// Convert the `CoredumpDir` to a `JSONValue`
    JSONValue toJson() const {
        return JSONValue([
            "coredumps": JSONValue(this.coredumps.map!(p => p.toJson).array),
        ]);
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
        foreach (ubyte[] buffer; stdin.byChunk(new ubyte[4096]))
        {
            target.rawWrite(buffer);
        }
    }

    /// Make sure the `CoredumpDir` exists already and if it doesn't put a default, empty config in there.
    private void ensureDir(in string configPath) const {
        if (!configPath.exists) {
            if (this.readOnly) {
                throw new NoCoredumpDir("Can't create new directory in read-only mode!");
            }
            infof("Config path '%s' doesn't exist, creating it and writing default config to it...", configPath);
            if(!this.targetPath.exists) {
                this.targetPath.mkdir;
            }

            immutable auto defaultConfig = `{"coredumps": [], "targetPath": "` ~ this.targetPath ~ `"}` ~ "\n";
            this.writeConfig(defaultConfig);
        }
    }

    /// Write the configuration file of the `CoredumpDir` to the `configPath`.
    void writeConfig() const {
        auto coredumpJson = this.toJson().toString();
        writeConfig(coredumpJson);
    }

    private void writeConfig(in string JSONConfig) const {
        auto path = buildPath(targetPath, configName);
        logDebugf("Writing CoredumpDir config '%s' to path '%s'", JSONConfig, path);
        auto configFile = File(path, "w");
        auto buf = new OutBuffer();
        buf.write(JSONConfig);
        configFile.write(buf.toString());
    }

    string getTargetPath() const pure nothrow @safe {
        return this.targetPath;
    }
}

unittest {
    import std.format : format;

    auto core = new Coredump(1000, 1000, 14_948, 6, SysTime(1_574_450_085), "Xwayland", "/usr/bin/");

    auto validString =
        `{"exe":"Xwayland","exePath":"\/usr\/bin\/","filename":"",`
        ~ `"gid":1000,"pid":14948,"sig":6,"timestamp":"00010101T005605.4450085","uid":1000}`;
    auto validJSON = parseJSON(validString);
    auto generatedJSON = core.toJson();
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

    auto core1 = new Coredump(1, 1, 1, 1, SysTime(1970), "test", "/usr/bin/");
    auto core2 = new Coredump(1, 1, 1, 1, SysTime(1971), "test", "/usr/bin/");
    auto coredumpDir = new CoredumpDir();
    coredumpDir.coredumps ~= core1;
    coredumpDir.coredumps ~= core2;

    auto validString = `{"coredumps":`
        ~ `[{"exe":"test","exePath":"\/usr\/bin\/","filename":"","gid":1,"pid":1,"sig":1, "timestamp":"00010101T005328.000197","uid":1},`
        ~ `{"exe":"test","exePath":"\/usr\/bin\/","filename":"","gid":1,"pid":1,"sig":1,"timestamp":"00010101T005328.0001971","uid":1}]}`;
    auto validJSON = parseJSON(validString);
    auto generatedJSON = coredumpDir.toJson();
    assert(generatedJSON == validJSON, format("Expected %s, got %s", validJSON, generatedJSON));

    auto coredumpDirParsed = new CoredumpDir(generatedJSON);
    assert(coredumpDirParsed.targetPath == coredumpDir.targetPath,
        format("Expected %s, got %s", coredumpDir.targetPath, coredumpDirParsed.targetPath));
    assert(coredumpDirParsed.coredumps[0].exe == coredumpDir.coredumps[0].exe,
        format("Expected %s, got %s", coredumpDir.coredumps[0].exe, coredumpDirParsed.coredumps[0].exe));
    assert(coredumpDirParsed.coredumps[1].timestamp == coredumpDir.coredumps[1].timestamp,
        format("Expected %s, got %s", coredumpDir.coredumps[1].timestamp, coredumpDirParsed.coredumps[1].timestamp));
}
