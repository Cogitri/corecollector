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

struct Options
{
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    @Option("exe-name", "e")
    @Help("The name of the executable whose curedump you're sending me.")
    string exe;

    @Option("pid", "p")
    @Help("The PID of the executable whose coredump you're sending me.")
    ulong pid;

    @Option("uid", "u")
    @Help("The UID of the user who executed the executable whose coredump you're sending me.")
    ulong uid;

    @Option("gid", "g")
    @Help("The GID of the user the executable whose coredump you're sending me.")
    ulong gid;

    @Option("signal", "s")
    @Help("The signal the executable whose coredump you're sending me threw when crashing.")
    ulong signal;

    @Option("timestamp", "t")
    @Help("The time the executable whose coredump you're sending me crashed.")
    string timestamp;

    Coredump toCoredump() {
        return new Coredump(this.uid, this.gid, this.pid, this.signal, this.exe, this.timestamp);
    }
}
