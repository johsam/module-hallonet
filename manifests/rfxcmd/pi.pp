class hallonet::rfxcmd::pi {

    require	hallonet::openhabconfig


    File {
        owner => 'pi',
        group => 'pi',
    }


    file {'rfx_commands':
        ensure  => directory,
        path    => '/home/pi/rfx-commands',
        source  => "puppet:///modules/${module_name}/pi/rfx-commands",
        recurse => true,
    }

    file {'nexa_one_off_link':
        ensure  => link,
        require => [File['rfx_commands']],
        path    => '/usr/local/bin/nexa_one_off.sh',
        target  => '/home/pi/rfx-commands/commands/nexa_one_off.sh',
    }

    file {'nexa_one_on_link':
        ensure  => link,
        require => [File['rfx_commands']],
        path    => '/usr/local/bin/nexa_one_on.sh',
        target  => '/home/pi/rfx-commands/commands/nexa_one_on.sh',
    }

    file {'cron_update_openhab':
        ensure => present,
        path   => '/etc/cron.d/update-openhab',
        source => "puppet:///modules/${module_name}/cron.d/update-openhab",
        require => [File['rfx_commands']],
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file {'cron_nexa_lights':
        ensure => present,
        path   => '/etc/cron.d/nexa-lights',
        source => "puppet:///modules/${module_name}/cron.d/nexa-lights",
        require => [File['rfx_commands']],
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

}
