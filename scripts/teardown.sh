#!/usr/bin/env bash
# Apaga el stack. Por defecto conserva el volumen jenkins_home (jobs, plugins, etc.).
# Pasar --purge para borrar también volumen y secretos.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "--purge" ]]; then
  echo "[teardown] modo purge: borrando volumen y secretos"
  docker compose down -v
  rm -rf infrastructure/secrets .env
else
  docker compose down
fi
