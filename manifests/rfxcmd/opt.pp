class hallonet::rfxcmd::opt {
    
    require	hallonet::openhabconfig


    File {
        owner => 'pi',
        group => 'pi',
        mode  => '0755',
    }


    package {$params::rfxcmd_packages:
        ensure  => installed,
    }

    
    file {'rfxcmd_initd':
        ensure => present,
        path   => '/etc/init.d/rfxcmd',
        source => "puppet:///modules/${module_name}/init.d/rfxcmd",
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file {'rfxcmd_var':
        ensure => directory,
        path   => '/var/rfxcmd',
    }


    file {'rfxcmd_opt':
        ensure  => directory,
        path    => '/opt/rfxcmd',
        source  => "puppet:///modules/${module_name}/opt/rfxcmd",
        recurse => true,
        require => [File['rfxcmd_var','rfxcmd_initd'],Package[$params::rfxcmd_packages]]
    }

}
