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


}
