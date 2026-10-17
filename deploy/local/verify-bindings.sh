#!/usr/bin/env bash
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
cd "$repo"
ids=$(docker ps --filter network=anubis-supabase-lab --format '{{.ID}}')
[[ -n "$ids" ]] || { printf 'BLOCKED: no running lab containers.\n' >&2; exit 1; }
caddy_id=$(docker compose -f compose.yaml ps -q caddy)
checked=0
while IFS= read -r id; do
  # Existing ANUBIS Caddy intentionally publishes 443; never alter it here.
  if [[ -n "$caddy_id" && "$caddy_id" == "$id"* ]]; then continue; fi
  bindings=$(docker inspect --format '{{range $port, $bindings := .NetworkSettings.Ports}}{{range $bindings}}{{printf "%s=%s\n" $port .HostIp}}{{end}}{{end}}' "$id")
  if [[ -n "$bindings" ]]; then
    while IFS= read -r binding; do
      binding=${binding#*=}
      [[ "$binding" == 127.0.0.1 || "$binding" == ::1 ]] || {
        printf 'FAIL: non-loopback port binding on container %s. Stop the lab and review.\n' "$id" >&2
        exit 1
      }
    done <<< "$bindings"
  fi
  checked=$((checked + 1))
done <<< "$ids"
[[ "$checked" -gt 0 ]] || { printf 'BLOCKED: no backend containers checked.\n' >&2; exit 1; }
printf 'PASS: %s backend containers inspected; published ports are loopback-only.\n' "$checked"
