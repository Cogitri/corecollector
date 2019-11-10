module corectl.options;

import hunt.util.Argument;

struct Options
{
    @Option("help", "h")
    @Help("Prints this help.")
    OptionFlag help;

    @Argument("mode")
    @Help("What mode to start in [list|info]")
    string mode;
}
