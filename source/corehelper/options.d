module corehelper.options;

import corecollector.coredump;

import hunt.util.Argument;

struct Options
{
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    @Option("exe-name", "e")
    @Help("The name of the executable whose curedump you're sending me.")
    string exe;

    @Option("pid", "p")
    @Help("The PID of the executable whose coredump you're sending me.")
    ulong pid;

    @Option("uid", "u")
    @Help("The UID of the user who executed the executable whose coredump you're sending me.")
    ulong uid;

    @Option("gid", "g")
    @Help("The GID of the user the executable whose coredump you're sending me.")
    ulong gid;

    @Option("signal", "s")
    @Help("The signal the executable whose coredump you're sending me threw when crashing.")
    ulong signal;

    @Option("timestamp", "t")
    @Help("The time the executable whose coredump you're sending me crashed.")
    string timestamp;

    Coredump toCoredump() {
        return new Coredump(this.uid, this.gid, this.pid, this.signal, this.exe, this.timestamp);
    }
}
