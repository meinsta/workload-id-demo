#!/usr/bin/env bash

set -euo pipefail

echo "🔧 Bootstrapping socket directories for Teleport Workload Identity demo..."

# Create socket directory structure
SOCKET_DIR="testing/.cache/sockets"
mkdir -p "$SOCKET_DIR"

# Set appropriate permissions (readable/writable by owner)
chmod 755 testing/.cache
chmod 755 "$SOCKET_DIR"

echo "✅ Created socket directory: $SOCKET_DIR"
echo "   - Backend socket will be: $SOCKET_DIR/backend.sock"
echo "   - Web socket will be: $SOCKET_DIR/web.sock"
echo ""
echo "🔑 Ready for Teleport Workload Identity (no API keys needed!)"
echo "   Next: export TELEPORT_PROXY_ADDR=\"your-cluster.teleport.sh:443\""
echo "   Then: ./testing/demo-after.sh"
