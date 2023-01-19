# Docker-Nagios

[![Travis branch](https://img.shields.io/travis/rust-lang/rust/master.svg?logo=travis)](https://travis-ci.com/tronyx/Docker-Nagios) [![CodeFactor](https://www.codefactor.io/repository/github/tronyx/docker-nagios/badge)](https://www.codefactor.io/repository/github/tronyx/docker-nagios) [![Docker Pulls](https://img.shields.io/docker/pulls/tronyx/nagios.svg)](https://hub.docker.com/r/tronyx/nagios) [![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/tronyx/Docker-Nagios/blob/master/LICENSE.md) [![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/tronyx/Docker-Nagios.svg)](http://isitmaintained.com/project/tronyx/Docker-Nagios "Average time to resolve an issue") [![Percentage of issues still open](http://isitmaintained.com/badge/open/tronyx/Docker-Nagios.svg)](http://isitmaintained.com/project/tronyx/Docker-Nagios "Percentage of issues still open")

## Notes

Fork of [JasonRivers Docker Nagios image](https://github.com/JasonRivers/Docker-Nagios) to incorporate various improvements from the open PRs on his repo. I have incorporated the following PRs:

* [#96](https://github.com/JasonRivers/Docker-Nagios/pull/96) - Fix issue with Nagiosgraph source (@fregge)
* [#101](https://github.com/JasonRivers/Docker-Nagios/pull/101) - Fixes to allow building on ARM aarch64 architecture (@garethrandall)
* [#110](https://github.com/JasonRivers/Docker-Nagios/pull/110) - Update to Ubuntu 18.04 LTS (@asimzeeshan)
* [#112](https://github.com/JasonRivers/Docker-Nagios/pull/112) - Add python3-nagiosplugin for plugins that need it (@davralin)
* [#116](https://github.com/JasonRivers/Docker-Nagios/pull/116) - Update Nagios to 4.4.6 (@mmerian)
* [#120](https://github.com/JasonRivers/Docker-Nagios/pull/120) - Add NSCA (@mmerian)
* [#130](https://github.com/JasonRivers/Docker-Nagios/issues/130) - Add Perl encryption libraries (@rehashedsalt)
* [#132](https://github.com/JasonRivers/Docker-Nagios/issues/132) - Add rSync (@LutzLegu)

Listing these as I wish to give the original users credit for their work.

## Changes That I've Made

Things that I have changed/updated so far:

* Updated the image to Ubuntu 20.04 LTS
* Updated Nagios Plugins to current latest (2.4.3)
* Updated NRPE to current latest (4.1.0)
* Updated NCPA to current latest (2.4.0)
* Updated NSCA to current latest (2.10.2)
* Added NagiosTV (0.8.5)

## Information

Nagios Core 4.4.10 running on Ubuntu 20.04 LTS with NagiosGraph, NRPE, NCPA, NSCA, CheckMK, and NagiosTV.

| Product | Version |
| ------- | ------- |
| Nagios Core | 4.4.10 |
| Nagios Plugins | 2.4.3 |
| NRPE | 4.1.0 |
| NCPA | 2.4.0 |
| NSCA | 2.10.2 |
| NagiosTV | 0.8.5 |

You can find the Docker Hub repository [HERE](https://hub.docker.com/r/tronyx/nagios).

### Configurations

* Nagios configuration lives in the `/opt/nagios/etc` directory.
* NagiosGraph configuration lives in the `/opt/nagiosgraph/etc` directory.
* NSCA configuration lives in the `/opt/nagiosgraph/etc` directory.

### Install

```bash
docker pull tronyx/nagios
```

### Running

Run with the example configuration with the following:

```bash
docker run --name nagios -p 8080:80 tronyx/nagios
```

Alternatively you can use external Nagios configuration & log data with the following:

```bash
docker run --name nagios  \
  -v /path-to-nagios/etc/:/opt/nagios/etc/ \
  -v /path-to-nagios/var:/opt/nagios/var/ \
  -v /path-to-custom-plugins:/opt/Custom-Nagios-Plugins \
  -v /path-to-nagiosgraph-var:/opt/nagiosgraph/var \
  -v /path-to-nagiosgraph-etc:/opt/nagiosgraph/etc \
  -p 8080:80 tronyx/nagios
```

Note: The path for the custom plugins will be /opt/Custom-Nagios-Plugins, you will need to reference this directory in your configuration scripts.

There are a number of environment variables that you can use to adjust the behaviour of the container:

| Environamne Variable | Description |
|--------|--------|
| MAIL_RELAY_HOST | Set Postfix relayhost |
| MAIL_INET_PROTOCOLS | Set the inet_protocols in postfix |
| NAGIOS_FQDN | Set the server Fully Qualified Domain Name in postfix |
| NAGIOS_TIMEZONE | Set the timezone of the server |

For the best results your Nagios container should have access to both IPv4 & IPv6 networks.

### Credentials

The default credentials for the web interface are:

`nagiosadmin` // `nagios`

### Extra Plugins

* Nagios NRPE [<http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details>]
* Nagios NCPA [<https://exchange.nagios.org/directory/Addons/Monitoring-Agents/NCPA/details>]
* Nagios NSCA [<https://exchange.nagios.org/directory/Addons/Passive-Checks/NSCA--2D-Nagios-Service-Check-Acceptor/details>]
* Nagiosgraph [<http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details>]
* JR-Nagios-Plugins - Custom plugins @JasonRivers created [<https://github.com/JasonRivers/nagios-plugins>]
* WL-Nagios-Plugins - Custom plugins from William Leibzon [<https://github.com/willixix/WL-NagiosPlugins>]
* JE-Nagios-Plugins - Custom plugins from Justin Ellison [<https://github.com/justintime/nagios-plugins>]
* DF-Nagios-Plugins - Custom pluging for MSSQL monitoring from Dan Fruehauf [<https://github.com/danfruehauf/nagios-plugins>]
* check-mqtt - Custom plugin for mqtt monitoring from Jan-Piet Mens [<https://github.com/jpmens/check-mqtt.git>]