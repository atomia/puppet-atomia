#
# == Class: atomia::rsyslog
#
# Manifest to setup centralized logging with rsyslog
#
# [is_server]
# Set to true if this node is a server
# (optionl) Defaults to false
#
# [server_ip]
# The ip address of the rsyslog server
# (required)
#
#
# === Examples
#
# class { 'atomia::rsyslog':
#   is_server   => true,
# }
#

class atomia::rsyslog(
    $is_server              = false,
    $server_ip,
) {

    if($is_server == true){
        file{ '/etc/rsyslog.d/atomia-rsyslog-server.conf':
            ensure      => present,
            content     => "puppet:///modules/atomia/rsyslog/atomia-rsyslog-server.conf",
        }

        file{ '/etc/rsyslog.conf':
            ensure      => present,
            content     => "puppet:///modules/atomia/rsyslog/rsyslog-server.conf",
        }
    } else{
        file{ '/etc/apache2/conf.d/log-to-syslog.conf':
            ensure      => present,
            content     => "ErrorLog syslog",
        }

        file{ '/etc/rsyslog.d/atomia-rsyslog-client.conf':
            ensure      => present,
            content     => template("atomia/rsyslog/atomia-rsyslog-client.conf.erb"),
        }
    }
}
