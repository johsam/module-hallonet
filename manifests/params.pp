class hallonet::params {

    $base_packages = [
        'nedit',
        'lftp',
        'multitail',
	'apt-file',
	'python-pip',
	'mlocate',
	'lighttpd',
	'collectd',
	'bc',
    ]

    $pip_packages = [
        'py-dateutil',
    ]

    $openhab_version = '1.6.2'
    $openhab_packages = ['openhab-runtime']
    
    $openhab_bindings = [
        'openhab-addon-binding-exec',
        'openhab-addon-persistence-rrd4j'
    ]


    $myopenhab_version = '1.7.0'
    $myopenhab = "org.openhab.io.myopenhab-${myopenhab_version}.jar"


    $rfxcmd_packages = [
        'python-mysqldb',
        'python-serial',
    ]

}
