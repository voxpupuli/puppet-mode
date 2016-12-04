# passing manifest 1
class 1 (
  $arg1 = 1,
  $arg2 =
    2,
  $arg3 = [
    1,
    2,
  ],
  $arg4 = {
    1 => 2,
    3 => 4,
  },
  $arg5 = (
    1 + 1
  ),
) {
  file { '/abc':
    ensure  => 'file',
    content =>
      file('abc'),
    require => [
      File['def'],
    ],
  }

  file {
    [
      '/def',
    ]:
      ensure  => 'directory';

    'ghi':
      ensure  => 'file',
      content => file('ghi');

    'jkl':
      ensure  => 'file'
      content => $::osfamily ? {
        'RedHat' => 'jkl',
        default  => 'jklol',
      };

    [
      'mno',
      'pqr',
    ]:
      ensure => (
        'file'
      ),
      content => (
        'stuff'
      );
  }
}
