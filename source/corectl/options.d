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

import hunt.util.Argument;

/// CLI `Options` of `corectl`
struct Options
{
    /// Whether the user requests help (the cmd overview to the printed).
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    /// The debug level to use
    @Option("debug", "d")
    @Help("What debug level to use. -1 = error (default), 0 = info, 1 = debug, 2 = trace.")
    int debugLevel = -1;

    /// What mode `corectl` should run in.
    @Argument("mode")
    @Help(
        "What mode to start in:
        
        - list:
            Lists core dumps that have been recorded by corecollector with the following information:
            
            -Executable: What executable has crashed.
            -Path: The path of the executable that has crashed.
            -Signal: The signal which has terminated the application.
            -UID: The UID of the process that has crashed.
            -GID: The GID of the process that has crashed.
            -PID: The PID the process was running under when it crashed.
            -Timestamp: The time at which the program crashed.
        -debug")
    string mode;
}
