pkgc = import('pkgconfig')

conf = configuration_data()

conf.set('COREDUMP_PATH', varlib_dir)
conf.set('CONFIG_PATH', sysconf_dir)
conf.set('LIBEXEC_DIR', libexec_dir)
conf.set('CORECOLLECTOR_VERSION', corecollector_version)
conf.set('CORECOLLECTOR_USER', 'corecollector')
conf.set('CORECOLLECTOR_GROUP', 'corecollector')

subdir('corecollector')

subdir('corectl')

subdir('corehelper')

foreach src : lib_src
    fmt = '@0@'
    file_name = fmt.format(src).underscorify()
    src_name = 'corecollector/@0@'.format(src)
    lib_test_exe = executable('test_libcorecollector' + file_name + '_exe',
        ['corecollector/lib.d', src_name],
        include_directories: src_inc,
        d_args: '-J' + join_paths(meson.current_source_dir(), 'corecollector', 'views'),
        d_unittest: true,
        d_module_versions: ['unittest_manual'],
        native: true,
        dependencies: core_lib_test_lib_dep,
    )
    test('test_libcorecollector_' + file_name, lib_test_exe)
endforeach

foreach src : helper_src
    fmt = '@0@'
    extra_src = []
    if src == 'corehelper.d'
      extra_src = ['corehelper/options.d']
    endif

    file_name = fmt.format(src).underscorify()
    src_name = 'corehelper/@0@'.format(src)
    helper_test_exe = executable('test_corehelper' + file_name + '_exe',
        ['corecollector/lib.d', src_name, extra_src],
        dependencies: core_lib_test_lib_dep,
        d_unittest: true,
        d_module_versions: ['unittest_manual'],
        native: true,
    )
    test('test_corehelper_' + file_name, helper_test_exe)
endforeach

foreach src : main_src
    fmt = '@0@'
    file_name = fmt.format(src).underscorify()
    src_name = 'corectl/@0@'.format(src)
    corectl_test_exe = executable('test_corectl' + file_name + '_exe',
        ['corecollector/lib.d', src_name],
        dependencies: core_lib_test_lib_dep,
        d_unittest: true,
        d_module_versions: ['unittest_manual'],
        native: true,
    )
    test('test_corectl_' + file_name, corectl_test_exe)
endforeach

