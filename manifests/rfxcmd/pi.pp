class hallonet::rfxcmd::pi {

    $mailme = hiera('mailme','')

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
        ensure  => present,
        path    => '/etc/cron.d/update-openhab',
        source  => "puppet:///modules/${module_name}/cron.d/update-openhab",
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'cron_update_temperatur_nu':
        ensure  => present,
        path    => '/etc/cron.d/update-temperatur-nu',
        source  => "puppet:///modules/${module_name}/cron.d/update-temperatur-nu",
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'cron_sql_backup':
        ensure  => present,
        path    => '/etc/cron.d/mysql-backup',
        content => template("${module_name}/cron/mysql-backup.erb"),
        require => Package[$params::rfxcmd_packages],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }


    file {'cron_wifi_check':
        ensure  => present,
        path    => '/etc/cron.d/wifi-check',
        content => template("${module_name}/cron/wifi-check.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'cron_nmap':
        ensure  => present,
        path    => '/etc/cron.d/nmap',
        content => template("${module_name}/cron/nmap.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }



    file {'cron_check_openhab_online':
        ensure  => present,
        path    => '/etc/cron.d/check-openhab-online',
        content => template("${module_name}/cron/check-openhab-online.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file {'cron_nexa_lights':
        ensure  => present,
        path    => '/etc/cron.d/nexa-lights',
        content => template("${module_name}/cron/nexa-lights.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

 
    file {'cron_update_sun_rise_set':
        ensure  => present,
        path    => '/etc/cron.d/update-sun-rise-set',
        content => template("${module_name}/cron/update-sun-rise-set.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
  
     file {'cron_schedule_lights_around_sunset':
        ensure  => present,
        path    => '/etc/cron.d/schedule-lights-around-sunset',
        content => template("${module_name}/cron/schedule-lights-around-sunset.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
 
     file {'cron_check_apt_updates':
        ensure  => present,
        path    => '/etc/cron.d/check-apt-updates',
        content => template("${module_name}/cron/check-apt-updates.erb"),
        require => [File['rfx_commands']],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
   
    #
    #	Stuff for /usr/local/bin
    #


    file {'openhab_to_nexa':
        ensure  => link,
        require => [File['rfx_commands']],
        path    => '/usr/local/bin/openhab-send-to-nexa.sh',
        target  => '/home/pi/rfx-commands/commands/openhab-send-to-nexa.sh',
    }


    file {'usr_local_bin_ttop':
        ensure  => link,
        require => [File['rfx_commands']],
        path    => '/usr/local/bin/ttop.sh',
        target  => '/home/pi/rfx-commands/ttop/ttop.sh',
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


    file {'pubnubmgr_initd':
        ensure => present,
        path   => '/etc/init.d/pubnubmgr',
        source => "puppet:///modules/${module_name}/init.d/pubnubmgr",
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }


}
