define puppet::puppetmaster::hasdb(
  $dbtype = 'mysql',
  $dbname = 'puppet',
){

  if !$puppet_storeconfig_password { fail("No \$puppet_storeconfig_password is set, please set it in your manifests or site.pp to add a password") }

  case $dbtype {
    'mysql': {  puppet::puppetmaster::hasdb::mysql{$name: dbname => $dbname, dbhost => $dbhost, dbuser => $dbuser, dbpwd => $dbpwd, } }
  }
}
