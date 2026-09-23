# Docker-Nagios

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/tronyx/Docker-Nagios/build.yml) [![CodeFactor](https://www.codefactor.io/repository/github/tronyx/docker-nagios/badge)](https://www.codefactor.io/repository/github/tronyx/docker-nagios) [![Docker Pulls](https://img.shields.io/docker/pulls/tronyx/nagios.svg)](https://hub.docker.com/r/tronyx/nagios) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/tronyx/nagios?arch=amd64&label=amd64) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/tronyx/nagios?arch=arm64&label=arm64) [![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/tronyx/Docker-Nagios/blob/master/LICENSE.md)

## Notes

Fork of [JasonRivers Docker Nagios image](https://github.com/JasonRivers/Docker-Nagios) to incorporate various improvements from the open PRs on his repo along with other updates and quality of life improvements.

## Incorporated PRs

Listing these as I wish to give the original users credit for their work.

* [#96](https://github.com/JasonRivers/Docker-Nagios/pull/96) - Fix issue with Nagiosgraph source ([fregge](https://github.com/fregge))
* [#101](https://github.com/JasonRivers/Docker-Nagios/pull/101) - Fixes to allow building on ARM aarch64 architecture ([garethrandall](https://github.com/garethrandall))
* [#110](https://github.com/JasonRivers/Docker-Nagios/pull/110) - Update to Ubuntu 18.04 LTS ([asimzeeshan](https://github.com/asimzeeshan))
* [#112](https://github.com/JasonRivers/Docker-Nagios/pull/112) - Add python3-nagiosplugin for plugins that need it ([davralin](https://github.com/davralin))
* [#116](https://github.com/JasonRivers/Docker-Nagios/pull/116) - Update Nagios to 4.4.6 ([mmerian](https://github.com/mmerian))
* [#120](https://github.com/JasonRivers/Docker-Nagios/pull/120) - Add NSCA ([mmerian](https://github.com/mmerian))
* [#130](https://github.com/JasonRivers/Docker-Nagios/issues/130) - Add Perl encryption libraries ([rehashedsalt](https://github.com/rehashedsalt))
* [#132](https://github.com/JasonRivers/Docker-Nagios/issues/132) - Add rSync ([LutzLegu](https://github.com/LutzLegu))
* [#165](https://github.com/JasonRivers/Docker-Nagios/pull/165) - Added libcrypt-x509-per and libtext-glob-perl modules ([Scott-Jones-COS](https://github.com/Scott-Jones-COS))

## Changes That I've Made

Things that I have changed/updated/added to date:

* Updated the image to Ubuntu 26.04 LTS
* Updated Nagios Core to the current latest
* Updated Nagios Plugins to current latest
* Updated NRPE to current latest
* Updated NCPA to current latest
* Updated NSCA to current latest
* Added NagiosTV
* Built multi-arch images (amd64 & arm64)
* Implemented multi-stage build to reduce the final image size by nearly 60%

## Information

Nagios Core running on Ubuntu 26.04 LTS with NagiosGraph, NRPE, NCPA, NSCA, and NagiosTV.

| Product | Version |
| ------- | ------- |
| [Nagios Core](https://github.com/NagiosEnterprises/nagioscore/releases) | 4.5.14 |
| [Nagios Plugins](https://github.com/nagios-plugins/nagios-plugins) | 2.5 |
| [NRPE](https://github.com/NagiosEnterprises/nrpe) | 4.1.3 |
| [NCPA](https://github.com/NagiosEnterprises/ncpa) | 3.5.0 |
| [NSCA](https://github.com/NagiosEnterprises/nsca) | 2.10.3 |
| [NagiosTV](https://github.com/chriscareycode/nagiostv-react) | 0.9.11 |

The images can be found on the [Docker Hub Registry](https://hub.docker.com/r/tronyx/nagios) or the [GitHub Registry](https://github.com/tronyx/Docker-Nagios/pkgs/container/nagios).

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
| Master | `latest`, `master`, `master-<nagios version>` | Master branch that is known to be stable. |
| Develop | `develop`, `develop-<nagios version>` | My testing/development branch for updates. |

I may spawn other branches for testing from time to time, IE: new Ubuntu LTS or something similar, but for the most part these are the main branches.

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

When bind mounting host directories, empty `etc`/`var` directories are populated with the default configuration on first start, and the Nagios and NagiosGraph directories are chowned to the container's `nagios` user (UID/GID `5000`) on every start.

### Using Docker Compose

An example [docker-compose.yml](docker-compose.yml) is included that uses named volumes by default, with a commented-out bind mount alternative:

```bash
docker compose up -d
```

There are a number of environment variables that you can use to adjust the behaviour of the container:

| Environment Variable | Description |
| -------- | -------- |
| MAIL_RELAY_HOST | Set Postfix relayhost |
| MAIL_RELAY_USERNAME | Set username for Postfix relayhost (requires `MAIL_RELAY_HOST`); if present, will force TLS on relayhost connections, remember to add port 587 to your MAIL_RELAY_HOST value if you are using the 'submission' port/service |
| MAIL_RELAY_PASSWORD | Set password for Postfix relayhost |
| MAIL_INET_PROTOCOLS | Set the inet_protocols in Postfix |
| NAGIOS_FQDN | Set the server Fully Qualified Domain Name used by Postfix and as Apache's `ServerName` (default `nagios.example.com`) |
| NAGIOS_TIMEZONE | Set the timezone of the server (default `UTC`). Written to `use_timezone` in `nagios.cfg` on every start, so it overrides any manual edit of that setting |
| NAGIOSADMIN_USER | Web interface admin username, used only when `htpasswd.users` is first created (default `nagiosadmin`) |
| NAGIOSADMIN_PASS | Web interface admin password, used only when `htpasswd.users` is first created (default `nagios`) |

For the best results your Nagios container should have access to both IPv4 & IPv6 networks.

### Credentials

The default credentials for the web interface are:

| Username | Password |
| -------- | -------- |
| `nagiosadmin` | `nagios` |

`NAGIOSADMIN_USER`/`NAGIOSADMIN_PASS` only seed `/opt/nagios/etc/htpasswd.users` the first time the container starts (i.e. when that file doesn't already exist, such as on a fresh named volume or empty bind mount). Changing these env vars on a container that already has a populated `etc` volume has no effect on the stored password.

To change the password on an existing container:

```bash
docker exec -it nagios htpasswd -b /opt/nagios/etc/htpasswd.users nagiosadmin '<new-password>'
```

### Health Check

The image defines a Docker `HEALTHCHECK` that reports unhealthy unless both of the following succeed:

* Apache answers an HTTP request on `http://localhost/` — any response counts, including a 401/403, since the check only cares that Apache itself is up and processing requests.
* `runit` reports the `nagios` service as up (`sv check /etc/service/nagios`).

### Extra Plugins

| Name/Link | Description |
| -------- | -------- |
| [Nagios NRPE](http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details) | Remotely execute Nagios plugins on other Linux/Unix machines |
| [Nagios NCPA](https://exchange.nagios.org/directory/Addons/Monitoring-Agents/NCPA/details) | Cross-platform monitoring agent |
| [Nagios NSCA](https://exchange.nagios.org/directory/Addons/Passive-Checks/NSCA--2D-Nagios-Service-Check-Acceptor/details) | Integrate passive alerts and checks from remote machines and applications |
| [Nagiosgraph](http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details) | Displays data in Nagios trends, as popups for hosts and services |
| [JR-Nagios-Plugins](https://github.com/JasonRivers/nagios-plugins) | Custom plugins from Jason Rivers |
| [WL-Nagios-Plugins](https://github.com/willixix/WL-NagiosPlugins) | Custom plugins from William Leibzon |
| [JE-Nagios-Plugins](https://github.com/justintime/nagios-plugins) | Custom plugins from Justin Ellison |
| [DF-Nagios-Plugins](https://github.com/danfruehauf/nagios-plugins) | Custom plugins from Dan Fruehauf (`check_sql`, `check_jenkins`, `check_vpn`) |
| [check_mssql_collection](https://github.com/NagiosEnterprises/check_mssql_collection) | MSSQL database and server checks from Nagios Enterprises |
| [check_nwc_health](https://github.com/lausser/check_nwc_health) | Network component (switch, router, firewall) checks from Gerhard Lausser |
| [check_apc.pl](plugins/check_apc.pl) | APC UPS checks via SNMP |
| [QStat](https://github.com/multiplay/qstat) | Game server status query tool, installed at `/usr/local/bin/qstat` and used by the `check_game` plugin |
| [check-mqtt](https://github.com/jpmens/check-mqtt.git) | Custom plugin for mqtt monitoring from Jan-Piet Mens |
| [NagiosTV](https://github.com/chriscareycode/nagiostv-react) | Monitor your Nagios server on a wall-mounted TV |
