configure_file(
    input: 'corecollector.conf.in',
    output: 'corecollector.conf',
    configuration: conf,
    install: true,
    install_dir: sysconf_dir,
)

configure_file(
    input: 'corecollector_sysctl.conf.in',
    output: '90-corecollector.conf',
    configuration: conf,
    install: true,
    install_dir: sysctl_dir,
)


scdoc = dependency('scdoc', version: '>=1.9.2', native: true, required: get_option('man-pages'))
if scdoc.found()
    scdoc_prog = find_program(scdoc.get_pkgconfig_variable('scdoc'), native: true)
    sh = find_program('sh', native: true)
    mandir = get_option('mandir')
    man_files = [
        'man/corectl.1.scd',
        'man/corecollector_conf.5.scd',
    ]
    foreach filename : man_files
        topic = filename.split('.')[-3].split('/')[-1]
        if topic.contains('_')
            topic = topic.split('_')[0] + '.' + topic.split('_')[1]
        endif
        section = filename.split('.')[-2]
        output = '@0@.@1@'.format(topic, section)

        custom_target(
            output,
            input: filename,
            output: output,
            command: [
                sh, '-c', '@0@ < @INPUT@ > @1@'.format(scdoc_prog.path(), join_paths('data', output))
            ],
            install: true,
            install_dir: '@0@/man@1@'.format(mandir, section)
        )
    endforeach
endif
