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

module corecollector.logging;

import core.sys.posix.syslog;
import std.experimental.logger;
import std.stdio;
import std.string;

/// This `Logger` implementation is basically a `FileLogger` but also
/// logs to syslog.
class SyslogLogger : FileLogger
{
    /// Construct a `SyslogLogger` and call `openlog`.
    this(LogLevel lv, File logFile) @trusted
    {
        super(logFile, lv);
        openlog("corecollector", LOG_ODELAY, LOG_DAEMON);
    }

    /// Write the log message to both stderr and syslog. Doesn't log if
    /// loglevel is none.
    override void writeLogMsg(ref LogEntry payload) @trusted
    {
        super.writeLogMsg(payload);
        if (this.logLevel != LogLevel.off)
        {
            syslog(toSyslogLevel(payload.logLevel), payload.msg.toStringz);
        }
    }

    /// Convert an enum to the respective syslog log level.
    auto toSyslogLevel(LogLevel lv)
    {
        final switch (lv) with (LogLevel)
        {
        case trace:
        case all:
            return LOG_DEBUG;
        case info:
            return LOG_INFO;
        case warning:
            return LOG_WARNING;
        case error:
            return LOG_ERR;
        case critical:
            return LOG_CRIT;
        case fatal:
            return LOG_ALERT;
        case off:
            assert(0);
        }
    }
}

/// Setup the logging with the supplied logging level.
void setupLogging(const LogLevel l, File logFile)
{
    sharedLog = new SyslogLogger(l, logFile);
}
