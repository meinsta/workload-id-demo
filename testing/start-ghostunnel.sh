#!/usr/bin/env bash

set -euo pipefail

echo "🔒 Starting ghostunnel (AFTER state - mTLS proxy, no API keys)"

# Web workload socket - use repo-local path by default
WEB_WORKLOAD_SOCKET="${WEB_WORKLOAD_SOCKET:-unix://testing/.cache/sockets/web.sock}"

# Ghostunnel configuration
LISTEN_PORT="${GHOSTUNNEL_LISTEN_PORT:-8081}"
TARGET_HOST="${GHOSTUNNEL_TARGET:-localhost:8443}"
VERIFY_URI="${GHOSTUNNEL_VERIFY_URI:-spiffe://mwidemo.cloud.gravitational.io/apps/w2w-demo/backend-1}"

echo "Configuration:"
echo "  Web socket: $WEB_WORKLOAD_SOCKET"
echo "  Listen: localhost:$LISTEN_PORT"
echo "  Target: $TARGET_HOST"
echo "  Verify URI: $VERIFY_URI"
echo "  🔑 No API keys - client authentication via SVID certificate"
echo ""

ghostunnel client \
  --use-workload-api-addr "$WEB_WORKLOAD_SOCKET" \
  --listen "localhost:$LISTEN_PORT" \
  --target "$TARGET_HOST" \
  --verify-uri "$VERIFY_URI"
