project(
    'corecollector',
    'd',
    license: 'GPL-3.0-or-later',
    meson_version: '>=0.50',
    version: '0.1.1',
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

link_runtime_shared_arg = []

if compiler_id == 'llvm'
    link_runtime_shared_arg = ['-link-defaultlib-shared']
elif compiler_id == 'dmd'
    link_runtime_shared_arg = ['-defaultlib=phobos2', '-debuglib=phobos2']
elif compiler_id == 'gcc'
    link_runtime_shared_arg = ['-shared-libphobos']
endif

subdir('source')
subdir('data')
