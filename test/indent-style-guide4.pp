class bluetooth (
  $ensure      = 'present',
  $autoupgrade = false,
) {
  # Validate class parameter inputs. (Fail early and fail hard)

  if ! ($ensure in [ 'present', 'absent' ]) {
    fail('bluetooth ensure parameter must be absent or present')
  }

  if ! ($autoupgrade in [ true, false ]) {
    fail('bluetooth autoupgrade parameter must be true or false')
  }

  # Set local variables based on the desired state

  if $ensure == 'present' {
    $service_enable = true
    $service_ensure = 'running'
    if $autoupgrade {
      $package_ensure = 'latest'
    } else {
      $package_ensure = 'present'
    }
  } else {
    $service_enable = false
    $service_ensure = 'stopped'
    $package_ensure = 'absent'
  }

  # Declare resources without any relationships in this section

  package { [ 'bluez-libs', 'bluez-utils']:
    ensure => $package_ensure,
  }

  service { 'hidd':
    enable         => $service_enable,
    ensure         => $service_ensure,
    status         => 'source /etc/init.d/functions; status hidd',
    hasstatus      => true,
    hasrestart     => true,
  }

  # Finally, declare relations based on desired behavior

  if $ensure == 'present' {
    Package['bluez-libs']  -> Package['bluez-utils']
    Package['bluez-libs']  ~> Service['hidd']
    Package['bluez-utils'] ~> Service['hidd']
  } else {
    Service['hidd']        -> Package['bluez-utils']
    Package['bluez-utils'] -> Package['bluez-libs']
  }
}
