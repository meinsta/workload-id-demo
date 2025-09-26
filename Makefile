# Makefile for AFTER Demo - Teleport Workload Identity (No API Keys)

.PHONY: help demo demo-build demo-logs demo-stop demo-clean test-local

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
