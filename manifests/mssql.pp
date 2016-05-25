## Atomia customer MSSQL resource server

### Deploys and configures a server running MSSQL for hosting customer databases.

### Variable documentation
#### mssql_username: The username of the MySQL user that automation server provisions databases through.
#### mssql_password: The password for the MySQL user that automation server provisions databases through.
#### server_ips: Comma separated list of all mysql servers ip addresses
#### product_key: Your license key for MSSQL
#### isopath: The absolute path to the MSSQL iso

### Validations
##### mssql_username(advanced): %username
##### mssql_password(advanced): %password
##### server_ips(advanced): .*
##### product_key: .*
##### isopath: .*

class atomia::mssql (
  $mssql_username  = 'AtomiaAdmin',
  $mssql_password,
  $server_ips      = '',
  $product_key,
  $isopath,
){

  class {'windows_sql':
    features            => 'SQL,RS_SHP,RS_SHPWFE,TOOLS',
    pid                 => $product_key,
    sqlsysadminaccounts => $mssql_username,
    agtsvcaccount       => 'svc_sqlagt',
    isopath             => $isopath,
    sqlsvcaccount       => 'svc_sqlsvc',
    securitymode        => 'sql',
    sapwd               => $mssql_password,
    mode                => 'master',
  }

}
