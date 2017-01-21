class hallonet::packages ($base_packages = $hallonet::params::base_packages,$pip_packages = $hallonet::params::pip_packages) {
    
    include hallonet::params
    
    $install = $hallonet::packages::base_packages
    $pipInstall = $hallonet::packages::pip_packages
    
    package { $install:
        ensure => installed,
    }

    package { $pipInstall:
        ensure   => installed,
        require  => Package[$params::rfxcmd_packages],
	provider => pip,
    }

    file {'usr_local_bin_tkfindsource':
        path    => '/usr/local/bin/tkfindsource.tcl',
        source  => "puppet:///modules/${module_name}/usr/local/bin/tkfindsource.tcl",
        require => Package[$params::rfxcmd_packages],
        mode    => '0755',
    }

    file {'usr_local_bin_sun_rise_set':
        path    => '/usr/local/bin/sun-rise-set.pl',
        source  => "puppet:///modules/${module_name}/usr/local/bin/sun-rise-set.pl",
        require => Package[$params::rfxcmd_packages],
        mode    => '0755',
    }

    file {'usr_local_bin_jq':
        path    => '/usr/local/bin/jq',
        source  => "puppet:///modules/${module_name}/usr/local/bin/jq",
        require => Package[$params::rfxcmd_packages],
        mode    => '0755',
    }

    file {'jq_man1':
        path    => '/usr/share/man/man1/jq.1',
        source  => "puppet:///modules/${module_name}/usr/man1/jq.1",
        require => Package[$params::rfxcmd_packages],
	owner   => 'root',
	group   => 'root',
        mode    => '0644',
    }

}
