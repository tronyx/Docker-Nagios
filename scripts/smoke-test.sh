#!/usr/bin/env bash
# Starts the given image and checks that Nagios, the web UI, key plugins and file permissions
# work, then that it shuts down cleanly. Usage: scripts/smoke-test.sh <image>
# Single-quoted commands are run inside the container, so they must not expand here.
# shellcheck disable=SC2016
set -uo pipefail

image=${1:?usage: $0 <image>}
name=nagios-smoke-$$
password=smoke-$RANDOM$RANDOM
pass=0
fail=0

cleanup() { docker rm -f "$name" >/dev/null 2>&1; }
trap cleanup EXIT

check() {
    local desc=$1
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS  $desc"
        pass=$((pass + 1))
    else
        echo "FAIL  $desc"
        fail=$((fail + 1))
    fi
}

in_container() { docker exec "$name" sh -c "$1"; }
as_nagios() { docker exec -u nagios "$name" sh -c "$1"; }

http_is() {
    local expected=$1
    shift
    [ "$(docker exec "$name" curl -s -o /dev/null -w '%{http_code}' "$@")" = "$expected" ]
}

docker run -d --name "$name" -e NAGIOSADMIN_PASS="$password" "$image" >/dev/null

echo "Waiting for $image to become healthy..."
for _ in $(seq 1 40); do
    status=$(docker inspect -f '{{.State.Health.Status}}' "$name" 2>/dev/null)
    [ "$status" = healthy ] || [ "$status" = unhealthy ] && break
    sleep 3
done
check "container is healthy" [ "$status" = healthy ]

check "all runit services are up" in_container \
    'for s in /etc/service/*/; do [ -x "$s/run" ] || continue; sv status "$s" | grep -q "^run:" || exit 1; done'
check "nagios -v accepts the config" in_container '/opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg'

check "/nagios/ requires authentication" http_is 401 http://localhost/nagios/
check "/nagios/ loads with credentials" http_is 200 -u "nagiosadmin:$password" http://localhost/nagios/
check "status.cgi loads" http_is 200 -u "nagiosadmin:$password" http://localhost/nagios/cgi-bin/status.cgi
check "NagiosGraph show.cgi loads" http_is 200 -u "nagiosadmin:$password" http://localhost/cgi-bin/show.cgi
check "NagiosTV loads" http_is 200 -u "nagiosadmin:$password" http://localhost/nagiostv/

check "check_icmp works as nagios" as_nagios '/opt/nagios/libexec/check_icmp -H 127.0.0.1'
check "check_ping works as nagios" as_nagios '/opt/nagios/libexec/check_ping -H 127.0.0.1 -w 100,20% -c 200,50%'
check "check_game is built" as_nagios '/opt/nagios/libexec/check_game --version | grep -q nagios-plugins'
check "check_nrpe runs" as_nagios '/opt/nagios/libexec/check_nrpe --help | grep -q NRPE'
check "check_ncpa.py runs" as_nagios '/opt/nagios/libexec/check_ncpa.py --help'
check "check_mssql_server.py runs" as_nagios '/opt/nagios/libexec/check_mssql_server.py --help'
check "check-mqtt.py runs" as_nagios '/opt/nagios/libexec/check-mqtt.py --help'
check "check_nwc_health runs" as_nagios '/opt/nagios/libexec/check_nwc_health --help | grep -q check_nwc_health'
check "Python plugin libraries import" as_nagios \
    'python3 -c "import nagiosplugin, pymssql, paho.mqtt.client, pywbem, paramiko, requests"'

check "check_icmp and check_dhcp are setuid root" in_container \
    'for p in check_icmp check_dhcp; do [ -u /opt/nagios/libexec/$p ] && [ "$(stat -c %U /opt/nagios/libexec/$p)" = root ] || exit 1; done'
check "nagios cannot write binaries, CGIs, plugins or web files" as_nagios \
    'for d in bin sbin libexec share; do [ ! -w /opt/nagios/$d ] || exit 1; done'
check "nagios can write its etc and var" as_nagios \
    'for d in /opt/nagios/etc /opt/nagios/var /opt/nagiosgraph/etc /opt/nagiosgraph/var; do [ -w "$d" ] || exit 1; done'

start=$(date +%s)
docker stop "$name" >/dev/null
elapsed=$(( $(date +%s) - start ))
check "docker stop finishes within 10s (took ${elapsed}s)" [ "$elapsed" -lt 10 ]
check "container exits with code 0" [ "$(docker inspect -f '{{.State.ExitCode}}' "$name")" = 0 ]

echo
echo "$pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    echo "--- container log (last 40 lines) ---"
    docker logs --tail 40 "$name" 2>&1
    exit 1
fi
