pkgc = import('pkgconfig')

conf = configuration_data()

conf.set('COREDUMP_PATH', varlib_dir)
conf.set('CONF_PATH', sysconf_dir)
conf.set('LIBEXECDIR', libexec_dir)
conf.set('VERSION', corecollector_version)

dlang = import('dlang')

subdir('corecollector')

subdir('corectl')

subdir('corehelper')

install_subdir(
    'corecollector',
    install_dir: include_dir,
    exclude_files: 'meson.build',
)
