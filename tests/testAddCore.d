import libTest;

import std.datetime;
import std.exception;
import std.file;
import std.format;
import std.path;
import std.process;
import std.stdio;

int main(string[] args)
{
    const auto testInfo = new TestInfo(args);

    auto stdinFilePath = deleteme();

    scope (exit)
    {
        remove(stdinFilePath);
        rmdirRecurse(testInfo.coredumpTestPath);
    }

    writeln(testInfo.coredumpTestPath);

    auto stdinFile = File(stdinFilePath, "w+");

    auto coreHelperPid = spawnProcess([
            testInfo.coreHelperExe, "-e", "test", "-X", "!test!test", "-g",
            "1000", "-u", "1000", "-p", "55", "-s", "6", "-t", "1"
            ], stdinFile, stdout, stderr);

    copy(buildPath(testInfo.dumpPath, "test_core"), stdinFilePath);

    enforce(wait(coreHelperPid) == 0);

    const auto expectedVal = format("ID  SIGNAL   UID      GID      PID      TIMESTAMP             EXE
1   6        1000     1000     55       %s  /test/test
",
            SysTime.fromUnixTime(1).toSimpleString());

    auto coreCtlStdoutPath = deleteme() ~ "stdout";

    scope (exit)
        remove(coreCtlStdoutPath);

    auto coreCtlStdout = File(coreCtlStdoutPath, "w+");

    auto coreCtlPid = spawnProcess([testInfo.coreCtlExe, "list"], stdin,
            coreCtlStdout, File("/dev/null", "w"));

    enforce(wait(coreCtlPid) == 0);

    coreCtlStdout.close();

    auto actualVal = readText(coreCtlStdoutPath);

    assert(expectedVal == actualVal, format("Expected %s, got %s", expectedVal, actualVal));

    return 0;
}
