class hallonet::packages ($base_packages = $hallonet::params::base_packages) {
    
    include hallonet::params
    
    $install = $hallonet::packages::base_packages
    
    package { $install:
        ensure => installed,
    }
}
