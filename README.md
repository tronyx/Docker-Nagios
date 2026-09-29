# Docker-Nagios

![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/tronyx/Docker-Nagios/build.yml) [![CodeFactor](https://www.codefactor.io/repository/github/tronyx/docker-nagios/badge)](https://www.codefactor.io/repository/github/tronyx/docker-nagios) [![Docker Pulls](https://img.shields.io/docker/pulls/tronyx/nagios.svg)](https://hub.docker.com/r/tronyx/nagios) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/tronyx/nagios?arch=amd64&label=amd64) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/tronyx/nagios?arch=arm64&label=arm64) [![GitHub](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/tronyx/Docker-Nagios/blob/master/LICENSE.md)

## 📝 Notes

A fork of [JasonRivers' Docker Nagios image](https://github.com/JasonRivers/Docker-Nagios) that pulls in fixes from the open pull requests on his repo, along with other updates and quality-of-life improvements.

## 🙏 Incorporated PRs

Listed here to give the original authors credit for their work.

* [#96](https://github.com/JasonRivers/Docker-Nagios/pull/96) - Fix issue with Nagiosgraph source ([fregge](https://github.com/fregge))
* [#101](https://github.com/JasonRivers/Docker-Nagios/pull/101) - Fixes to allow building on ARM aarch64 architecture ([garethrandall](https://github.com/garethrandall))
* [#110](https://github.com/JasonRivers/Docker-Nagios/pull/110) - Update to Ubuntu 18.04 LTS ([asimzeeshan](https://github.com/asimzeeshan))
* [#112](https://github.com/JasonRivers/Docker-Nagios/pull/112) - Add python3-nagiosplugin for plugins that need it ([davralin](https://github.com/davralin))
* [#116](https://github.com/JasonRivers/Docker-Nagios/pull/116) - Update Nagios to 4.4.6 ([mmerian](https://github.com/mmerian))
* [#120](https://github.com/JasonRivers/Docker-Nagios/pull/120) - Add NSCA ([mmerian](https://github.com/mmerian))
* [#130](https://github.com/JasonRivers/Docker-Nagios/issues/130) - Add Perl encryption libraries ([rehashedsalt](https://github.com/rehashedsalt))
* [#132](https://github.com/JasonRivers/Docker-Nagios/issues/132) - Add rsync ([LutzLegu](https://github.com/LutzLegu))
* [#165](https://github.com/JasonRivers/Docker-Nagios/pull/165) - Added libcrypt-x509-perl and libtext-glob-perl modules ([Scott-Jones-COS](https://github.com/Scott-Jones-COS))

## ✨ Changes That I've Made

Things that I have changed/updated/added to date:

* Updated the image to Ubuntu 26.04 LTS
* Updated Nagios Core, Nagios Plugins, NRPE, NCPA and NSCA to their latest releases
* Added NagiosTV
* Added `check_mysql` and `check_mysql_query`, kept `check_radius` working on Ubuntu 26.04, and fixed `check_game` not being built
* Built multi-arch images (amd64 & arm64)
* Switched to a multi-stage build, cutting the image size by nearly 60%
* Removed the default web interface password: set your own, or a random one is generated on first start
* Switched stored passwords from unsalted SHA-1 to bcrypt
* Gave a custom `NAGIOSADMIN_USER` full admin access in the web interface
* Applied `NAGIOS_TIMEZONE` and `NAGIOS_FQDN` at startup instead of at build time
* Fixed SMTP relay authentication
* Made the container shut down cleanly within a few seconds
* Hardened the image: binaries and web files are owned by root, and Apache no longer shows its version
* Pinned every upstream source to an exact version, with a workflow that refreshes the pins every other week
* Added CI that lints, smoke-tests and scans every image for vulnerabilities before publishing it, with SBOM and provenance attestations attached

## ℹ️ Information

Nagios Core running on Ubuntu 26.04 LTS with NagiosGraph, NRPE, NCPA, NSCA and NagiosTV.

| Product | Version |
| ------- | ------- |
| [Nagios Core](https://github.com/NagiosEnterprises/nagioscore/releases) | 4.5.14 |
| [Nagios Plugins](https://github.com/nagios-plugins/nagios-plugins) | 2.5 |
| [NRPE](https://github.com/NagiosEnterprises/nrpe) | 4.1.3 |
| [NCPA](https://github.com/NagiosEnterprises/ncpa) | 3.5.0 |
| [NSCA](https://github.com/NagiosEnterprises/nsca) | 2.10.3 |
| [NagiosTV](https://github.com/chriscareycode/nagiostv-react) | 0.9.11 |

All of the standard Nagios Plugins are included, plus the extras listed under [Extra Plugins](#-extra-plugins).

> [!NOTE]
> `check_radius` is the one exception: Nagios Plugins can't build it on Ubuntu 26.04, so the image includes Ubuntu's build of it from the sister project, Monitoring Plugins, instead. See [Using check_radius](#-using-check_radius) to set it up.

### ⚙️ Configuration

* Nagios and NSCA: `/opt/nagios/etc`
* NagiosGraph: `/opt/nagiosgraph/etc`
* Your own plugins: `/opt/Custom-Nagios-Plugins` (use this path in your command definitions)

### 🐳 Docker

The images are available on [Docker Hub](https://hub.docker.com/r/tronyx/nagios) and the [GitHub Container Registry](https://github.com/tronyx/Docker-Nagios/pkgs/container/nagios):

```bash
docker pull tronyx/nagios
docker pull ghcr.io/tronyx/nagios
```

#### 🏷️ Tags

| Branch | Image Tag | Notes |
| ------- | ------- | ------- |
| Master | `latest`, `master`, `master-<nagios version>` | Stable. |
| Develop | `develop`, `develop-<nagios version>` | My testing/development branch for updates. |

I occasionally create other branches for testing, such as for a new Ubuntu LTS release, but these two are the main ones.

#### 🚀 Running the Container

To try it out with the example configuration:

```bash
docker run --name nagios -p 8080:80 tronyx/nagios
```

> [!TIP]
> Then open `http://localhost:8080/nagios/` and log in as `nagiosadmin`, using the password from the container log (see [Credentials](#-credentials)).

To keep your configuration and data outside the container, mount host directories:

```bash
docker run --name nagios \
  -v /path/to/nagios/etc:/opt/nagios/etc \
  -v /path/to/nagios/var:/opt/nagios/var \
  -v /path/to/custom-plugins:/opt/Custom-Nagios-Plugins \
  -v /path/to/nagiosgraph/etc:/opt/nagiosgraph/etc \
  -v /path/to/nagiosgraph/var:/opt/nagiosgraph/var \
  -p 8080:80 tronyx/nagios
```

Empty directories are filled with the default configuration on first start, and the Nagios and NagiosGraph directories are handed to the container's `nagios` user (UID/GID `5000`) on every start.

A few more options:

* To use the GitHub image, replace `tronyx/nagios` with `ghcr.io/tronyx/nagios`.
* To accept passive check results from remote hosts via NSCA, also publish its port with `-p 5667:5667`.
* For best results, give the container access to both IPv4 and IPv6 networks.

#### 🧩 Using Docker Compose

The included [docker-compose.yml](docker-compose.yml) uses named volumes by default, with a commented-out bind mount alternative and examples for setting the admin password:

```bash
docker compose up -d
```

#### 🔧 Environment Variables

| Variable | Description |
| -------- | -------- |
| `MAIL_RELAY_HOST` | Postfix relay host for outgoing mail. Include the port if it isn't 25, e.g. `smtp.example.com:587` |
| `MAIL_RELAY_USERNAME` | Username for the relay host (requires `MAIL_RELAY_HOST`). Setting it also forces TLS to the relay |
| `MAIL_RELAY_PASSWORD` | Password for the relay host |
| `MAIL_INET_PROTOCOLS` | Postfix's `inet_protocols` setting, e.g. `ipv4` |
| `NAGIOS_FQDN` | The server's fully qualified domain name, used by Postfix and as Apache's `ServerName` (default `nagios.example.com`) |
| `NAGIOS_TIMEZONE` | Timezone (default `UTC`). Written to `nagios.cfg` on every start, so it overrides any `use_timezone` you set there |
| `NAGIOSADMIN_USER` | Web interface admin username (default `nagiosadmin`). Only used on first start |
| `NAGIOSADMIN_PASS` | Web interface admin password. Only used on first start, and has no default (see [Credentials](#-credentials)) |
| `NAGIOSADMIN_PASS_FILE` | Path to a file containing the admin password, such as a Docker secret. Takes precedence over `NAGIOSADMIN_PASS` |

### 🔑 Credentials

> [!IMPORTANT]
> There's no default password. If you don't set one, a random password is generated on first start and printed in the container log.

On first start, the login for `NAGIOSADMIN_USER` (default `nagiosadmin`) gets its password from the first of these that's set:

1. The file named by `NAGIOSADMIN_PASS_FILE`
2. `NAGIOSADMIN_PASS`
3. If neither is set, a random password is generated and printed once in the container log:

```bash
$ docker logs nagios 2>&1 | grep 'Generated password'
Generated password for nagiosadmin: ddUoZ0rcvn4qe6sbami72LGTVnk3vt
```

With Docker Compose, a secret keeps the password out of the container's environment, where `docker inspect` would show it:

```yaml
services:
  nagios:
    environment:
      NAGIOSADMIN_PASS_FILE: /run/secrets/nagiosadmin_pass
    secrets:
      - nagiosadmin_pass

secrets:
  nagiosadmin_pass:
    file: ./nagiosadmin_pass.txt
```

> [!NOTE]
> These settings are only read when `/opt/nagios/etc/htpasswd.users` doesn't exist yet, such as on a fresh volume. Changing them later has no effect, so existing installs keep their current password.

To change the password later (it prompts for the new one):

```bash
docker exec -it nagios htpasswd -B /opt/nagios/etc/htpasswd.users nagiosadmin
```

This also upgrades a password set by an older version of the image to the stronger bcrypt format.

### 📡 Using check_radius

`check_radius` comes from Ubuntu's Monitoring Plugins package, built against [radcli](https://github.com/radcli/radcli), because Nagios Plugins can't build it on Ubuntu 26.04. It takes the same options as before, but needs a radcli configuration listing your RADIUS servers. Copy the default one into your `etc` volume once:

```bash
docker exec nagios sh -c 'cp -r /etc/radcli /opt/nagios/etc/radcli && sed -i "s|/etc/radcli/|/opt/nagios/etc/radcli/|" /opt/nagios/etc/radcli/radiusclient.conf && chown -R nagios:nagios /opt/nagios/etc/radcli && chmod 600 /opt/nagios/etc/radcli/servers'
```

Then add your servers and shared secrets to `/opt/nagios/etc/radcli/servers`, and pass `-F /opt/nagios/etc/radcli/radiusclient.conf` to `check_radius`.

### 🔒 Reverse Proxy and TLS

> [!WARNING]
> The container serves plain HTTP on port 80, and the web interface uses Basic authentication, which sends your password with every request. If it's reachable from anywhere other than a trusted local network, put it behind a reverse proxy that handles TLS, such as Traefik, nginx, Caddy or SWAG.

When setting up the proxy:

* Proxy a whole hostname, e.g. `https://nagios.example.com/`, not a sub-path. Nagios, NagiosGraph and NagiosTV use the absolute paths `/nagios/`, `/cgi-bin/` and `/nagiostv/`.
* Set `NAGIOS_FQDN` to that hostname.
* If the proxy reaches the container over a Docker network, you don't need to publish port 80 on the host.

### 🩺 Health Check

The image's Docker health check reports healthy when Apache is answering requests and Nagios is running. It doesn't log in, so it works whatever password you set.

### 🔌 Extra Plugins

| Name/Link | Description |
| -------- | -------- |
| [Nagios NRPE](http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details) | Remotely execute Nagios plugins on other Linux/Unix machines |
| [Nagios NCPA](https://exchange.nagios.org/directory/Addons/Monitoring-Agents/NCPA/details) | Cross-platform monitoring agent |
| [Nagios NSCA](https://exchange.nagios.org/directory/Addons/Passive-Checks/NSCA--2D-Nagios-Service-Check-Acceptor/details) | Integrate passive alerts and checks from remote machines and applications |
| [NagiosGraph](http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details) | Graphs performance data from your checks, shown as popups for hosts and services |
| [JR-Nagios-Plugins](https://github.com/JasonRivers/nagios-plugins) | Custom plugins from Jason Rivers |
| [WL-Nagios-Plugins](https://github.com/willixix/naglio-plugins) | Custom plugins from William Leibzon |
| [JE-Nagios-Plugins](https://github.com/justintime/nagios-plugins) | Custom plugins from Justin Ellison |
| [DF-Nagios-Plugins](https://github.com/danfruehauf/nagios-plugins) | Custom plugins from Dan Fruehauf (`check_sql`, `check_jenkins`, `check_vpn`) |
| [check_mssql_collection](https://github.com/NagiosEnterprises/check_mssql_collection) | MSSQL database and server checks from Nagios Enterprises |
| [check_nwc_health](https://github.com/lausser/check_nwc_health) | Network component (switch, router, firewall) checks from Gerhard Lausser |
| [check_apc.pl](plugins/check_apc.pl) | APC UPS checks via SNMP |
| [QStat](https://github.com/multiplay/qstat) | Game server status query tool, installed at `/usr/local/bin/qstat` and used by the `check_game` plugin |
| [check-mqtt](https://github.com/jpmens/check-mqtt) | MQTT broker checks from Jan-Piet Mens |
| [NagiosTV](https://github.com/chriscareycode/nagiostv-react) | Monitor your Nagios server on a wall-mounted TV |

## 🛠️ Maintaining the Image

Every upstream source is pinned to an exact version: git repositories to a commit (the `*_COMMIT` build args), the Ubuntu base image to a digest (`BASE_IMAGE`), and downloaded files to a SHA-256 checksum. Tagged releases are also checked at build time, so the build fails if a tag has been moved.

* **Updating pins:** run [scripts/update-pinned-checksums.sh](scripts/update-pinned-checksums.sh), which needs `git`, `curl` and `docker buildx`. It updates the [Dockerfile](Dockerfile) and summarises what changed; review the diff before committing. The `update-pins` workflow runs it every other week and opens a pull request against `develop`.
* **Bumping a component:** change its `*_VERSION` build arg (e.g. `NAGIOS_VERSION`) in the Dockerfile, then run the script to update its commit and checksums.
* **Updating CI tools:** buildx, BuildKit and Trivy (in `build.yml`) and hadolint, shellcheck and actionlint (in `lint.yml`) are pinned by hand, and the script doesn't update them. Bump them now and then.
* **Testing an image:** `scripts/smoke-test.sh <image>` starts the image and checks logins, the web interface, key plugins, file permissions and a clean shutdown. CI runs it on every build before anything is published.

> [!NOTE]
> GitHub only runs scheduled and manually triggered workflows from the default branch, so `update-pins` starts working once it's on `master`; until then, run the script by hand. It also needs "Allow GitHub Actions to create and approve pull requests" enabled under Settings → Actions → General.
