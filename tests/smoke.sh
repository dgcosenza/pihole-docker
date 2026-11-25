#!/usr/bin/env bash
# Smoke test for dgcosenza/pihole.
#
# Runs the image on a private port range, proves that DNS, the web interface,
# the healthcheck and the non-root service account work, and that the
# healthcheck fails closed. CI runs the same checks (.github/workflows/daily.yml).
#
# Usage: IMAGE=dgcosenza/pihole:latest tests/smoke.sh
set -euo pipefail

IMAGE="${IMAGE:-dgcosenza/pihole:latest}"
NAME="${NAME:-pihole-smoke}"
DNS_PORT="${DNS_PORT:-15353}"
WEB_PORT="${WEB_PORT:-18080}"
DATA="$(mktemp -d)"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  rm -rf "$DATA"
}
trap cleanup EXIT

chmod 777 "$DATA"
docker run -d --name "$NAME" \
  --security-opt no-new-privileges:true \
  -e TZ=UTC \
  -e FTLCONF_webserver_api_password=ci-smoke-password \
  -p "127.0.0.1:${DNS_PORT}:53/tcp" \
  -p "127.0.0.1:${DNS_PORT}:53/udp" \
  -p "127.0.0.1:${WEB_PORT}:80/tcp" \
  -v "$DATA/etc-pihole:/etc/pihole" \
  -v "$DATA/etc-dnsmasq.d:/etc/dnsmasq.d" \
  -v "$DATA/var-log-pihole:/var/log/pihole" \
  "$IMAGE"

echo "== waiting for healthcheck"
for i in $(seq 1 60); do
  status="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$NAME")"
  [ "$status" = "healthy" ] && break
  [ "$status" = "unhealthy" ] && { docker logs "$NAME"; exit 1; }
  sleep 2
done
test "$(docker inspect -f '{{.State.Health.Status}}' "$NAME")" = "healthy"

echo "== non-root service account and FTL user"
test "$(docker exec "$NAME" id -u pihole)" = "1000"
test "$(docker exec "$NAME" id -g pihole)" = "1000"
docker exec "$NAME" sh -c 'ps -o user,args -C pihole-FTL' | grep -q '^pihole'

echo "== DNS answers"
docker exec "$NAME" dig +short +norecurse @127.0.0.1 pi.hole | grep -q '^127.0.0.1$'
docker exec "$NAME" dig +short +time=5 +tries=2 @127.0.0.1 example.com \
  | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'

echo "== web interface"
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "http://127.0.0.1:${WEB_PORT}/admin/")"
test "$code" = "200" -o "$code" = "302"

echo "== component versions"
docker exec "$NAME" pihole -v

echo "== negative test: healthcheck must fail when FTL is gone"
docker exec "$NAME" sh -c 'killall --signal 9 pihole-FTL || true'
sleep 3
if docker exec "$NAME" sh -c 'dig -p $(pihole-FTL --config dns.port) +short +norecurse +retry=0 @127.0.0.1 pi.hole'; then
  echo "ERROR: DNS still answered after FTL was killed" >&2
  exit 1
fi

echo "Smoke test passed."
