# == Class: grafanadash::graphite_apache
#
# This class configures an Apache Virtual Host for a Graphite server and
# SHOULD NOT be called directly.
#
# === Parameters
#
# [*apache_servername*]
#   ServerName to add to the Apache Virtual Host configurations for Graphite
#   vhost.
#
# [*graphite_apache_port*]
#   Port on the Apache server under which the Graphite web application should
#   be hosted.
#
class grafanadash::graphite_apache (
  $apache_servername,
  $graphite_apache_port
) {
  # Need to ensure these parent directories for the 'graphite' vhost-managed
  # directories exist so that the vhost can be realized properly.
  file {
    '/opt/graphite':
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755';

    '/opt/graphite/storage':
      ensure => directory,
      owner  => $::graphite::params::web_user,
      group  => $::graphite::params::web_group,
      mode   => '0755';

    '/opt/graphite/storage/log':
      ensure => directory,
      owner  => $::graphite::params::web_user,
      group  => $::graphite::params::web_group,
      mode   => '0755';

    '/opt/graphite/conf':
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755';
  }

  class { 'apache::mod::wsgi':
    wsgi_socket_prefix => 'run/wsgi'
  }

  # This WSGI file contains a hack that works around a problem sometimes seen
  # after the initial install of Graphite.  The Graphite web application would
  # occasionally return errors to the Grafana front-end if requests were made
  # after initialization but before the Apache web server was restarted a
  # second or additional time.  In this error state, the Graphite web app log
  # contained statements like "IntegrityError: column username is not unique"
  # and "DatabaseError: database is locked".  The hack WSGI file sets an
  # environment variable called 'READTHEDOCS'.  The presence of this variable
  # causes the Graphite web app to skip over the code that tries to create a
  # default sqlite user and which led to the above errors in the log.  With
  # this change in place, I have not seen the error messages in the log and
  # the Grafana front-end successfully receives responses from the Graphite
  # web application backend even without the extra Apache web server restarts.
  # The following pull request,
  # https://github.com/graphite-project/graphite-web/pull/527, has changes
  # which have been merged to the graphite-web master branch and hopefully
  # eliminate the need for this hack workaround.  Once this change can be
  # picked up in a new graphite-web release, this hack WSGI file should be
  # removed and the vhost repointed to the original "graphite.wsgi" file
  # the graphite puppet module sets up.
  file { '/opt/graphite/conf/graphite_hack.wsgi':
    ensure  => file,
    owner   => $::graphite::params::web_user,
    group   => $::graphite::params::web_group,
    mode    => '0644',
    content => file('grafanadash/opt/graphite/conf/graphite_hack.wsgi');
  } ->
  apache::vhost { 'graphite':
    servername                  => $apache_servername,
    port                        => $graphite_apache_port,
    docroot                     => '/opt/graphite/webapp',
    logroot                     => '/opt/graphite/storage/log/webapp',
    aliases                     => [
      {
        alias => '/content/',
        path  => '/opt/graphite/webapp/content/'
      },
      {
        alias => '/media/',
        path  => '@DJANGO_ROOT@/contrib/admin/media'
      }
    ],
    directories                 => [
      {
        path  => '/opt/graphite/conf',
        order => 'deny,allow'
      },
      {
        path       => '/content/',
        provider   => 'location',
        sethandler => 'None'
      },
      {
        path       => '/media/',
        provider   => 'location',
        sethandler => 'None'
      },
    ],
    # Need CORS so that Grafana web app can make cross-origin requests from
    # the browser to the Graphite server.
    headers                     => [
      'set Access-Control-Allow-Origin "*"',
      'set Access-Control-Allow-Methods "GET, OPTIONS, POST"',
      'set Access-Control-Allow-Headers "origin, authorization, accept"'
    ],
    wsgi_application_group      => '%{GLOBAL}',
    wsgi_daemon_process         => 'graphite',
    wsgi_daemon_process_options => {
      processes          => '5',
      threads            => '5',
      display-name       => '%{GROUP}',
      inactivity-timeout => 120,
    },
    wsgi_process_group          => 'graphite',
    wsgi_import_script          => '/opt/graphite/conf/graphite_hack.wsgi',
    wsgi_import_script_options  => {
      process-group     => 'graphite',
      application-group => '%{GLOBAL}'
    },
    wsgi_script_aliases         => {
      '/' => '/opt/graphite/conf/graphite_hack.wsgi'
    }
  }
}
