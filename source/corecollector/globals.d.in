module corecollector.globals;

immutable auto libexecDir = "@LIBEXEC_DIR@";
immutable auto corecollectorVersion = "@CORECOLLECTOR_VERSION@";
// Allow setting the configuration path via an environment variable in tests
version (unittest_manual)
{
    immutable string confPath;
    immutable string testConfigPath;
    shared static this()
    {
        import std.path : buildPath;
        import std.process : environment;

        confPath = environment.get("CORECOLLECTOR_CONFIG_PATH", "@CONFIG_PATH@");
        testConfigPath = buildPath(confPath, "corecollector.conf");
    }
}
else
{
    immutable auto confPath = "@CONFIG_PATH@";
}
immutable auto coredumpPath = "@COREDUMP_PATH@";
immutable auto group = "@CORECOLLECTOR_GROUP@";
immutable auto user = "@CORECOLLECTOR_USER@";
