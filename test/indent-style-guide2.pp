# init.pp
class myservice (
  $service_ensure     = $myservice::params::service_ensure,
  $package_list       = $myservice::params::package_list,
  $tempfile_contents  = $myservice::params::tempfile_contents,
) inherits myservice::params {

  if !($service_ensure in [ 'running', 'stopped' ]) {
    fail('ensure parameter must be running or stopped')
  }

  if !$package_list {
    fail("Module ${module_name} does not support ${::operatingsystem}")
  }

  # temp file contents cannot contain numbers
  case $tempfile_contents {
    /\d/: {
      $_tempfile_contents = regsubst($tempfile_contents, '\d', '', 'G')
    }
    default: {
      $_tempfile_contents = $tempfile_contents
    }
  }

  $variable = 'something'

  Package { ensure => present, }

  File {
    owner => '0',
    group => '0',
    mode  => '0644',
  }

  package { $package_list: }

  file { "/tmp/${variable}":
    ensure   => present,
    contents => $_tempfile_contents,
  }

  service { 'myservice':
    ensure    => $service_ensure,
    hasstatus => true,
  }

  Package[$package_list] -> Service['myservice']
}

# params.pp
class myservice::params {
  $service_ensure = 'running'

  case $::operatingsystem {
    'centos': {
      $package_list = 'myservice-centos-package'
    }
    'solaris': {
      $package_list = [ 'myservice-solaris-package1', 'myservice-solaris-package2' ]
    }
    default: {
      $package_list = undef
    }
  }
}
