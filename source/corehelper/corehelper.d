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

module corehelper.corehelper;

import corecollector.configuration;
import corecollector.coredump;
import corehelper.options;

import hunt.logging;

import std.exception : ErrnoException;

/// `CoreHelper` is the main class of the `corehelper` module holding most
/// of its functionality
class CoreHelper {
    /// The coredump we're currently handling
    Coredump coredump;
    /// The configuration we loaded from the filesystem
    immutable Configuration config;
    /// The options that the user (kernel) has supplied on the CLI
    Options opt;

    /// ctor for generating a `CoreHelper` with the configuration
    /// and command line arguments.
    this(immutable Configuration config, immutable Options opt) {
        this.config = config;
        this.opt = opt;
        this.coredump = this.opt.toCoredump;
    }

    /// Write the coredump to the `CoredumpDir`
    int writeCoredump() {
        auto coredumpDir = new CoredumpDir(this.config.targetPath);
        try {
            coredumpDir.addCoredump(this.coredump);
            coredumpDir.writeConfig();
            return 0;
        } catch (ErrnoException e) {
            errorf("Couldn't save coredump due to error %s\n", e);
            return 1;
        }
    }
}
