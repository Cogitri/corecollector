configuration_d = configure_file(
    input: 'configuration.d',
    output: 'configuration.d',
    configuration: conf,
)

lib_src = [
    configuration_d,
    'coredump.d',
    'logging.d',
    'lz4.d',
]

core_lib = library(
    'corecollector',
    lib_src,
    include_directories: src_inc,
    dependencies: [lz4_dep, hunt_dep],
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    d_module_versions: d_mod_version,
    link_args: ['-shared', '-link-defaultlib-shared'],
)

core_lib_dep = declare_dependency(
    dependencies: hunt_dep,
    link_with: core_lib,
    include_directories: src_inc,
    link_args: '-link-defaultlib-shared',
)

pkgc.generate(
    core_lib,
    name: 'corecollector-0',
    subdirs: 'd/corecollector',
    version: meson.project_version(),
)

core_lib_test_exe = executable(
    'core-lib-text-exe',
    [lib_src, 'tests/main.d'],
    include_directories: src_inc,
    dependencies: [lz4_dep, hunt_dep],
    d_unittest: true,
    link_args: '-link-defaultlib-shared',
)

test(
    'corelib-test',
     core_lib_test_exe,
)
