module corehelpersetup.main;

import corecollector.logging;

import core.stdc.errno;
import core.sys.posix.sys.resource;
import std.experimental.logger;

version (CRuntime_Musl)
{
    import core.stdc.config;

    /// https://github.com/dlang/druntime/pull/2854
    enum RLIM_INFINITY = cast(c_ulong)(~0UL);
}

int main()
{
    immutable auto logLevel = LogLevel.trace;
    setupLogging(logLevel);

    const auto unlimitedCores = rlimit(RLIM_INFINITY, RLIM_INFINITY);

    if (setrlimit(RLIMIT_CORE, &unlimitedCores) < 0)
    {
        errorf("Failed to set 'RLIMIT_CORE' due to error %m!", errno);
    }

    return 0;
}
