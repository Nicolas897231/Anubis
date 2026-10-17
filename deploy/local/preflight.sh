#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$repo"

fail() { printf 'BLOCKED: %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Linux ]] || fail 'Run this check on the Ubuntu server.'
for tool in docker ss free df openssl; do
  command -v "$tool" >/dev/null || fail "Missing command: $tool"
done
[[ -f compose.yaml && -f supabase/config.toml ]] || fail 'Incomplete checkout.'
[[ -f .env ]] || fail 'Existing ANUBIS .env missing; do not overwrite server configuration.'
[[ ! -f supabase/.temp/project-ref ]] || fail 'Checkout linked to hosted. Use a separate, unlinked lab checkout; do not delete the link blindly.'

docker info >/dev/null 2>&1 || fail 'Docker unavailable to this user. Do not change permissions automatically.'
docker compose version
docker compose -f compose.yaml config --quiet
caddy_id=$(docker compose -f compose.yaml ps -q caddy)
[[ -n "$caddy_id" ]] || fail 'Existing ANUBIS Caddy must be running before this lab procedure.'

printf '\nINFO: ANUBIS runs Node inside Docker; host Node/npm are not required.\n'
if command -v supabase >/dev/null 2>&1; then
  printf 'INFO: native Supabase CLI found; verify its version before starting the lab.\n'
else
  printf 'INFO: native Supabase CLI not installed yet; install it in step 2, after preflight review.\n'
fi

printf '\nResources (review available memory/disk before installing):\n'
free -h
df -h .
printf '\nExisting containers (no environment variables):\n'
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
printf '\nExisting listeners on 80/443 (do not stop Guardian):\n'
ss -H -ltn '( sport = :80 or sport = :443 )'

listeners=$(ss -H -ltn '( sport >= :54320 and sport <= :54329 )')
if [[ -n "$listeners" ]]; then
  printf '%s\n' "$listeners"
  fail 'Lab port range already occupied. Inspect ownership; do not stop other applications. This preflight is for first installation.'
fi
if docker network inspect anubis-supabase-lab >/dev/null 2>&1; then
  binding=$(docker network inspect anubis-supabase-lab --format '{{index .Options "com.docker.network.bridge.host_binding_ipv4"}}')
  [[ "$binding" == 127.0.0.1 ]] || fail 'Existing lab network is not loopback-bound. Review without deleting it.'
fi
printf '\nPASS: initial preflight only; no services started and no integration validated.\n'
