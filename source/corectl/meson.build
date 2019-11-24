corectl_d = configure_file(
    input: 'corectl.d',
    output: 'corectl.d',
    configuration: conf,
)

main_src = [
    'main.d',
    'options.d',
    corectl_d,
]

executable(
    'corectl',
    main_src,
    install: true,
    dependencies: [hunt_dep, core_lib_dep],
)
