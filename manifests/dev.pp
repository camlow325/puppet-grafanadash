# == Class: grafanadash::dev
#
# Installs Graphite and Grafana on a single host, running under Apache.
#
# === Parameters
#
# [*apache_servername*]
#   ServerName to add to the Apache Virtual Host configurations for Graphite
#   and Grafana vhost.  Defaults to ::fqdn of the host on which the packages
#   are being installed.
#
# [*grafana_apache_port*]
#   Port on the Apache server under which the Grafana web application should
#   be hosted.  Defaults to 10000.
#
# [*graphite_apache_port*]
#   Port on the Apache server under which the Graphite web application should
#   be hosted.  Defaults to 80.
#
# [*graphite_line_receiver_port*]
#   Port of the Graphite line receiver.  Defaults to 2003.
#
# [*graphite_url*]
#   Port of the Graphite web server interface - used by Grafana's config.js
#   to poll Graphite for data.  Defaults to "http://${::fqdn}"
#
# === Examples
#
#  class { 'grafanadash::dev':
#  }
#
#  class { 'grafanadash::dev':
#    apache_servername           => 'myhost.domain.com',
#    grafana_apache_port         => 9999,
#    graphite_apache_port        => 9998,
#    graphite_line_receiver_port => 9997,
#    graphite_url                => 'http://myhost.domain.com:9998'
#  }
#
class grafanadash::dev (
  $apache_servername           = $grafanadash::params::apache_servername,
  $grafana_apache_port         = $grafanadash::params::grafana_apache_port,
  $graphite_apache_port        = $grafanadash::params::graphite_apache_port,
  $graphite_line_receiver_port = $grafanadash::params::graphite_line_receiver_port,
  $graphite_url                = $grafanadash::params::graphite_url
) inherits grafanadash::params {
  class { 'epel': } ->
  class { 'selinux':
    mode => 'permissive'
  } ->
  class { 'graphite':
    gr_apache_port             => $graphite_apache_port,
    gr_line_receiver_port      => $graphite_line_receiver_port,
    gr_web_server              => 'none',
    gr_web_cors_allow_from_all => true
  } ->
  # TODO: Would prefer to let puppet-grafana manage the /opt/grafana symlink
  # itself but letting it do so would have /opt/grafana point to
  # /opt/grafana-[version] while the grafana archive would be expanded to
  # /opt/grafana-[version]/grafana-[version].  See
  # https://github.com/bfraser/puppet-grafana/pull/13.  Managing symlink locally
  # for now so that it points to where the archive is installed.  config.js is
  # still being installed to /opt/grafana-[version] so creating a symlink to
  # that from /opt/grafana-[version]/grafana-[version] so that it can be
  # retrieved from the base directory of the archive.  Should be able to remove
  # the symlink_name file resources and let symlink = true (default) as a
  # parameter to the 'grafana' class once this issue is addressed.
  class { 'grafana':
    symlink     => false,
    datasources => {
      'graphite' => {
        'type'    => 'graphite',
        'url'     => $graphite_url,
        'default' => true
      }
    }
  } ->
  file { $::grafana::symlink_name:
    ensure => link,
    target => "/opt/grafana-${::grafana::params::version}/grafana-${::grafana::params::version}",
    owner  => $::grafana::grafana_user,
    group  => $::grafana::grafana_group
  } ->
  file { "${::grafana::symlink_name}/config.js":
    ensure => link,
    target => $::grafana::config_js,
    owner  => $::grafana::grafana_user,
    group  => $::grafana::grafana_group
  }

  class { 'apache':
    default_vhost => false,
  }

  class { 'grafanadash::graphite_apache':
    apache_servername    => $apache_servername,
    graphite_apache_port => $graphite_apache_port
  }

  # Added this to workaround "Could not find dependency" error that otherwise
  # would occur.  See https://github.com/bfraser/puppet-grafana/issues/5.
  include archive::prerequisites

  class { 'grafanadash::grafana_apache':
    apache_servername   => $apache_servername,
    grafana_apache_port => $grafana_apache_port
  }
}
