# 📜 Changelog

The notable changes to the Docker-Nagios image, newest first.

The project doesn't use version numbers of its own. Each entry is one merge into `master`, which is published as `latest`, and links to its pull request for the full details. Changes waiting on `develop` are listed under **Unreleased**.

## Unreleased

Nothing yet.

## 2026-10-06 · [#62](https://github.com/tronyx/Docker-Nagios/pull/62)

### Security

- The image is rebuilt on the current `ubuntu:26.04` base with updated packages, fixing CVE-2026-42772 and CVE-2026-54873 in OpenSSL (`openssl`, `libssl3t64` and `openssl-provider-legacy` 3.5.5-1ubuntu3.6 → 3.5.5-1ubuntu3.7, low) and CVE-2026-94287 in `libxpm4` (1:3.5.17-1ubuntu0.26.04.1 → 1:3.5.17-1ubuntu0.26.04.2, medium).

### Changed

- `check_nwc_health` is updated to the latest upstream commit.

### Project

- The `update-pins` workflow never refreshed the base image digest. The script stopped silently while looking it up in CI (`awk` quitting early killed `docker buildx imagetools inspect`, and `pipefail` with `set -e` ended the script without a message), and the step still passed because its shell had no `pipefail`, so a pull request was opened with only the pins changed before that point and an empty summary. The script now asks buildx for the digest directly, and the step fails if the script does.
- `develop` is now the repository's default branch, so scheduled and manually started workflows run from it. The README's build badge shows `master`'s status, since that's what `latest` is built from.

## 2026-10-05 · [#60](https://github.com/tronyx/Docker-Nagios/pull/60)

### Fixed

- After `docker restart` (or `docker stop` and `docker start`), NSCA and Apache could get stuck restarting, logging `There's already an NSCA server running (PID 21). Bailing out...` and `httpd (pid 19) already running` over and over. A restart keeps the container's files, including their PID files in `/run`, and the new start reuses the same low process IDs, so a leftover PID file could point at a different, running service. Leftover PID files are now removed at startup, before any service starts. A container recreated with `docker compose up` was never affected.

### Project

- The smoke test also restarts the container with stale PID files in place and checks that it comes back healthy with no service restart-looping.

## 2026-09-30 · [#59](https://github.com/tronyx/Docker-Nagios/pull/59)

### Project

- The README notes that `update-pins` needs `peter-evans/create-pull-request` allowed when the repository restricts which actions can run.

## 2026-09-30 · [#58](https://github.com/tronyx/Docker-Nagios/pull/58)

### Changed

- **There's no default admin password any more.** On first start, the web interface password comes from `NAGIOSADMIN_PASS_FILE` (for Docker secrets) or `NAGIOSADMIN_PASS`; with neither set, a random one is generated and printed in the container log. An existing `htpasswd.users` is left as it is.
- `NAGIOS_TIMEZONE` and `NAGIOS_FQDN` are applied when the container starts instead of when the image is built, so setting them on `docker run` now takes effect.
- The container shuts down cleanly within a few seconds, well inside Docker's 10-second stop timeout, and exits with code 0.
- NCPA is updated to 3.5.0.
- The final image has 22 layers instead of 37.

### Added

