main_src = [
    'options.d',
    'corectl.d',
]

executable(
    'corectl',
    ['main.d', main_src],
    install: true,
    dependencies: core_lib_dep,
)

corectl_test_exe = executable(
    'corectl-test-exe',
    ['../corecollector/lib.d', main_src],
    dependencies: core_lib_test_lib_dep,
    d_unittest: true,
    d_module_versions: ['unittest_manual'],
)

test('corectl-test', corectl_test_exe)
