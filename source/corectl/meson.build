main_src = [
    'options.d',
    'corectl.d',
]

corectl_exe = executable(
    'corectl',
    ['main.d', main_src],
    install: true,
    dependencies: core_lib_dep,
)

corectl_int_test_exe  = executable(
    'corectl-int-test-exe',
    ['main.d', main_src],
    dependencies: core_lib_test_lib_dep,
    d_module_versions: ['unittest_manual'],
    native: true,
)
