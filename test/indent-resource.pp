file { 'test':
  ensure => present,
  owner  => root,
  group  => root,
}

file { $var:
  ensure => present,
  owner  => root,
  group  => root,
}

file { ['test', $var]:
  ensure => present,
  owner  => root,
  group  => root,
}

my::own::thing { 'yes':
  ensure => present,
  arg    => 42,
}

file { 'test':
  ensure  => present,
  owner   => root,
  group   => root,
  require => [File['one'],
              File['two'],
             ],
  notify  => [
    File['one'],
    File['two'],
  ],
}
