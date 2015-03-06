class hallonet {
    include hallonet::params
   
    include hallonet::packages

    include hallonet::openhab
    include hallonet::openhabconfig

    include hallonet::rfxcmd

}
