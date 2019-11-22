* Set the sysctl `kernel.core_pattern` property
    * Check if it's set when invoking `corectl`
* Improve `corectl`'s UX
    * Add info subcommand
    * Make command parsing friendlier
    * Make config parsing friendlier
    * Properly line up text in `corectl list`
        * Truncate strings if too long
* corehelper
    * Convert UNIX timestamp we get from the kernel to date
    * Drop uneeded privileges
    * Record program's path so we can make invoking the debugger easier