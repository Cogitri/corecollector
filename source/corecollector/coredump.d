module corecollector.coredump;

static import hunt.serialization.JsonSerializer;

import std.conv;
import std.file;
import std.json;
import std.path;
import std.stdio;
import std.uuid;

immutable configName = "coredumps.json";

class Coredump {
    ulong pid;
    ulong uid;
    ulong gid;
    ulong sig;
    string exe;
    string timestamp;
    string filename;

    this(ulong uid, ulong gid, ulong pid, ulong sig, string exe, string timestamp) {
        this.uid = uid;
        this.pid = pid;
        this.gid = gid;
        this.sig = sig;
        this.exe = exe;
        this.timestamp = timestamp;
    }

    this(JSONValue json) {
        auto core = this(
            json["uid"].uinteger,
            json["gid"].uinteger,
            json["pid"].uinteger,
            json["sig"].uinteger,
            json["exe"].str,
            json["timestamp"].str
        );

        core.filename = generateCoredumpName();
    }

    final string generateCoredumpName() {
        auto filename = this.exe ~ "-"
            ~ this.sig.to!string ~ "-"
            ~ this.pid.to!string ~ "-"
            ~ this.uid.to!string ~ "-"
            ~ this.gid.to!string ~ "-"
            ~ this.timestamp;
        return filename ~ sha1UUID(filename).to!string;
    }
}

class CoredumpDir {
    private Coredump[] coredumps;
    private string targetPath;

    this() {
        coredumps = new Coredump[0];
    }

    this(JSONValue json) {
        foreach(x; json["coredumps"].array) {
            coredumps ~= new Coredump(x);
        }
    }

    this(string targetPath) {
        this.targetPath = targetPath;
        auto configPath = buildPath(targetPath, configName);
        this.ensureDir(configPath);

        auto coredump_text = readText(configPath);
        auto coredump_json = parseJSON(coredump_text);
        this(coredump_json);
    }

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

    private void ensureDir(string configPath) {
        if (!configPath.exists) {
            if(!this.targetPath.exists) {
                this.targetPath.mkdir;
            }

            immutable auto defaultConfig = `{"coredumps": [], "targetPath": "` ~ this.targetPath ~ `"`;
            this.writeConfig(defaultConfig);
        }
    }

    void writeConfig() {
        auto coredump_json = hunt.serialization.JsonSerializer.toJson(this).toString();
        writeConfig(coredump_json);
    }

    private void writeConfig(string JSONConfig) {
        auto coredump_json = hunt.serialization.JsonSerializer.toJson(this).toString();
        auto configFile = File(buildPath(targetPath, configName), "w");
        configFile.write(coredump_json);
    }
}

unittest {
    auto core = new Coredump(1, 1, 1, 1, "test", "1970");

    string validString = `{"exe":"test","gid":1,"pid":1,"sig":1,"timestamp":"1970","uid":1}`;
    auto generatedJSON = hunt.serialization.JsonSerializer.toJson(core);
    assert(generatedJSON == parseJSON(validString));

    auto parsedCore = new Coredump(generatedJSON);
    assert(parsedCore.exe == core.exe);
    assert(parsedCore.uid == core.uid);
    assert(parsedCore.pid == core.pid);
    assert(parsedCore.sig == core.sig);
    assert(parsedCore.timestamp == core.timestamp);
    assert(parsedCore.gid == core.gid);
}

unittest {
    auto core1 = new Coredump(1, 1, 1, 1, "test", "1970");
    auto core2 = new Coredump(1, 1, 1, 1, "test", "1971");
    auto coredumpDir = new CoredumpDir();
    coredumpDir.coredumps ~= core1;
    coredumpDir.coredumps ~= core2;

    auto validString = `{"coredumps":[{"exe":"test","gid":1,"pid":1,"sig":1,"timestamp":"1970","uid":1},{"exe":"test","gid":1,"pid":1,"sig":1,"timestamp":"1971","uid":1}],"targetPath":[]}`;
    auto generatedJSON = hunt.serialization.JsonSerializer.toJson(coredumpDir);
    assert(generatedJSON == parseJSON(validString));

    auto coredumpDirParsed = new CoredumpDir(generatedJSON);
    assert(coredumpDirParsed.targetPath == coredumpDir.targetPath);
    assert(coredumpDirParsed.coredumps[0].exe == coredumpDir.coredumps[0].exe);
    assert(coredumpDirParsed.coredumps[1].timestamp == coredumpDir.coredumps[1].timestamp);
}
