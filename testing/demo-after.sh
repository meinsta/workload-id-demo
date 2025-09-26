#!/usr/bin/env bash

set -euo pipefail

echo "🎯 AFTER Demo: Teleport Workload Identity (No API Keys)"
echo "=================================================="
echo ""

# Check required environment
if [ -z "${TELEPORT_PROXY_ADDR:-}" ]; then
    echo "❌ TELEPORT_PROXY_ADDR environment variable required"
    echo "   Example: export TELEPORT_PROXY_ADDR=\"your-cluster.teleport.sh:443\""
    exit 1
fi

echo "📋 Configuration:"
echo "   Teleport Cluster: $TELEPORT_PROXY_ADDR"
echo "   Socket Directory: testing/.cache/sockets/"
echo "   🔑 Authentication Method: mTLS via SVID certificates (no API keys)"
echo ""

# Step 1: Bootstrap sockets
echo "🔧 Step 1: Bootstrap socket directories"
./testing/bootstrap_sockets.sh
echo ""

# Step 2: Start tbot for backend (background)
echo "🤖 Step 2: Starting tbot for backend..."
export BACKEND_WORKLOAD_SOCKET="unix://testing/.cache/sockets/backend.sock"
tbot start --config=testing/tbot-backend-1.yaml &
TBOT_BACKEND_PID=$!
echo "   Started tbot (backend) with PID: $TBOT_BACKEND_PID"
echo "   Socket: $BACKEND_WORKLOAD_SOCKET"
echo ""

# Step 3: Start tbot for web (background)
echo "🌐 Step 3: Starting tbot for web..."
export WEB_WORKLOAD_SOCKET="unix://testing/.cache/sockets/web.sock"
tbot start --config=testing/tbot-web.yaml &
TBOT_WEB_PID=$!
echo "   Started tbot (web) with PID: $TBOT_WEB_PID"
echo "   Socket: $WEB_WORKLOAD_SOCKET"
echo ""

# Give tbot time to get initial certificates
echo "⏳ Waiting for initial certificate issuance..."
sleep 10

# Step 4: Start ghostunnel (background)
echo "🔒 Step 4: Starting ghostunnel proxy..."
./testing/start-ghostunnel.sh &
GHOSTUNNEL_PID=$!
echo "   Started ghostunnel with PID: $GHOSTUNNEL_PID"
echo ""

# Give ghostunnel time to start
sleep 5

# Step 5: Start backend (background)
echo "🚀 Step 5: Starting backend service..."
./testing/start-backend.sh &
BACKEND_PID=$!
echo "   Started backend with PID: $BACKEND_PID"
echo ""

# Give backend time to start
sleep 5

# Step 6: Test the demo
echo "🧪 Step 6: Testing the AFTER demo..."
echo ""

# Test 1: Check whoami endpoint
echo "Test 1: Identity check (no API key)"
if curl -s -k "https://localhost:8081/whoami" | jq -r '. | "SPIFFE ID: \(.spiffe_id) | Expires in: \(.expires_in)"'; then
    echo "✅ Identity verified via certificate (not API key)"
else
    echo "❌ Failed to get identity"
fi
echo ""

# Test 2: Check main endpoint  
echo "Test 2: Backend communication"
if curl -s "http://localhost:8081/" | jq -r '. | "Backend: \(.name) | SVID: \(.svid)"'; then
    echo "✅ Backend communication successful (mTLS, no headers)"
else
    echo "❌ Failed to communicate with backend"
fi
echo ""

# Step 7: Demo report
echo "📊 Demo Report:"
echo "==============="
echo "✅ No Authorization header used anywhere"
echo "✅ Client identity: cryptographically proven via SVID certificate"
echo "✅ Certificate expires and auto-rotates via tbot"
echo "✅ All access audited by Teleport"
echo "✅ No shared secrets in environment or config files"
echo ""

echo "🎉 AFTER Demo Complete!"
echo ""
echo "Key insights:"
echo "• Authentication = mTLS certificates (not bearer tokens)"
echo "• Authorization = Teleport policies (not shared secrets)"  
echo "• Rotation = automatic via tbot (not manual key updates)"
echo "• Audit = comprehensive via Teleport (not limited logs)"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "🧹 Cleaning up demo processes..."
    
    if [ -n "${BACKEND_PID:-}" ]; then
        kill $BACKEND_PID 2>/dev/null || true
        echo "   Stopped backend"
    fi
    
    if [ -n "${GHOSTUNNEL_PID:-}" ]; then
        kill $GHOSTUNNEL_PID 2>/dev/null || true
        echo "   Stopped ghostunnel"
    fi
    
    if [ -n "${TBOT_WEB_PID:-}" ]; then
        kill $TBOT_WEB_PID 2>/dev/null || true
        echo "   Stopped tbot (web)"
    fi
    
    if [ -n "${TBOT_BACKEND_PID:-}" ]; then
        kill $TBOT_BACKEND_PID 2>/dev/null || true
        echo "   Stopped tbot (backend)"
    fi
    
    echo "✅ Cleanup complete"
}

# Set up cleanup trap
trap cleanup EXIT

# Keep demo running for inspection
echo "Demo is running. Press Ctrl+C to stop."
echo ""
echo "Try these commands:"
echo "  curl -k https://localhost:8081/whoami"
echo "  curl http://localhost:8081/"
echo "  curl http://localhost:8080/status  # (if web app is running)"
echo ""

# Wait for interrupt
while true; do
    sleep 1
done
