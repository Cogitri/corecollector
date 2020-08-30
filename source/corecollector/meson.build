globals_d = configure_file(
    input: 'globals.d.in',
    output: 'globals.d',
    configuration: conf,
)

lib_src = [
    'configuration.d',
    'coredump.d',
    'logging.d',
]

core_lib = library(
    'corecollector',
    ['muslsyslog.d', lib_src, globals_d],
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    d_module_versions: d_mod_version,
    include_directories: src_inc,
)

core_lib_dep = declare_dependency(
    link_with: core_lib,
    include_directories: src_inc,
)

pkgc.generate(
    core_lib,
    name: 'corecollector-0',
    subdirs: 'd/corecollector',
    version: meson.project_version(),
)

core_lib_test_lib = library(
    'core-lib-test-lib',
    [lib_src, globals_d],
    include_directories: src_inc,
    d_args: '-J' + join_paths(meson.current_source_dir(), 'views'),
    d_module_versions: ['unittest_manual'],
    native: true,
)

core_lib_test_lib_dep = declare_dependency(
    link_with: core_lib_test_lib,
    include_directories: src_inc,
)

install_headers(
    lib_src,
    subdir: 'd/corecollector/corecollector',
)
