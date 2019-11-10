helper_d = configure_file(
    input: 'main.d',
    output: 'main.d',
    configuration: conf,
)

helper_src = [
    helper_d,
    'options.d',
    'corehelper.d',
]


executable(
    'corehelper',
    helper_src,
    install: true,
    dependencies: [hunt_dep, core_lib_dep],
    install_dir: libexec_dir,
)
