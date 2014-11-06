# == Class: grafanadash::params
#
# This class specifies default parameters for the grafanadash module and
# SHOULD NOT be called directly.
#
# === Parameters
#
# None.
#

class grafanadash::params {
  $apache_servername           = $::fqdn
  $grafana_apache_port         = 10000
  $graphite_apache_port        = 80
  $graphite_line_receiver_port = 2003
  $graphite_url                = "http://${::fqdn}"
}