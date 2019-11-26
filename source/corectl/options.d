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

module corectl.options;

import std.conv;
import std.exception;
import std.format;
import std.getopt;

immutable helpText =
"
Usage:
  corectl <subcommand> [OPTION...]
  
List and interact with coredumps

Subcommands:
  debug [ID]        - Open the coredump identified by ID in a debugger.
  dump  [ID] [FILE] - Dump the coredump identified by ID to file denoted by FILE.
                      Defaults to 'stdout'.
  info [ID]         - Get more detailed information for the coredump identified by ID.
  list              - List all available coredumps.
  
Help Options:
  -h, --help         - Show help options.

Application Options:
  -v, --version      - Print program version.
  -d, --debug [0-3]  - Specify the debug level.";

/// CLI `Options` of `corectl`
class Options
{
    bool showVersion;
    bool showHelp;
    int debugLevel = -1;
    int id;
    string mode;
    string file;

    this(string[] args) {
        getopt(args,
            "help|h", &showHelp,
            "version|v", &showVersion,
            "debug|d", &debugLevel,
        );

        if (showHelp || showVersion) {
            return;
        }

        enforce(args.length >= 2, "Please specify a subcommand.");

        this.mode = args[1];
        switch(this.mode) {
            case "list":
                enforce(args.length == 2, "Didn't expect additional arguments to 'list'");
                break;
            case "debug":
            case "info":
                enforce(args.length == 3, "Only expected two arguments (subcommand and ID)");
                this.id = args[2].to!uint - 1;
                break;
            case "dump":
                if (args.length == 3) {
                    this.id = args[2].to!uint - 1;
                } else if (args.length == 4) {
                    this.id = args[2].to!uint - 1;
                    this.file = args[3];
                } else {
                    assert(0, "Expected either ID or ID and file to dump to for subcommand");
                }

                break;
            default:
                assert(0, format("Unknown subcommand %s", this.mode));
        }
    }
}
