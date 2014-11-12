# == Class: grafanadash::grafana_apache
#
# This class configures an Apache Virtual Host for a Grafana server and
# SHOULD NOT be called directly.
#
# === Parameters
#
# [*apache_servername*]
#   ServerName to add to the Apache Virtual Host configurations for Grafana
#   vhost.
#
# [*grafana_apache_port*]
#   Port on the Apache server under which the Grafana web application should
#   be hosted.
#
class grafanadash::grafana_apache (
  $apache_servername,
  $grafana_apache_port
) {
  # Create Apache virtual host
  apache::vhost { 'grafana':
    servername      => $apache_servername,
    port            => $grafana_apache_port,
    docroot         => '/opt/grafana',
    error_log_file  => 'grafana-error.log',
    access_log_file => 'grafana-access.log',
    directories     => [
      {
        # TODO: Only need 'FollowSymLinks' here because config.js is a
        # symlink to a file in the parent directory.  See comment above the
        # 'grafana' class reference in dev.pp.  Should remove this when the
        # underlying issue in puppet-grafana is addressed.
        path           => '/opt/grafana',
        options        => [ 'FollowSymLinks' ],
        allow          => 'from All',
        allow_override => [ 'None' ],
        order          => 'Allow,Deny',
      }
    ]
  }
}
