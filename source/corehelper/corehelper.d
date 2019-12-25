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
static import corecollector.globals;
import corehelper.options;

import core.sys.posix.unistd;
import std.exception;
import std.experimental.logger;
import std.file;
import std.format;
import std.path;
import std.stdio;

/// `CoreHelper` is the main class of the `corehelper` module holding most
/// of its functionality
class CoreHelper
{
    /// The coredump we're currently handling
    Coredump coredump;
    /// The configuration we loaded from the filesystem
    const Configuration config;
    /// The options that the user (kernel) has supplied on the CLI
    const Options opt;

    /// ctor for generating a `CoreHelper` with the configuration
    /// and command line arguments.
    this(in Configuration config, in Options opt) @safe
    {
        this.config = config;
        this.opt = opt;
        this.coredump = this.opt.toCoredump;
    }

    /// Simple check to see if we can write a file to the coredumpDir.
    /// Do note that as of now this just creates a temp file which is later
    /// removed to check this instead of calling stat() for simplicity reasons.
    private bool ensureDirWriteable()
    {
        try
        {
            auto tempFile = buildPath(corecollector.globals.coredumpPath, deleteme);
            File(tempFile, "w");
            scope (exit)
                remove(tempFile);
            return true;
        }
        catch (FileException e)
        {
            return false;
        }
    }

    /// Drop privileges to not run as root when we don't have to.
    private void dropPrivileges(in uint corecollectorUid, in uint corecollectorGid)
    {
        if (getuid() == 0)
        {
            errnoEnforce(setgid(corecollectorGid) == 0,
                    format("Failed to drop group to %d", corecollectorGid));
            errnoEnforce(setuid(corecollectorUid) == 0,
                    format("Failed to drop user to %d", corecollectorUid));
        }
    }

    /// Write the coredump to the `CoredumpDir`
    int writeCoredump()
    {
        auto coredumpDir = new CoredumpDir(this.config.targetPath, false, this.config.maxDirSize);

        auto corecollectorUid = getUid();
        auto corecollectorGid = getGid();
        dropPrivileges(corecollectorUid, corecollectorGid);
        enforce(ensureDirWriteable(),
                format("Directory %s isn't writable for user %s! Please make sure it is writeable.",
                    corecollector.globals.coredumpPath, corecollector.globals.user));

        try
        {
            coredumpDir.addCoredump(this.coredump);
            coredumpDir.rotateDir();
            coredumpDir.writeConfig();
            return 0;
        }
        catch (ErrnoException e)
        {
            errorf("Couldn't save coredump due to error %s\n", e);
            return 1;
        }
    }
}
