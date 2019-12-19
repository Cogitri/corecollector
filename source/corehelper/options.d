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

import std.array;
import std.datetime;
import std.experimental.logger;
import std.getopt;

auto immutable helpText = "
Usage:
  corehelper [OPTION...]

Dump a coredump from stdin to the coredumpdir for later access

Help Options:
  -h, --help         - Show help options.
  -v, --version      - Print program version.

Application Options (All of these NEED to be specified):
  -e, --exe-name      - Specfiy the name of the executable which crashed.
  -x, --exe-path      - Specify the path of the executable which crashed.
  -p, --pid           - Specfiy the PID that was used when the program crashed.
  -u, --uid           - Specify the UID of the user that ran the crashed program.
  -g, --gid           - Specify the GID of the group that ran the crashed program.
  -s, --signal        - Specify the signal that the program threw when crashing.
  -t, --timestamp     - UNIX time at which the program crashed.";

/// CLI arguments passed to this binary, usually by the kernel
class Options
{
  /// Print the `helpText`.
  bool showHelp;
  /// Print the version.
  bool showVersion;
  /// The string of the exe.
  string exe;
  /// The path of the exe.
  string exePath;
  /// The pid of the program.
  long pid;
  /// The uid of the user running the program.
  long uid;
  /// The gid of the group running the program.
  long gid;
  /// The signal with which the program terminated.
  long signal;
  /// The timestamp of when the program crashed.
  long timestamp;

  this(string[] args) @safe
  {
    getopt(args, "help|h", &this.showHelp, "version|v", &this.showVersion,
        std.getopt.config.required, "e|exe-name", &this.exe,
        std.getopt.config.required, "x|exe-path", &this.exePath,
        std.getopt.config.required, "p|pid", &this.pid,
        std.getopt.config.required, "u|uid", &this.uid,
        std.getopt.config.required, "g|gid", &this.gid,
        std.getopt.config.required, "s|signal", &this.signal,
        std.getopt.config.required, "t|timestamp", &this.timestamp);
    tracef("Parsed options: exe: '%s', exePath: '%s, pid: '%d', uid: '%d', gid: '%d', singal: '%d', timestamp: '%d'",
        this.exe, this.exePath, this.pid, this.uid, this.gid, this.signal, this.timestamp);
  }

  /// Convert a `Options` to a `Coredump`
  Coredump toCoredump() const @safe
  {
    // The kernel sends `!` instead of `/`: http://man7.org/linux/man-pages/man5/core.5.html
    auto slashPath = this.exePath.replace("!", "/");
    SysTime dTime = unixTimeToStdTime(this.timestamp);
    return new Coredump(this.uid, this.gid, this.pid, this.signal, dTime, this.exe, slashPath);
  }
}
