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

subdir('corehelpersetup')

install_subdir(
    'corecollector',
    install_dir: include_dir,
    exclude_files: 'meson.build',
)
