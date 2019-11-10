module corehelper.main;

import corecollector.configuration;
import corecollector.coredump;
import corehelper.corehelper;
import corehelper.options;

import hunt.util.Argument;
import hunt.Exceptions : ConfigurationException;

import std.conv : to;
import std.file;
import std.path;
import std.stdio : stderr, stdin, File, writef;

private immutable usage = usageString!Options("corehelper");
private immutable help = helpString!Option;

int main(string[] args)
{
    // We ignore this exception - the kernel should always pass us the correct args.
    immutable auto options = parseArgs!Options(args[1 .. $]);

    Configuration conf;

    try {
        conf = new Configuration(configPath);
    } catch (ConfigurationException e) {
        stderr.writef("Couldn't read configuration at path %s due to error %s\n", configPath, e);
        return 1;
    }

    auto coreHelper = new CoreHelper(conf, options);

    return coreHelper.writeCoredump();
}
