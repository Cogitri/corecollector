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

    /// What mode `corectl` should run in.
    @Argument("mode")
    @Help("What mode to start in [list|info]")
    string mode;
}
