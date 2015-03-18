 class hallonet::openhabconfig {
    
    require hallonet::params
    require hallonet::openhab

    File {
        owner => 'pi',
        group => 'pi',
        mode  => '0644',
    }

    file {'openhab_sitemap':
        ensure => present,
        path   => '/etc/openhab/configurations/sitemaps/ripan.sitemap',
        source => "puppet:///modules/${module_name}/openhab/sitemaps/ripan.sitemap",
    }

#    file {'openhab_sitemap_default':
#        ensure  => link,
#        path    => '/etc/openhab/configurations/sitemaps/default.sitemap',
#        target  => 'ripan.sitemap',
#        require => File['openhab_sitemap'],
#    }



    file {'openhab_items':
        ensure => present,
        path   => '/etc/openhab/configurations/items/ripan.items',
        source => "puppet:///modules/${module_name}/openhab/items/ripan.items",
    }

    file {'openhab_config':
        ensure => present,
        path   => '/etc/openhab/configurations/openhab.cfg',
        source => "puppet:///modules/${module_name}/openhab/openhab.cfg",
    }

    file {'openhab_rrd4j':
        ensure => present,
        path   => '/etc/openhab/configurations/persistence/rrd4j.persist',
        source => "puppet:///modules/${module_name}/openhab/persistence/rrd4j.persist",
    }



    hallonet::copyicon {[
        'ripan_clock',
        'ripan_humidity',
        'ripan_new_temp',
        'ripan_openhab',
        'ripan_pi',
        'ripan_small_blue_temp',
        'ripan_small_red_temp',
        'ripan_temp',
        'ripan_tnu'
    ]:}

}

