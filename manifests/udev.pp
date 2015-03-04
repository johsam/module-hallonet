 class hallonet::udev {

    File {
        owner => 'root',
        group => 'root',
        mode  => '0644',
    }


    file {'udev_local_rules':
        ensure => present,
        path   => '/etc/udev/rules.d/10-local.rules',
        source => "puppet:///modules/${module_name}/udev/10-local.rules",
    }

}

