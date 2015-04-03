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

}
