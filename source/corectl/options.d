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

import std.algorithm.mutation : remove;

import std.conv;
import std.exception;
import std.format;
import std.getopt;
import std.stdio;
import std.typecons : tuple;

immutable helpText = "
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

class InsufficientArgLengthException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

class UnexpectedArgumentException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

class UnknownArgumentException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

class BadIdException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__) @safe
    {
        super(msg, file, line);
    }
}

/// CLI `Options` of `corectl`
class Options
{
    bool showVersion;
    bool showHelp;
    int debugLevel = -1;
    int id;
    string mode;
    string file;

    this(ref string[] args) @safe
    {
        getopt(args, "help|h", &this.showHelp, "version|v",
                &this.showVersion, "debug|d", &this.debugLevel);

        if (showHelp || showVersion)
        {
            return;
        }

        enforce!InsufficientArgLengthException(args.length >= 2, "Please specify a subcommand.");

        this.mode = args[1];
        switch (this.mode)
        {
        case "list":
            enforce!UnexpectedArgumentException(args.length == 2,
                    format("Didn't expect the additional arguments %s to subcommand 'list'",
                        args.remove(tuple(0, 2))));
            break;
        case "debug":
        case "info":
            enforce!InsufficientArgLengthException(args.length >= 3,
                    format("Expected an ID after the subcommand %s", this.mode));
            enforce!UnexpectedArgumentException(args.length == 3,
                    format("Didn't expect the additional arguments %s to subcommand '%s'",
                        args.remove(tuple(0, 3)), this.mode));
            try
            {
                this.id = args[2].to!int - 1;
            }
            catch (ConvException e)
            {
                throw new BadIdException(format("Can't decode bad ID %s due to error %s",
                        args[2], e.msg));
            }

            enforce!BadIdException(this.id > -1,
                    format("Bad ID %d, IDs start from 1 (see 'corectl list' to find out the ID of a coredump",
                        this.id + 1));
            break;
        case "dump":
            enforce!InsufficientArgLengthException(args.length >= 3,
                    "Expected an ID and optionally a path (or stdout) to dump the coredumd to after the subcommand 'dump'");

            try
            {
                this.id = args[2].to!int - 1;
            }
            catch (ConvException e)
            {
                throw new BadIdException(format("Can't decode bad ID %s due to error %s",
                        args[2], e.msg));
            }

            enforce!BadIdException(this.id > -1,
                    format("Bad ID %d, IDs start from 1 (see 'corectl list' to find out the ID of a coredump",
                        this.id + 1));

            if (args.length == 4)
            {
                this.file = args[3];
            }
            else if (args.length != 3)
            {
                throw new UnexpectedArgumentException(format(
                        "Didn't expect the additional arguments %s to the subcommand 'dump'",
                        args.remove(tuple(0, 4))));
            }

            break;
        default:
            throw new UnknownArgumentException(format("Unknown subcommand %s", this.mode));
        }
    }
}

@safe unittest
{
    import std.array : array;
    import std.stdio;

    auto args = array(["corectl", "-h"]);
    assert(new Options(args).showHelp);
    assert(args.length == 1);
    args ~= "--version";
    assert(new Options(args).showVersion);
    assert(args.length == 1);

    assertThrown!InsufficientArgLengthException(new Options(args));

    args ~= "list";
    assert(new Options(args).mode == "list");
    args ~= "unexpectedarg";
    assertThrown!UnexpectedArgumentException(new Options(args));

    args = array(["corectl", "debug", "1"]);
    auto optionsDebug = new Options(args);
    assert(optionsDebug.id == 0);
    assert(optionsDebug.mode == "debug");
    args ~= "unexpectedarg";
    assertThrown!UnexpectedArgumentException(new Options(args));
    args = array(["corectl", "debug", "0"]);
    assertThrown!BadIdException(new Options(args));
    args = array(["corectl", "debug", "badid"]);
    assertThrown!BadIdException(new Options(args));

    args = array(["corectl", "info", "1"]);
    auto optionsInfo = new Options(args);
    assert(optionsInfo.id == 0);
    assert(optionsInfo.mode == "info");
    args ~= "unexpectedarg";
    assertThrown!UnexpectedArgumentException(new Options(args));
    args = array(["corectl", "info", "0"]);
    assertThrown!BadIdException(new Options(args));
    args = array(["corectl", "info", "badid"]);
    assertThrown!BadIdException(new Options(args));

    args = array(["corectl", "dump", "1"]);
    auto optionsDump = new Options(args);
    assert(optionsDump.id == 0);
    assert(optionsDump.mode == "dump");
    assert(optionsDump.file == "");
    args = array(["corectl", "dump", "1", "stdout"]);
    auto optionsDumpFile = new Options(args);
    assert(optionsDumpFile.id == 0);
    assert(optionsDumpFile.mode == "dump");
    assert(optionsDumpFile.file == "stdout");
    args = array(["corectl", "dump"]);
    assertThrown!InsufficientArgLengthException(new Options(args));
    args ~= "badid";
    assertThrown!BadIdException(new Options(args));
    args = array(["corectl", "dump", "1", "stdout", "unexpectedarg"]);
    assertThrown!UnexpectedArgumentException(new Options(args));

    args = array(["corectl", "unknownarg"]);
    assertThrown!UnknownArgumentException(new Options(args));
}
