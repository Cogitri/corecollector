import std.file;
import std.path;
import std.process;

class TestInfo
{
    const string testExe;
    const string coreCtlExe;
    const string coreHelperExe;
    const string coredumpTestPath;
    const string dumpPath;

    this(string[] args)
    {
        this.testExe = args[1];
        this.coreCtlExe = args[2];
        this.coreHelperExe = args[3];
        this.coredumpTestPath = args[4];
        this.dumpPath = args[5];

        if (!buildPath(dumpPath, "test_core").exists())
        {
            auto gdbPid = spawnProcess(["gdb", "--exec"] ~ this.testExe ~ [
                    "--batch", "-ex", "run", "-ex", "generate-core-file test_core"
                    ]);

            if (wait(gdbPid) != 0)
            {
                assert(0, "Generating the test coredump with gdb failed.");
            }

            rename("test_core", buildPath(dumpPath, "test_core"));
        }
    }
}
