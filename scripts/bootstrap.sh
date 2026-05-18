#!/usr/bin/env bash
# Idempotente: genera secretos si faltan, levanta el stack, imprime URLs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SECRETS_DIR="infrastructure/secrets"
PRIV_KEY="$SECRETS_DIR/controller_ssh_key"
PUB_KEY="$SECRETS_DIR/controller_ssh_key.pub"
ENV_FILE=".env"

mkdir -p "$SECRETS_DIR"

# 1. Llave SSH del controller (ed25519 sin passphrase, scope solo este stack).
if [[ ! -f "$PRIV_KEY" ]]; then
  echo "[bootstrap] generando llave SSH controller -> agentes"
  ssh-keygen -t ed25519 -N "" -C "controller@unir-calc-ci" -f "$PRIV_KEY" >/dev/null
fi
chmod 600 "$PRIV_KEY"

# 2. .env: admin de Jenkins + pubkey en una línea.
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[bootstrap] creando .env"
  ADMIN_PASS="$(openssl rand -hex 16)"
  cat > "$ENV_FILE" <<EOF
JENKINS_ADMIN_ID=admin
JENKINS_ADMIN_PASSWORD=$ADMIN_PASS
CONTROLLER_SSH_PUBKEY=$(cat "$PUB_KEY")
EOF
  echo "[bootstrap] password admin generado, revisa .env"
else
  # Asegura que la pubkey en .env coincide con la del fichero.
  CURRENT="$(grep -E '^CONTROLLER_SSH_PUBKEY=' "$ENV_FILE" | cut -d= -f2-)"
  EXPECTED="$(cat "$PUB_KEY")"
  if [[ "$CURRENT" != "$EXPECTED" ]]; then
    echo "[bootstrap] actualizando CONTROLLER_SSH_PUBKEY en .env"
    sed -i.bak "s|^CONTROLLER_SSH_PUBKEY=.*|CONTROLLER_SSH_PUBKEY=$EXPECTED|" "$ENV_FILE"
    rm -f "$ENV_FILE.bak"
  fi
fi

# 3. Build + up.
echo "[bootstrap] docker compose build"
docker compose build

echo "[bootstrap] docker compose up -d"
docker compose up -d

# 4. Espera a que Jenkins esté listo (HTTP 200 en /login).
echo -n "[bootstrap] esperando Jenkins"
for i in $(seq 1 60); do
  if curl -fsS -o /dev/null http://localhost:8080/login 2>/dev/null; then
    echo " listo"
    break
  fi
  echo -n "."
  sleep 2
done

echo
echo "[bootstrap] Stack arriba:"
echo "  Jenkins UI:   http://localhost:8080"
echo "  Wiremock:     http://localhost:9090/__admin/mappings"
echo "  Login:        admin / $(grep JENKINS_ADMIN_PASSWORD .env | cut -d= -f2)"
