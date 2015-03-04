class hallonet::openhab {

    #
    #	apt configuration
    #

    file{'apt_auth':
        path    => '/etc/apt/apt.conf.d/99auth',
        owner   => root,
        group   => root,
        content => 'APT::Get::AllowUnauthenticated yes;',
        mode    => '0644',
    }

    file {'openhab_apt_repo':
        ensure  => present,
        path    => '/etc/apt/sources.list.d/openhab.list',
        replace => yes,
        content => template("${module_name}/openhab/openhab.list.erb"),
        require => File['apt_auth'],
        notify  => Exec['apt_update'],
    }

    
    exec {'apt_update':
        path        => '/usr/bin:/bin',
        command     => 'apt-get update',
        refreshonly => true
    }

    #
    #	openhab packages
    #

    package {$params::openhab_packages:
        ensure  => installed,
        alias   => 'openhab_packages',
        require => [File['openhab_apt_repo'],Exec['apt_update']],
        notify  => Exec['openhab_file_perms'],
    }
    
    package {$params::openhab_bindings:
        ensure  => installed,
        require => Package['openhab_packages'],
    }

    #
    #	My openhab addon
    #

    file {'openhab_myopenhab':
        ensure  => present,
        path    => "/usr/share/openhab/addons/${params::myopenhab}",
        source  => "puppet:///modules/${module_name}/openhab/addons/${params::myopenhab}",
        require => Package['openhab_packages'],
    }

    #
    #	Wrong permissions need to be fixed
    #

    exec {'openhab_file_perms':
        path        => '/usr/bin:/bin',
        command     => 'chown -R openhab:openhab /usr/share/openhab/webapps',
        refreshonly => true
    }



}
