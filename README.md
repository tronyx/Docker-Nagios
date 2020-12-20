# Docker-Nagios

Fork of [JasonRivers Docker Nagios image](https://github.com/JasonRivers/Docker-Nagios) to incorporate various improvements from the open PRs on his repo. I have incorporated the following PRs:

[#116](https://github.com/JasonRivers/Docker-Nagios/pull/116)
[#112](https://github.com/JasonRivers/Docker-Nagios/pull/112)
[#110](https://github.com/JasonRivers/Docker-Nagios/pull/110)
[#101](https://github.com/JasonRivers/Docker-Nagios/pull/101)
[#96](https://github.com/JasonRivers/Docker-Nagios/pull/96)
[#72](https://github.com/JasonRivers/Docker-Nagios/pull/72)

Listing these as I wish to give the original users credit for their work.

Build Status: [![Build Status](https://www.travis-ci.com/tronyx/Docker-Nagios.svg?branch=master)](https://www.travis-ci.com/tronyx/Docker-Nagios)

Nagios Core 4.4.6 running on Ubuntu 18.04 LTS with NagiosGraph, NRPE, & NSCA

### Configurations
Nagios Configuration lives in /opt/nagios/etc
NagiosGraph configuration lives in /opt/nagiosgraph/etc

### Install

```sh
docker pull tronyx/nagios:latest
```

### Running

Run with the example configuration with the following:

```sh
docker run --name nagios -p 0.0.0.0:8080:80 tronyx/nagios:latest
```

alternatively you can use external Nagios configuration & log data with the following:

```sh
docker run --name nagios  \
  -v /path-to-nagios/etc/:/opt/nagios/etc/ \
  -v /path-to-nagios/var:/opt/nagios/var/ \
  -v /path-to-custom-plugins:/opt/Custom-Nagios-Plugins \
  -v /path-to-nagiosgraph-var:/opt/nagiosgraph/var \
  -v /path-to-nagiosgraph-etc:/opt/nagiosgraph/etc \
  -p 0.0.0.0:8080:80 tronyx/nagios:latest
```

Note: The path for the custom plugins will be /opt/Custom-Nagios-Plugins, you will need to reference this directory in your configuration scripts.

There are a number of environment variables that you can use to adjust the behaviour of the container:

| Environamne Variable | Description |
|--------|--------|
| MAIL_RELAY_HOST | Set Postfix relayhost |
| MAIL_INET_PROTOCOLS | set the inet_protocols in postfix |
| NAGIOS_FQDN | set the server Fully Qualified Domain Name in postfix |
| NAGIOS_TIMEZONE | set the timezone of the server |

For best results your Nagios image should have access to both IPv4 & IPv6 networks

#### Credentials

The default credentials for the web interface is `nagiosadmin` / `nagios`

### Extra Plugins

* Nagios NRPE [<http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details>]
* Nagios NSCA [<https://exchange.nagios.org/directory/Addons/Passive-Checks/NSCA--2D-Nagios-Service-Check-Acceptor/details>]
* Nagiosgraph [<http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details>]
* JR-Nagios-Plugins -  custom plugins @JasonRivers created [<https://github.com/JasonRivers/nagios-plugins>]
* WL-Nagios-Plugins -  custom plugins from William Leibzon [<https://github.com/willixix/WL-NagiosPlugins>]
* JE-Nagios-Plugins -  custom plugins from Justin Ellison [<https://github.com/justintime/nagios-plugins>]


