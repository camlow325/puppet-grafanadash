# grafanadash

#### Table of Contents

1. [Overview](#overview)
2. [Setup - The basics of getting started with grafanadash](#setup)
    * [What grafanadash affects](#what-grafanadash-affects)
    * [Usage](#usage)
3. [Limitations - OS compatibility, etc.](#limitations)

## Overview

This is a simple dev module for installing graphite and grafana on a single node.
It was only successfully tested with Puppet 3.7.1 and CentOS 6.

This is basically derived from what the cprice404/grafanadash module does
(https://forge.puppetlabs.com/cprice404/grafanadash) with the exception of no
initial support for setting up elasticsearch.  You're probably better off using
cprice404/grafanadash as this module is purely an experiment.

## Setup

### What grafanadash affects

* Sets selinux to 'permissive'.
* Installs EPEL repo, graphite, related python packages needed by graphite, and
  grafana.  Sets up Apache Virtual Hosts for graphite and grafana.

### Usage

To install with default parameters:

```puppet
    class { 'grafanadash::dev': }
```

To install with custom parameters:

```puppet
    class { 'grafanadash::dev':
      apache_servername           => 'myhost.mydomain.com',
      grafana_apache_port         => 9998,
      graphite_apache_port        => 9997,
      graphite_line_receiver_port => 9996,
      graphite_url                => 'http://myhost.mydomain.com:9997'
    }
```

## Limitations

Sets selinux to permissive rather than just configuring the minimal rules needed
for applications to run with selinux still being enforced.

After the initial installation, requests to the Graphite web app -- including
requests made by the Grafana front-end -- may encounter errors.  In the
/opt/graphite/storage/log/webapp/graphite_error.log a "DatabaseError: database
is locked" error may be seen.  After restarting the Apache web server --
possibly more than once -- this problem seems to disappear.

This module does not work on CentOS 7.0.1406 for three reasons:

1) An "Error: comparison of String with 7 failed at
   ...selinux/manifests/params.pp" message occurs.  This is due to some missing
   logic in the version string checking in the selinux module's params.pp class.
   This is a known issue in the selinux module.  A pull request to address this
   is at https://github.com/spiette/puppet-selinux/pull/13/files.

2) A couple of the dependencies that the graphite module is looking for are
   not satisfied - Django14 and python-sqlite2.  An issue about this was filed
   in the puppet-graphite project -
   https://github.com/echocat/puppet-graphite/issues/106.

3) Assuming one were to workaround the second problem by installing a django
   1.6 version from EPEL, there is a problem in the latest released package
   of graphite-web, 0.9.12, with running under django 1.6.  A fix for that
   problem was integrated to graphite-web master at
   https://github.com/graphite-project/graphite-web/commit/fc3f018544c19b90cc63797d18970a4cc27ef2ad
   but that fix has not been included in a later release of graphite-web.
