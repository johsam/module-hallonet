define hallonet::copyicon {
    file {$name:
        ensure => present,
        path   => "/usr/share/openhab/webapps/images/${name}.png",
        source => "puppet:///modules/${module_name}/openhab/icons/${name}.png",
    }
}