- `check_nwc_health`, with its Perl dependencies (thanks to [FliesLikeABrick](https://github.com/FliesLikeABrick), [#55](https://github.com/tronyx/Docker-Nagios/pull/55)).
- Authenticated SMTP relays with TLS, set with `MAIL_RELAY_HOST`, `MAIL_RELAY_USERNAME` and `MAIL_RELAY_PASSWORD`, for sending notifications through a mail service (thanks to [FliesLikeABrick](https://github.com/FliesLikeABrick)). The credentials are kept in a separate, root-only file rather than Postfix's world-readable `main.cf`.
- Apache's `authnz_ldap` module is enabled, for LDAP logins in a customised site configuration (thanks to [FliesLikeABrick](https://github.com/FliesLikeABrick), [#54](https://github.com/tronyx/Docker-Nagios/pull/54)).
- `check_mysql` and `check_mysql_query`.
- `check_radius` is back. Nagios Plugins can't build it on Ubuntu 26.04, so the image includes Ubuntu's build from Monitoring Plugins instead; the README's new "Using check_radius" section shows how to set it up.
- `python-is-python3`, so plugins whose first line asks for `python` run.

### Fixed

- `check_game` wasn't built, because QStat was built after Nagios Plugins.
- A custom `NAGIOSADMIN_USER` could log in but had none of the admin permissions, which `cgi.cfg` gave to `nagiosadmin` only. They're now given to the configured user on first start.
- Without an `nsca.cfg`, the NSCA service restarted every second. It now stays idle until there is one.
- SMTP relay authentication didn't work on arm64, which was missing the SASL modules.
- NagiosGraph's multi-select fix wasn't applied to the default configuration, and its fallback for a missing `ngshared.pm` was broken. It's now restored from the image's copy.
- `check_icmp` could stop working when the plugin folder's owner was changed at startup.
- runit's `svlogd` template was being started as a service.

### Security

- Passwords are stored with bcrypt instead of unsalted SHA-1, and passed to `htpasswd` on its input instead of its command line, where other processes could see them. This applies when `htpasswd.users` is first created; an existing file isn't converted.
- Apache no longer shows its version in response headers and error pages. The README's new "Reverse Proxy and TLS" section covers serving the web interface over HTTPS.
- Binaries, CGIs, plugins and web files are owned by root, so the `nagios` user can only write to its configuration and data.
- The unused `xinetd` and `snmpd` packages are removed, and `ping` no longer has an unnecessary setuid bit.
- Published images carry an SBOM and build provenance.

### Project

- Every upstream source is pinned: git sources to an exact commit (tagged releases are checked against their tag, so a moved tag fails the build), the Ubuntu base image to its digest, downloads to a SHA-256 checksum, and the Python plugin packages, with their dependencies, to versions and hashes in `requirements.txt`. `scripts/update-pinned-checksums.sh` refreshes them, and the `update-pins` workflow runs it every other week and opens a pull request against `develop`.
- Every image is smoke-tested (`scripts/smoke-test.sh`) on both architectures before it's published: logins, the web interface, key plugins, file permissions and a clean shutdown.
- Every image is scanned with Trivy, with the results in the repository's Code scanning page. An image with a fixable critical vulnerability isn't published. A weekly `scan` workflow also rescans the published `master` and `develop` images.
- A `lint` workflow checks the Dockerfile (hadolint), the shell scripts (shellcheck) and the workflows (actionlint).
- The amd64 and arm64 Dockerfiles are merged into one `Dockerfile`.
- The build cache is kept in the GitHub Actions cache instead of a `tronyx/docker-nagios` repository on Docker Hub, and `[no-cache]` in a pushed commit's message rebuilds everything from scratch.
- Workflow tokens get only the permissions they need, GHCR is pushed to with the built-in token instead of a personal access token, buildx and BuildKit are pinned to released versions, and the Nagios components build with parallel `make`.
- Pull requests are built and tested but don't push images or cache.
- Stale-closed issues are locked by the `stale` workflow.
- The README is rewritten, with sections on credentials, `check_radius`, running behind a reverse proxy, and maintaining the image.

## 2026-09-03 · [#52](https://github.com/tronyx/Docker-Nagios/pull/52)

### Changed

- **The image is based on Ubuntu 26.04 LTS.**
- Nagios Core is updated to 4.5.14, Nagios Plugins to 2.5, NCPA to 3.4.3 and NagiosTV to 0.9.11.
- The image is built in stages, so build tools and sources stay out of the final image, cutting its size by nearly 60%.
- The NagiosTV and NCPA downloads are checked against SHA-256 checksums, and the Python plugin packages are pinned to versions.

### Added

- A Docker health check, which doesn't depend on the web interface credentials.

### Fixed

- Postfix couldn't start in its chroot.

### Project

- arm64 images are built on GitHub's arm64 runners instead of under QEMU emulation, with a build cache.
- The unsupported arm-v7 Dockerfile is removed.

## 2025-07-24 · [#45](https://github.com/tronyx/Docker-Nagios/pull/45)

### Fixed

- The NSCA build downloads `config.guess` and `config.sub` from Savannah's git server instead of its old CVS address.

## 2025-07-23 · [#44](https://github.com/tronyx/Docker-Nagios/pull/44)

### Changed

- Nagios Core is updated to 4.5.9, NRPE to 4.1.3, NCPA to 3.1.3 and NagiosTV to 0.9.5.

### Project

- A `stale` workflow marks and closes inactive issues.

## Earlier

Changes before July 2025 are listed in the [merged pull requests](https://github.com/tronyx/Docker-Nagios/pulls?q=is%3Apr+is%3Amerged+base%3Amaster).
