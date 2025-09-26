#!/usr/bin/env bash

set -euo pipefail

echo "🚀 Starting backend service (AFTER state - no API keys)"

# Workload API socket - use repo-local path by default
export WORKLOAD_API_SOCKET="${WORKLOAD_API_SOCKET:-unix://testing/.cache/sockets/backend.sock}"

# Legacy compatibility 
export BACKEND_SOCKET_PATH="$WORKLOAD_API_SOCKET"

# Backend configuration
export BACKEND_APPROVED_CLIENT_SPIFFEID="${BACKEND_APPROVED_CLIENT_SPIFFEID:-spiffe://mwidemo.cloud.gravitational.io/apps/w2w-demo/web}"
export BACKEND_NAME="${BACKEND_NAME:-Backend 1 (AFTER)}"
export BACKEND_INFRA="${BACKEND_INFRA:-VM}"
export BACKEND_PORT="${BACKEND_PORT:-8443}"

echo "Configuration:"
echo "  Socket: $WORKLOAD_API_SOCKET"
echo "  Approved Client: $BACKEND_APPROVED_CLIENT_SPIFFEID"
echo "  Port: $BACKEND_PORT"
echo "  🔑 No API keys - identity via mTLS certificate"
echo ""

cd ../backend && go run main.go
