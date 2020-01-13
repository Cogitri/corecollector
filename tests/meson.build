test_env = environment()

test_env.set('CORECOLLECTOR_CONFIG_PATH', meson.current_build_dir())

crash_test_exe = executable(
    'crashing_test_exe',
    'crash.d',
)

conf_test = configuration_data()
coredump_test_path = join_paths(meson.current_build_dir(), 'testCoredumps')
conf_test.set('COREDUMP_PATH', coredump_test_path)

configure_file(
    input: 'corecollector.conf.in',
    output: 'corecollector.conf',
    configuration: conf_test,
)

subdir('shTestCases')
