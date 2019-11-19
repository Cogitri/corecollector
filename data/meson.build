configure_file(
    input: 'corecollector.conf.in',
    output: 'corecollector.conf',
    configuration: conf,
    install: true,
    install_dir: sysconf_dir,
)

configure_file(
    input: 'coredumps.json.in',
    output: 'coredumps.json',
    configuration: conf,
    install: true,
    install_dir: varlib_dir,
)
