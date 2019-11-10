module corecollector.coredump;

static import hunt.serialization.JsonSerializer;

//import std.cov: to;
import std.file;
import std.json;
import std.path;
import std.stdio;

immutable configName = "coredumps.json";

class Coredump {
    ulong pid;
    ulong uid;
    ulong gid;
    ulong sig;
    string exe;
    string timestamp;

    this(ulong uid, ulong gid, ulong pid, ulong sig, string exe, string timestamp) {
        this.uid = uid;
        this.pid = pid;
        this.gid = gid;
        this.sig = sig;
        this.exe = exe;
        this.timestamp = timestamp;
    }

    this(JSONValue json) {
        this(
            json["uid"].uinteger,
            json["gid"].uinteger,
            json["pid"].uinteger,
            json["sig"].uinteger,
            json["exe"].str,
            json["timestamp"].str
        );
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
        auto coredump_text = readText(buildPath(targetPath, configName));
        auto coredump_json = parseJSON(coredump_text);
        this(coredump_json);
    }

    @safe ~this() {
        auto coredump_json = hunt.serialization.JsonSerializer.toJson(this).toString();
        auto configFile = File(buildPath(targetPath, configName), "w");
        configFile.write(coredump_json);
    }

    void addCoredump(Coredump coredump) {
        this.coredumps ~= coredump;

        auto target = File(this.targetPath, "w");
        scope (exit)
            target.close();

        foreach (ubyte[] buffer; stdin.byChunk(new ubyte[4096]))
        {
            target.rawWrite(buffer);
        }
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
