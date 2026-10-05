#!/usr/bin/env bash
# Starts the given image and checks that Nagios, the web UI, key plugins and file permissions
# work, then that it shuts down cleanly. Usage: scripts/smoke-test.sh <image>
# Single-quoted commands are run inside the container, so they must not expand here.
# shellcheck disable=SC2016
set -uo pipefail

image=${1:?usage: $0 <image>}
name=nagios-smoke-$$
# Started with no password at all, to check one is generated and logged
gen_name=$name-generated
# Not the default nagiosadmin, so the cgi.cfg permission hand-off is exercised too
user=smokeadmin
password=smoke-$RANDOM$RANDOM
pass_file=$(mktemp)
printf '%s\n' "$password" > "$pass_file"
pass=0
fail=0

cleanup() { docker rm -f "$name" "$gen_name" >/dev/null 2>&1; rm -f "$pass_file"; }
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

wait_healthy() {
    for _ in $(seq 1 40); do
        status=$(docker inspect -f '{{.State.Health.Status}}' "$name" 2>/dev/null)
        [ "$status" = healthy ] || [ "$status" = unhealthy ] && break
        sleep 3
    done
}

docker run -d --name "$name" -e NAGIOSADMIN_USER="$user" -e NAGIOSADMIN_PASS_FILE=/run/secrets/nagiosadmin_pass \
    -v "$pass_file:/run/secrets/nagiosadmin_pass:ro" "$image" >/dev/null
docker run -d --name "$gen_name" "$image" >/dev/null

echo "Waiting for $image to become healthy..."
wait_healthy
check "container is healthy" [ "$status" = healthy ]

check "all runit services are up" in_container \
    'for s in /etc/service/*/; do [ -x "$s/run" ] || continue; sv status "$s" | grep -q "^run:" || exit 1; done'
check "nagios -v accepts the config" in_container '/opt/nagios/bin/nagios -v /opt/nagios/etc/nagios.cfg'

check "/nagios/ requires authentication" http_is 401 http://localhost/nagios/
check "admin password is stored as bcrypt" in_container 'grep -q "^[^:]*:[$]2y[$]" /opt/nagios/etc/htpasswd.users'
generated=$(docker logs "$gen_name" 2>&1 | sed -n 's/^Generated password for nagiosadmin: \([^ ]*\)$/\1/p')
check "a password is generated and logged when none is given" \
    docker exec "$gen_name" htpasswd -vb /opt/nagios/etc/htpasswd.users nagiosadmin "$generated"
docker rm -f "$gen_name" >/dev/null 2>&1
check "/nagios/ loads with credentials" http_is 200 -u "$user:$password" http://localhost/nagios/
check "status.cgi loads" http_is 200 -u "$user:$password" http://localhost/nagios/cgi-bin/status.cgi
check "admin user is authorized to see all hosts" \
    sh -c "docker exec '$name' curl -s -u '$user:$password' 'http://localhost/nagios/cgi-bin/status.cgi?host=all' | grep -q 'host=localhost'"
check "NagiosGraph show.cgi loads" http_is 200 -u "$user:$password" http://localhost/cgi-bin/show.cgi
check "NagiosTV loads" http_is 200 -u "$user:$password" http://localhost/nagiostv/
check "Apache hides its version" in_container \
    '[ "$(curl -sI http://localhost/ | tr -d "\r" | sed -n "s/^Server: //p")" = Apache ] && ! curl -s http://localhost/no-such-page | grep -q "<address>"'

check "check_icmp works as nagios" as_nagios '/opt/nagios/libexec/check_icmp -H 127.0.0.1'
check "check_ping works as nagios" as_nagios '/opt/nagios/libexec/check_ping -H 127.0.0.1 -w 100,20% -c 200,50%'
check "check_game is built" as_nagios '/opt/nagios/libexec/check_game --version | grep -q nagios-plugins'
check "check_mysql and check_mysql_query are built" as_nagios \
    '/opt/nagios/libexec/check_mysql --version | grep -q nagios-plugins && /opt/nagios/libexec/check_mysql_query --version | grep -q nagios-plugins'
check "check_radius runs" as_nagios '/opt/nagios/libexec/check_radius --version | grep -q monitoring-plugins'
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

log_lines=$(docker logs "$name" 2>&1 | wc -l)
docker start "$name" >/dev/null
wait_healthy
sleep 5
check "container is healthy after a restart" [ "$status" = healthy ]
check "no service restart-loops after a restart" \
    sh -c "! docker logs '$name' 2>&1 | tail -n +$((log_lines + 1)) | grep -Eq 'already running|Bailing out'"

echo
echo "$pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    echo "--- container log (last 40 lines) ---"
    docker logs --tail 40 "$name" 2>&1
    exit 1
fi
