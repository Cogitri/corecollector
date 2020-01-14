test_env = environment()

test_env.set('CORECOLLECTOR_CONFIG_PATH', meson.current_build_dir())

crash_test_exe = executable(
    'crashing_test_exe',
    'crash.d',
    native: true,
)

conf_test = configuration_data()
coredump_test_path = join_paths(meson.current_build_dir(), 'testCoredumps')
conf_test.set('COREDUMP_PATH', coredump_test_path)

configure_file(
    input: 'corecollector.conf.in',
    output: 'corecollector.conf',
    configuration: conf_test,
)

args = [
    crash_test_exe.full_path(),
    corectl_int_test_exe.full_path(),
    corehelper_int_test_exe.full_path(),
    coredump_test_path,
    meson.current_build_dir(),
]

lib_test = static_library(
    'corecollector-lib-test',
    'libTest.d',
    native: true,
)

test_add_core = executable(
    'test-add-core',
    'testAddCore.d',
    link_with: lib_test,
    native: true,
)

test(
    'test-add-core-test',
    test_add_core,
    args: args,
    env: test_env,
)
