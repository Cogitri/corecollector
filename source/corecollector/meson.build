globals_d = configure_file(
    input: 'globals.d',
    output: 'globals.d',
    configuration: conf,
)

lib_src = [
    'configuration.d',
    'coredump.d',
    'logging.d',
    globals_d,
]

core_lib = library(
    'corecollector',
    ['muslsyslog.d', lib_src],
    install: true,
    version: meson.project_version(),
    soversion: project_soversion,
    d_module_versions: d_mod_version,
    include_directories: src_inc,
    link_args: ['-shared', link_runtime_shared_arg],
)

core_lib_dep = declare_dependency(
    link_with: core_lib,
    include_directories: src_inc,
    link_args: link_runtime_shared_arg,
)

pkgc.generate(
    core_lib,
    name: 'corecollector-0',
    subdirs: 'd/corecollector',
    version: meson.project_version(),
)

core_lib_test_lib = library(
    'core-lib-test-lib',
    lib_src,
    d_unittest: true,
    include_directories: src_inc,
    d_args: '-J' + join_paths(meson.current_source_dir(), 'views'),
    d_module_versions: ['unittest_manual'],
    link_args: [link_runtime_shared_arg],
)

core_lib_test_lib_dep = declare_dependency(
    link_with: core_lib_test_lib,
    include_directories: src_inc,
    link_args: link_runtime_shared_arg,
)

# TODO: instead of compiling the source twice here it'd be nice if we could
# link a dummy main() against core_lib_test_lib_dep
core_lib_test_exe = executable(
    'core-lib-test-exe',
    [lib_src, 'lib.d'],
    d_unittest: true,
    link_args: [link_runtime_shared_arg],
    include_directories: src_inc,
    d_module_versions: ['unittest_manual'],
    d_args: '-J' + join_paths(meson.current_source_dir(), 'views'),
)

test(
    'corelib-test',
     core_lib_test_exe,
)

install_headers(
    lib_src,
    subdir: 'd/corecollector/corecollector',
)
