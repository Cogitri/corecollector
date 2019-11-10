module corecollector.corecollector;

import corectl.options;

import hunt.util.Argument;


import std.algorithm;
import std.algorithm.mutation : copy;
import std.array;
import std.file;
import std.path;
import std.stdio : write, writef, writeln, stderr, File;

private class Corecollector {
    string targetPath;
    string[] availableDumps;

    this(string targetPath) {
        this.targetPath = targetPath;
        this.availableDumps = dirEntries(this.targetPath, SpanMode.shallow)
            .filter!(a => a.isFile)
            .map!(a => baseName(a.name))
            .array;
    }

    int list_coredumps() {
        writeln("stub");
        return 0;
    }
}

private immutable usage = usageString!Options("corecollector");
private immutable help = helpString!Options;

int main(string[] args)
{
    Options options;

    try
    {
        options = parseArgs!Options(args[1 .. $]);
    }
    catch (ArgParseError e)
    {
        stderr.writeln(e.msg);
        stderr.write(usage);
        return 1;
    }
    catch (ArgParseHelp e)
    {
        // Help was requested
        stderr.writeln(usage);
        stderr.write(help);
        return 0;
    }

    switch (options.mode) {
        case "list":
            writeln("stub");
            break;
        default:
            stderr.writef("Unknown operation %s\n", options.mode);
            break;
    }

    return 0;
}
