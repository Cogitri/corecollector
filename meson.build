project(
    'corecollector',
    'd',
    license: 'GPL-3.0-or-later',
    meson_version: '>=0.50',
    version: '0.3.2',
)

project_soversion = 0

d_mod_version = []

src_inc = include_directories('source')

prefix = get_option('prefix')
libexec_dir = join_paths(prefix, get_option('libexecdir'), 'corecollector')
varlib_dir = join_paths(prefix, get_option('localstatedir'), 'lib', 'corecollector')
sysconf_dir = join_paths(prefix, get_option('sysconfdir'), 'corecollector')
sysctl_dir = join_paths(prefix, get_option('libdir'), 'sysctl.d')
include_dir = join_paths(prefix, get_option('includedir'), 'd', 'corecollector')

vcs_tag = run_command('git', 'rev-parse', '--short', 'HEAD').stdout().strip()
if vcs_tag == ''
    corecollector_version = meson.project_version()
else
    corecollector_version = meson.project_version() + '-@0@'.format (vcs_tag)
endif

compiler_id = meson.get_compiler('d').get_id()
meson_version = meson.version()

if (compiler_id == 'llvm' or compiler_id == 'dmd') and meson_version >= '0.52.0' or meson_version < '0.54'
    warning('Meson version >=0.52 and <0.54 has a bug that causes bad linkage with LDC2 and DMD. Please use GDC or an older/newer meson version.')
endif

gdb = find_program('gdb', native: true, required: false)

if not gdb.found()
    warning('Couldn\'t find gdb! Please be mindful that it\'s required for tests and during runtime.')
endif

subdir('source')
subdir('data')
subdir('tests')
