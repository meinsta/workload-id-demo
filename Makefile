# Makefile for AFTER Demo - Teleport Workload Identity (No API Keys)

.PHONY: help demo demo-build demo-logs demo-stop demo-clean test-local real-demo real-setup direct-demo

# Default target
help:
	@echo "🎯 AFTER Demo - Teleport Workload Identity (No API Keys)"
	@echo "=================================================="
	@echo ""
	@echo "Available targets:"
	@echo "  demo         - Run the complete AFTER demo (build + start)"
	@echo "  demo-build   - Build Docker images for demo"
	@echo "  demo-logs    - View logs from running demo"
	@echo "  demo-stop    - Stop the demo"
	@echo "  demo-clean   - Clean up demo (images, volumes, containers)"
	@echo "  real-demo    - Run demo with REAL Teleport cluster (requires setup)"
	@echo "  real-setup   - Show setup instructions for real Teleport"
	@echo "  direct-demo  - Run direct SPIFFE demo (no Ghostunnel needed!)"
	@echo "  test-local   - Test local scripts (requires dependencies)"
	@echo ""
	@echo "🚀 Quick start: make demo"
	@echo ""
	@echo "Key insight: Identity = infrastructure, not configuration"
	@echo "No API keys = automatic rotation + audit + cryptographic identity"

# Run the complete demo
demo:
	@echo "🚀 Starting AFTER Demo (No API Keys)..."
	@echo "🔑 Authentication via certificates, not shared secrets"
	@echo ""
	docker-compose -f docker-compose.demo.yml up --build
	@echo ""
	@echo "🎉 Demo endpoints:"
	@echo "  Web App: http://localhost:8080 (no API keys used)"
	@echo "  Backend: http://localhost:8443/whoami (certificate identity)"
	@echo "  Status: http://localhost:8080/status (cert expiry, not key expiry)"
	@echo "  Docs: http://localhost:8090 (full documentation)"

# Build Docker images
demo-build:
	@echo "🔨 Building Docker images for AFTER demo..."
	docker-compose -f docker-compose.demo.yml build

# View logs
demo-logs:
	@echo "📋 Viewing demo logs (watch for 'no API keys' messages)..."
	docker-compose -f docker-compose.demo.yml logs -f

# Stop the demo
demo-stop:
	@echo "⏹️ Stopping AFTER demo..."
	docker-compose -f docker-compose.demo.yml down

# Clean up everything
demo-clean:
	@echo "🧹 Cleaning up demo (containers, images, volumes)..."
	docker-compose -f docker-compose.demo.yml down -v --rmi all
	@echo "✅ Cleanup complete"

# Test local scripts (requires local dependencies)
test-local:
	@echo "🧪 Testing local scripts..."
	@echo "⚠️  Requires: go, tbot, ghostunnel, TELEPORT_PROXY_ADDR"
	@echo ""
	./testing/bootstrap_sockets.sh
	@echo ""
	@echo "✅ Socket bootstrap successful"
	@echo "Next: export TELEPORT_PROXY_ADDR and run ./testing/demo-after.sh"

# Development helpers
dev-backend:
	@echo "🚀 Building backend service only..."
	docker build -t workload-demo-backend ./backend

dev-web:
	@echo "🌐 Building web service only..."
	docker build -t workload-demo-web ./web

dev-test:
	@echo "🧪 Running backend tests..."
	cd backend && go test -v ./...

# Show demo status
status:
	@echo "📊 Demo Status Check:"
	@echo ""
	@echo "Backend /whoami (certificate identity):"
	@curl -s http://localhost:8443/whoami | jq . || echo "❌ Backend not running"
	@echo ""
	@echo "Web /status (no API key status):"
	@curl -s http://localhost:8080/status | jq . || echo "❌ Web not running"
	@echo ""
	@echo "🔑 Notice: No Authorization headers used anywhere!"

# Real Teleport demo (connects to actual cluster)
real-demo:
	@echo "🔗 Starting REAL Teleport demo..."
	@echo "⚠️  This connects to your actual Teleport cluster"
	@echo "📋 Requirements: .env file with TELEPORT_PROXY_ADDR and join tokens"
	@echo ""
	@if [ ! -f .env ]; then \
		echo "❌ Missing .env file. Run 'make real-setup' for instructions"; \
		exit 1; \
	fi
	@echo "🚀 Starting with real Teleport certificates..."
	docker-compose -f docker-compose.real.yml up --build
	@echo ""
	@echo "🎉 Real Teleport demo endpoints:"
	@echo "  Web App: http://localhost:8080 (no API keys used)"
	@echo "  Backend: http://localhost:8443/whoami (REAL SPIFFE ID from your cluster)"
	@echo "  Status: http://localhost:8080/status (real cert expiry)"
	@echo "  Docs: http://localhost:8090 (full documentation)"

real-setup:
	@echo "🔗 Real Teleport Setup Instructions"
	@echo "==================================="
	@echo ""
	@echo "1. 📖 Read the complete setup guide:"
	@echo "   cat REAL_TELEPORT_SETUP.md"
	@echo ""
	@echo "2. 🏗️ Configure your Teleport cluster:"
	@echo "   - Create workload identities for demo-backend and demo-web"
	@echo "   - Generate Machine ID join tokens"
	@echo "   - Note your cluster proxy address"
	@echo ""
	@echo "3. ⚙️ Create .env file with:"
	@echo "   TELEPORT_PROXY_ADDR=your-tenant.teleport.sh:443"
	@echo "   BACKEND_JOIN_TOKEN=your-backend-token"
	@echo "   WEB_JOIN_TOKEN=your-web-token"
	@echo "   BACKEND_SPIFFE_ID=spiffe://your-tenant.teleport.sh/apps/demo/backend"
	@echo "   WEB_SPIFFE_ID=spiffe://your-tenant.teleport.sh/apps/demo/web"
	@echo ""
	@echo "4. 🚀 Run: make real-demo"
	@echo ""
	@echo "💡 This will connect to YOUR Teleport cluster and issue REAL certificates!"
	@echo "🔑 No API keys anywhere - all authentication via mTLS certificates"

# Direct SPIFFE demo (eliminates Ghostunnel)
direct-demo:
	@echo "⚡ Starting Direct SPIFFE Demo (no Ghostunnel!)"
	@echo "🎯 Pure SPIFFE-to-SPIFFE mTLS communication"
	@echo ""
	@echo "🗑️  ELIMINATED: Ghostunnel proxy layer"
	@echo "✅ DIRECT: Web service with own SPIFFE identity"
	@echo "✅ DIRECT: End-to-end mTLS (web SVID → backend SVID)"
	@echo "🔑 RESULT: Fewer components, same security"
	@echo ""
	docker-compose -f docker-compose.direct.yml up --build
	@echo ""
	@echo "🎉 Direct SPIFFE demo endpoints:"
	@echo "  Web: http://localhost:8080 (Go service with SPIFFE identity)"
	@echo "  Backend: https://localhost:8443/whoami (direct mTLS target)"
	@echo "  Status: http://localhost:8080/status (both web & backend cert info)"
	@echo "  Docs: http://localhost:8090 (architecture documentation)"
	@echo ""
	@echo "🚀 Key insight: Both services are SPIFFE-native - no proxy needed!"
