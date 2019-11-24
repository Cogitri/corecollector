configure_file(
    input: 'corecollector.conf.in',
    output: 'corecollector.conf',
    configuration: conf,
    install: true,
    install_dir: sysconf_dir,
)

configure_file(
    input: 'corecollector_sysctl.conf.in',
    output: '90-corecollector.conf',
    configuration: conf,
    install: true,
    install_dir: sysctl_dir,
)