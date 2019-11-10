module corehelper.corehelper;

import corecollector.configuration;
import corecollector.coredump;
import corehelper.options;

import std.exception : ErrnoException;
import std.stdio : stderr, writef;

class CoreHelper {
    Coredump coredump;
    Configuration config;
    Options opt;

    this(Configuration config, immutable Options opt) {
        this.config = config;
        this.opt = opt;
        this.coredump = this.opt.toCoredump;
    }

    int writeCoredump() {
        auto coredumpDir = new CoredumpDir(this.config.targetPath);
        try {
            coredumpDir.addCoredump(this.coredump);
            return 0;
        } catch (ErrnoException e) {
            stderr.writef("Couldn't save coredump due to error %s\n", e);
            return 1;
        }
    }
}
