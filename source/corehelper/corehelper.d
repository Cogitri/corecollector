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
            coredumpDir.writeConfig();
            return 0;
        } catch (ErrnoException e) {
            stderr.writef("Couldn't save coredump due to error %s\n", e);
            return 1;
        }
    }
}
