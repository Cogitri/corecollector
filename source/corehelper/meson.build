helper_src = [
    'options.d',
    'corehelper.d',
]

corehelper_exe = executable(
    'corehelper',
    ['main.d', helper_src],
    install: true,
    dependencies: core_lib_dep,
    install_dir: libexec_dir,
)

corehelper_int_test_exe = executable(
    'corehelper-int-test-exe',
    ['main.d', helper_src],
    dependencies: core_lib_test_lib_dep,
    d_module_versions: ['unittest_manual'],
    native: true,
)

corehelper_test_exe = executable(
    'corehelper-test-exe',
    ['../corecollector/lib.d', helper_src],
    dependencies: core_lib_test_lib_dep,
    d_unittest: true,
    d_module_versions: ['unittest_manual'],
    native: true,
)

test('corehelper-test', corehelper_test_exe)
