test_add_core_exe = find_program('testAddCore.sh')

args = [
    crash_test_exe.full_path(),
    corectl_int_test_exe.full_path(),
    corehelper_int_test_exe.full_path(),
    coredump_test_path,
]

test(
    'testAddCore',
    test_add_core_exe,
    args: args,
    env: test_env,
)
