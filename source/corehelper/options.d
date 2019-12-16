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

module corehelper.options;

import corecollector.coredump;

import hunt.util.Argument;

import std.array;
import std.datetime;

/// CLI arguments passed to this binary, usually by the kernel
struct Options
{
    /// If a user does want to run this binary this will print the help
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    /// The string of the exe
    @Option("exe-name", "e")
    @Help("The name of the executable whose curedump you're sending me.")
    string exe;

    /// The path of the exe
    @Option("exe-path", "E")
    @Help("The path of the executable whose coredump you're sending me,")
    string exePath;

    /// The pid of the exe
    @Option("pid", "p")
    @Help("The PID of the executable whose coredump you're sending me.")
    long pid;

    /// The uid of the exe
    @Option("uid", "u")
    @Help("The UID of the user who executed the executable whose coredump you're sending me.")
    long uid;

    /// The gid of the exe
    @Option("gid", "g")
    @Help("The GID of the user the executable whose coredump you're sending me.")
    long gid;

    /// The signal of the exe
    @Option("signal", "s")
    @Help("The signal the executable whose coredump you're sending me threw when crashing.")
    long signal;

    /// The timestamp of the exe crashing
    @Option("timestamp", "t")
    @Help("The time the executable whose coredump you're sending me crashed.")
    long timestamp;

    /// Convert a `Options` to a `Coredump`
    Coredump toCoredump() const
    {
        // The kernel sends `!` instead of `/`: http://man7.org/linux/man-pages/man5/core.5.html
        auto slashPath = this.exePath.replace("!", "/");
        SysTime dTime = unixTimeToStdTime(this.timestamp);
        return new Coredump(this.uid, this.gid, this.pid, this.signal, dTime, this.exe, slashPath);
    }
}
