class hallonet::params {

    $base_packages = [
    'nedit',
    'lftp',
    'multitail',
	'apt-file',
	'python-pip',
	'mlocate',
	'lighttpd',
	'bc',
	'libdatetime-astro-sunrise-perl',
	'libdate-manip-perl',
	'autotools-dev',
	'ruby-dev',
	'avahi-daemon',
	'avahi-utils',
	'libxml-simple-perl',
	'libjson-any-perl',
	'nmap',
    ]

    $pip_packages = [
        'py-dateutil',
        'python-nmap',
        'astral',
        'rethinkdb',
    ]

    $openhab_version = '1.6.2'
    $openhab_packages = ['openhab-runtime']

    $openhab_bindings = [
        'openhab-addon-binding-exec',
        'openhab-addon-persistence-rrd4j'
    ]


    $myopenhab_version = '1.8.0'
    $myopenhab = "org.openhab.io.openhabcloud_1.9.0.201612192331.jar"


    $rfxcmd_packages = [
        'python-mysqldb',
        'python-serial',
    ]

}
