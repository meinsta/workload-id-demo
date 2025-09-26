# 🐳 Docker Demo: AFTER State (No API Keys)

This Docker demo showcases the complete **AFTER state** where API keys are eliminated using Teleport Workload Identity principles. The demo runs entirely in containers and requires no external dependencies.

## 🚀 Quick Start

```bash
# Clone and navigate to the repository
git clone https://github.com/meinsta/workload-id-demo.git
cd workload-id-demo

# Run the complete AFTER demo
docker-compose -f docker-compose.demo.yml up --build
```

## 🎯 What You'll See

### ✅ **No API Keys Anywhere**
- **Backend**: No Authorization header validation
- **Web**: No Authorization headers sent
- **Logs**: Clear messaging about cryptographic identity

### 🔐 **Certificate-Based Authentication**
- **Identity**: Proven via mTLS certificates, not shared secrets
- **Rotation**: Automatic (simulated by mock SPIFFE server)
- **Audit**: All access patterns visible in logs

## 📊 Demo Endpoints

Once running, visit these URLs:

| Service | URL | Purpose |
|---------|-----|---------|
| **Web App** | http://localhost:8080 | Main application (no API keys used) |
| **Backend /whoami** | http://localhost:8443/whoami | Identity endpoint (proves cert-based auth) |
| **Backend Main** | http://localhost:8443/ | Backend service response |
| **Status Check** | http://localhost:8080/status | Certificate status (no key expiry to track!) |
| **Documentation** | http://localhost:8090 | Full AFTER demo documentation |

## 🔍 Key Observations

### 1. **No Authorization Headers**
```bash
# Check web app requests - no auth headers
curl http://localhost:8080/status
# → Shows certificate authentication, not API key patterns
```

### 2. **Identity via Certificates**
```bash
# Check backend identity 
curl http://localhost:8443/whoami
# → Returns SPIFFE ID, certificate expiry, remaining lifetime
# → Note: "Authentication via mTLS certificate, not API key"
```

### 3. **Automatic Rotation**
```bash
# Watch logs for rotation messages
docker-compose -f docker-compose.demo.yml logs -f
# → See automatic certificate renewal (no manual key updates!)
```

## 🏗️ Architecture Overview

```
┌─────────────────┐    HTTP (no auth headers)    ┌─────────────────┐
│   Web App       │◄──────────────────────────►│  Backend        │
│   :8080         │                             │  :8443          │
│                 │                             │                 │
│ • No API keys   │                             │ • /whoami       │
│ • /status       │                             │ • SVID logging  │
│ • mTLS comments │                             │ • Cert validation│
└─────────┬───────┘                             └─────────┬───────┘
          │                                               │
          ▼                                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Mock SPIFFE Server                             │
│          (Simulates tbot + Teleport in production)             │
│                                                                 │
│ • Provides certificates (not API keys)                         │
│ • Simulates automatic rotation                                 │
│ • Shows identity as infrastructure                             │
└─────────────────────────────────────────────────────────────────┘
```

## 🎭 Demo vs Production

| Component | Demo Mode | Production Mode |
|-----------|-----------|-----------------|
| **Certificate Source** | Mock SPIFFE Server | Real tbot + Teleport cluster |
| **mTLS Proxy** | Direct connection | ghostunnel with SVID validation |
| **Identity Validation** | Simulated | Real SPIFFE ID verification |
| **Rotation** | Mock timer | Teleport Machine ID automatic renewal |
| **Audit** | Container logs | Full Teleport audit trail |

## 📋 Before vs After Comparison

### ❌ **BEFORE (API Keys)**
- Long-lived secrets in environment variables
- Authorization headers on every request
- Manual rotation and secret management
- Limited audit capabilities
- Risk of credential stuffing

### ✅ **AFTER (Teleport Workload Identity)**
- Short-lived certificates managed by infrastructure
- mTLS authentication without headers
- Automatic rotation by Teleport
- Comprehensive audit in Teleport logs
- Cryptographically-bound identity

## 🛠️ Development

### Build Individual Services
```bash
# Build backend
docker build -t workload-demo-backend ./backend

# Build web
docker build -t workload-demo-web ./web

# Run backend only
docker run -p 8443:8443 workload-demo-backend
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.demo.yml logs -f

# Specific service
docker-compose -f docker-compose.demo.yml logs -f backend
```

### Clean Up
```bash
# Stop all services
docker-compose -f docker-compose.demo.yml down

# Remove images
docker-compose -f docker-compose.demo.yml down --rmi all

# Full cleanup including volumes
docker-compose -f docker-compose.demo.yml down -v --rmi all
```

## 🎓 Learning Outcomes

After running this demo, you'll understand:

1. **How API keys are eliminated** through cryptographic identity
2. **What mTLS authentication looks like** in practice
3. **How automatic certificate rotation works** (simulated)
4. **Why identity as infrastructure** is more secure than secrets as configuration
5. **The audit and operational benefits** of Teleport Workload Identity

## 🚀 Next Steps

1. **Run the demo**: `docker-compose -f docker-compose.demo.yml up --build`
2. **Explore endpoints**: Visit all the URLs listed above
3. **Read documentation**: Check http://localhost:8090 for detailed docs
4. **Review code**: See how API key patterns are explicitly avoided
5. **Try with real Teleport**: Use `docker-compose.yml` with actual cluster

## 🔑 Key Insight

**Identity becomes infrastructure**, not configuration. Services prove who they are through certificates managed by Teleport, not through secrets managed by developers.

**No more API keys = automatic rotation + comprehensive audit + cryptographically-bound identity + zero shared secrets.**
