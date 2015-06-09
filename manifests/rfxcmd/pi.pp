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

    #
    #	Cron jobs
    #

    file {'cron_update_openhab':
        ensure => present,
        path   => '/etc/cron.d/update-openhab',
        source => "puppet:///modules/${module_name}/cron.d/update-openhab",
        require => [File['rfx_commands']],
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file {'cron_update_temperatur_nu':
        ensure => present,
        path   => '/etc/cron.d/update-temperatur-nu',
        source => "puppet:///modules/${module_name}/cron.d/update-temperatur-nu",
        require => [File['rfx_commands']],
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file {'cron_check_openhab_online':
        ensure => present,
        path   => '/etc/cron.d/check-openhab-online',
        source => "puppet:///modules/${module_name}/cron.d/check-openhab-online",
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


    file {'graphite_core_temp':
        ensure => present,
        path   => '/etc/cron.d/graphite-core-temp',
        source => "puppet:///modules/${module_name}/cron.d/graphite-core-temp",
        require => [File['rfx_commands']],
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
 
    
    #
    #	Stuff for /usr/local/bin
    #


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

    file {'usr_local_bin_ttop':
        path    => '/usr/local/bin/ttop.sh',
        source  => "puppet:///modules/${module_name}/usr/local/bin/ttop.sh",
        require => [File['rfx_commands']],
        mode    => '0755',
    }

    file {'multitail':
        ensure  => link,
        require => [File['rfx_commands']],
        path    => '/home/pi/mt.sh',
        target  => '/home/pi/rfx-commands/commands/mt.sh',
    }

    file {'db_backup':
        ensure  => link,
        require => [File['rfx_commands']],
        path    => '/home/pi/db-backup.sh',
        target  => '/home/pi/rfx-commands/commands/db-backup.sh',
    }

}
