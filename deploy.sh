#!/usr/bin/env bash
# Sube el website de Airelibre al VPS. Lo sirve el mismo Caddy del Portal DCR.
# Uso: ./deploy.sh [host]
set -euo pipefail
HOST="${1:-147.93.5.74}"
KEY="${SSH_KEY:-$HOME/.ssh/dcr_vps_ed25519}"
SSH_OPTS="-i $KEY -o StrictHostKeyChecking=accept-new"
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "→ Copiando website a $HOST:/opt/airelibre/site"
ssh $SSH_OPTS "root@$HOST" "mkdir -p /opt/airelibre/site"
rsync -az --delete -e "ssh $SSH_OPTS" \
  --include 'index.html' --include 'img/***' --exclude '*' \
  "$DIR/" "root@$HOST:/opt/airelibre/site/"

# La primera vez hay que reiniciar Caddy con la config nueva (bloque airelibre + carpeta montada).
if ! ssh $SSH_OPTS "root@$HOST" "docker exec portal-dcr-caddy test -f /srv/airelibre/index.html" 2>/dev/null; then
  echo "→ Primera vez: actualizando Caddy del Portal DCR"
  "$DIR/../portal-dcr/deploy/deploy.sh" "$HOST"
fi

echo "✓ Listo: https://airelibre.$(echo "$HOST" | tr . -).sslip.io"
