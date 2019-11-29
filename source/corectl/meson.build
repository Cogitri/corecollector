corectl_d = configure_file(
    input: 'corectl.d',
    output: 'corectl.d',
    configuration: conf,
)

main_d = configure_file(
    input: 'main.d',
    output: 'main.d',
    configuration: conf,
)

main_src = [
    'options.d',
    main_d,
    corectl_d,
]

executable(
    'corectl',
    main_src,
    install: true,
    dependencies: core_lib_dep,
)
