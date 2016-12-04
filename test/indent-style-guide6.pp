case $::operatingsystem {
  'centos': {
    $version = '1.2.3'
  }
  'solaris': {
    $version = '3.2.1'
  }
  default: {
    fail("Module ${module_name} is not supported on ${::operatingsystem}")
  }
}
