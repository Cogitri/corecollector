project(
    'corecollector',
    'd',
    license: 'GPL-3.0-or-later',
    meson_version: '>=0.50',
    version: '0.0.1',
)

project_soversion = 0

d_mod_version = []

src_inc = include_directories('source')

hunt_dep = dependency('hunt-1')

prefix = get_option('prefix')
libexec_dir = join_paths(prefix, get_option('libexecdir'), 'corecollector')
varlib_dir = join_paths(prefix, get_option('localstatedir'), 'lib', 'corecollector')
sysconf_dir = join_paths(prefix, get_option('sysconfdir'), 'corecollector')
sysctl_dir = join_paths(prefix, get_option('sysconfdir'), 'sysctl.d')
include_dir = join_paths(prefix, get_option('includedir'), 'd', 'corecollector')

vcs_tag = run_command('git', 'rev-parse', '--short', 'HEAD').stdout().strip()
if vcs_tag == ''
    corecollector_version = meson.project_version()
else
    corecollector_version = meson.project_version() + '-@0@'.format (vcs_tag)
endif



subdir('source')
subdir('data')
