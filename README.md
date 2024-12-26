# Docker-Nagios

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/tronyx/Docker-Nagios/build.yml) [![CodeFactor](https://www.codefactor.io/repository/github/tronyx/docker-nagios/badge)](https://www.codefactor.io/repository/github/tronyx/docker-nagios) [![Docker Pulls](https://img.shields.io/docker/pulls/tronyx/nagios.svg)](https://hub.docker.com/r/tronyx/nagios) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/tronyx/nagios?arch=amd64&label=amd64) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/tronyx/nagios?arch=arm64&label=arm64) [![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/tronyx/Docker-Nagios/blob/master/LICENSE.md)

## Notes

Fork of [JasonRivers Docker Nagios image](https://github.com/JasonRivers/Docker-Nagios) to incorporate various improvements from the open PRs on his repo. I have incorporated the following PRs:

* [#96](https://github.com/JasonRivers/Docker-Nagios/pull/96) - Fix issue with Nagiosgraph source ([fregge](https://github.com/fregge))
* [#101](https://github.com/JasonRivers/Docker-Nagios/pull/101) - Fixes to allow building on ARM aarch64 architecture ([garethrandall](https://github.com/garethrandall))
* [#110](https://github.com/JasonRivers/Docker-Nagios/pull/110) - Update to Ubuntu 18.04 LTS ([asimzeeshan](https://github.com/asimzeeshan))
* [#112](https://github.com/JasonRivers/Docker-Nagios/pull/112) - Add python3-nagiosplugin for plugins that need it ([davralin](https://github.com/davralin))
* [#116](https://github.com/JasonRivers/Docker-Nagios/pull/116) - Update Nagios to 4.4.6 ([mmerian](https://github.com/mmerian))
* [#120](https://github.com/JasonRivers/Docker-Nagios/pull/120) - Add NSCA ([mmerian](https://github.com/mmerian))
* [#130](https://github.com/JasonRivers/Docker-Nagios/issues/130) - Add Perl encryption libraries ([rehashedsalt](https://github.com/rehashedsalt))
* [#132](https://github.com/JasonRivers/Docker-Nagios/issues/132) - Add rSync ([LutzLegu](https://github.com/LutzLegu))
* [#165](https://github.com/JasonRivers/Docker-Nagios/pull/165) - Added libcrypt-x509-per and libtext-glob-perl modules ([Scott-Jones-COS](https://github.com/Scott-Jones-COS))

Listing these as I wish to give the original users credit for their work.

## Changes That I've Made

Things that I have changed/updated/added to date:

* Updated the image to Ubuntu 24.04 LTS
* Updated Nagios Core to the current latest
* Updated Nagios Plugins to current latest
* Updated NRPE to current latest
* Updated NCPA to current latest
* Updated NSCA to current latest
* Added NagiosTV
* Built multi-arch images (amd64 & arm64)

## Information

Nagios Core running on Ubuntu 24.04 LTS with NagiosGraph, NRPE, NCPA, NSCA, and NagiosTV.

| Product | Version |
| ------- | ------- |
| [Nagios Core](https://github.com/NagiosEnterprises/nagioscore/releases) | 4.5.9 |
| [Nagios Plugins](https://github.com/nagios-plugins/nagios-plugins) | 2.4.12 |
| [NRPE](https://github.com/NagiosEnterprises/nrpe) | 4.1.3 |
| [NCPA](https://github.com/NagiosEnterprises/ncpa) | 3.1.1 |
| [NSCA](https://github.com/NagiosEnterprises/nsca) | 2.10.3 |
| [NagiosTV](https://github.com/chriscareycode/nagiostv-react) | 0.9.2 |

You can find the Docker Hub Registry [HERE](https://hub.docker.com/r/tronyx/nagios) or the GitHub Registry [HERE](https://github.com/tronyx/Docker-Nagios/pkgs/container/nagios).

### Configurations

* Nagios configuration is stored in the `/opt/nagios/etc` directory.
* NagiosGraph configuration is stored in the `/opt/nagiosgraph/etc` directory.
* NSCA configuration is stored in the `/opt/nagios/etc` directory.

### Pull the Image

```bash
docker pull tronyx/nagios
docker pull ghcr.io/tronyx/nagios
```

#### Versions/Docker Tags

| Branch | Image Tag | Notes |
| ------- | ------- | ------- |
| Master | latest | Master branch that is known to be stable. |
| Develop | develop | My testing/development branch for updates. |
| Ubuntu-22.04 | ubuntu-22.04 | Older Ubuntu base version that still has Python 2 and the plugins that require it. Use this for arm-v7 hardware. Will keep this as up-to-date as possible. |

### Running

Run the container with the example configuration using the following `docker` commands:

```bash
docker run --name nagios -p 8080:80 tronyx/nagios
docker run --name nagios -p 8080:80 ghcr.io/tronyx/nagios
```

Alternatively you can use external Nagios configuration & log data with the following `docker` commands:

```bash
docker run --name nagios  \
  -v /path-to-nagios/etc/:/opt/nagios/etc/ \
  -v /path-to-nagios/var:/opt/nagios/var/ \
  -v /path-to-custom-plugins:/opt/Custom-Nagios-Plugins \
  -v /path-to-nagiosgraph-var:/opt/nagiosgraph/var \
  -v /path-to-nagiosgraph-etc:/opt/nagiosgraph/etc \
  -p 8080:80 tronyx/nagios

docker run --name nagios  \
  -v /path-to-nagios/etc/:/opt/nagios/etc/ \
  -v /path-to-nagios/var:/opt/nagios/var/ \
  -v /path-to-custom-plugins:/opt/Custom-Nagios-Plugins \
  -v /path-to-nagiosgraph-var:/opt/nagiosgraph/var \
  -v /path-to-nagiosgraph-etc:/opt/nagiosgraph/etc \
  -p 8080:80 ghcr.io/tronyx/nagios
```

Note: The path for the custom plugins will be `/opt/Custom-Nagios-Plugins`, which you will need to reference in your configuration scripts.

There are a number of environment variables that you can use to adjust the behaviour of the container:

| Environment Variable | Description |
|--------|--------|
| MAIL_RELAY_HOST | Set Postfix relayhost |
| MAIL_INET_PROTOCOLS | Set the inet_protocols in Postfix |
| NAGIOS_FQDN | Set the server Fully Qualified Domain Name in Postfix |
| NAGIOS_TIMEZONE | Set the timezone of the server |

For the best results your Nagios container should have access to both IPv4 & IPv6 networks.

### Credentials

The default credentials for the web interface are:

| Username | Password |
|--------|--------|
| `nagiosadmin` | `nagios` |

### Extra Plugins

* [Nagios NRPE](http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details)
* [Nagios NCPA](https://exchange.nagios.org/directory/Addons/Monitoring-Agents/NCPA/details)
* [Nagios NSCA](https://exchange.nagios.org/directory/Addons/Passive-Checks/NSCA--2D-Nagios-Service-Check-Acceptor/details)
* [Nagiosgraph](http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details)
* [JR-Nagios-Plugins](https://github.com/JasonRivers/nagios-plugins) - Custom plugins from Jason Rivers
* [WL-Nagios-Plugins](https://github.com/willixix/WL-NagiosPlugins) - Custom plugins from William Leibzon
* [JE-Nagios-Plugins](https://github.com/justintime/nagios-plugins) - Custom plugins from Justin Ellison
* [DF-Nagios-Plugins](https://github.com/danfruehauf/nagios-plugins) - Custom pluging for MSSQL monitoring from Dan Fruehauf
* [check-mqtt](https://github.com/jpmens/check-mqtt.git) - Custom plugin for mqtt monitoring from Jan-Piet Mens
* [NagiosTV](https://github.com/chriscareycode/nagiostv-react) - Monitor your Nagios server on a wall-mounted TV
* [check_apc](https://exchange.nagios.org/directory/Plugins/Hardware/UPS/APC/check_apc-2Epl/details) - Check APC for status, health, and load