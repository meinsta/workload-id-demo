# 🔗 Real Teleport Tenant Setup Guide

This guide walks you through connecting the demo to your **actual Teleport cluster** instead of the mock SPIFFE server.

## 🎯 **What Changes: Mock vs Real**

| Component | **Mock (demo)** | **Real Teleport** |
|-----------|-----------------|-------------------|
| **Certificate Source** | Fake socket files | Real tbot + your Teleport cluster |
| **Authentication** | Simulated | Real SPIFFE certificates from Teleport |
| **Rotation** | Mock timer | Actual Teleport Machine ID rotation |
| **Audit** | Container logs | Full Teleport audit logs |
| **Network** | Local Docker | Real mTLS with SPIFFE validation |

## 📋 **Prerequisites**

1. **Teleport Cloud or Self-Hosted cluster** with admin access
2. **Docker and Docker Compose** installed locally
3. **Network access** to your Teleport cluster

## 🔧 **Step-by-Step Setup**

### **Step 1: Teleport Cluster Configuration**

First, configure workload identities and Machine ID in your Teleport cluster:

```bash
# 1. Log into your Teleport cluster
tsh login --proxy=your-tenant.teleport.sh

# 2. Create workload identities
tctl create -f - <<EOF
kind: workload_identity
version: v1
metadata:
  name: demo-backend
spec:
  rules:
    allow:
    - conditions:
      - search:
        - labels.app
        - demo-backend
      - search:
        - labels.env  
        - after-demo
EOF

tctl create -f - <<EOF
kind: workload_identity
version: v1
metadata:
  name: demo-web
spec:
  rules:
    allow:
    - conditions:
      - search:
        - labels.app
        - demo-web
      - search:
        - labels.env
        - after-demo
EOF

# 3. Create Machine ID join tokens
BACKEND_TOKEN=$(tctl tokens add --type=bot --bot-name=demo-backend --format=json | jq -r .metadata.name)
WEB_TOKEN=$(tctl tokens add --type=bot --bot-name=demo-web --format=json | jq -r .metadata.name)

echo "Backend token: $BACKEND_TOKEN"
echo "Web token: $WEB_TOKEN"
```

### **Step 2: Environment Configuration**

Create a `.env` file with your Teleport cluster information:

```bash
# Create .env file
cat > .env <<EOF
# Your Teleport cluster
TELEPORT_PROXY_ADDR=your-tenant.teleport.sh:443

# Join tokens from Step 1
BACKEND_JOIN_TOKEN=your-backend-token-here
WEB_JOIN_TOKEN=your-web-token-here

# SPIFFE IDs (update to match your cluster)
BACKEND_SPIFFE_ID=spiffe://your-tenant.teleport.sh/apps/demo/backend
WEB_SPIFFE_ID=spiffe://your-tenant.teleport.sh/apps/demo/web

# Logging level
TBOT_LOG_LEVEL=debug
EOF
```

### **Step 3: Update Docker Compose Configuration**

The demo includes `docker-compose.real.yml` which uses real tbot instead of mock:

```yaml
# Key differences from mock version:
services:
  tbot-backend:
    image: public.ecr.aws/gravitational/teleport:15
    command: >
      tbot start
      --config=/etc/tbot/tbot-backend-real.yaml
      --debug
    volumes:
      - ./testing/tbot-backend-real.yaml:/etc/tbot/tbot-backend-real.yaml:ro
```

### **Step 4: Run the Real Demo**

```bash
# 1. Source your environment
source .env

# 2. Run with real Teleport
docker-compose -f docker-compose.real.yml up --build

# 3. Watch for real certificate issuance in logs
docker-compose -f docker-compose.real.yml logs -f tbot-backend
```

### **Step 5: Verify Real Certificates**

```bash
# Check backend identity (real SPIFFE ID from your cluster)
curl -s http://localhost:8443/whoami | jq .

# Expected output with YOUR cluster's SPIFFE ID:
{
  "spiffe_id": "spiffe://your-tenant.teleport.sh/apps/demo/backend",
  "not_after": "2024-01-01T10:10:00Z",
  "expires_in": "9m45s",
  "note": "Authentication via mTLS certificate, not API key"
}
```

## 🔍 **Verification Checklist**

✅ **tbot connects to your cluster** (check logs for "Successfully renewed credentials")  
✅ **Real SPIFFE IDs** in `/whoami` response match your cluster  
✅ **Certificate rotation** happens automatically every 10 minutes  
✅ **Audit logs** appear in your Teleport cluster's audit log  
✅ **No API keys** used anywhere in the flow  

## 🐛 **Troubleshooting**

### **Problem: tbot can't connect to cluster**
```bash
# Check proxy address
nslookup your-tenant.teleport.sh

# Verify token is valid
tctl tokens ls
```

### **Problem: SPIFFE ID mismatch**
```bash
# Check workload identity rules
tctl get workload_identity/demo-backend

# Update SPIFFE IDs in .env file to match your cluster
```

### **Problem: Certificate not being issued**
```bash
# Check tbot logs
docker-compose -f docker-compose.real.yml logs tbot-backend

# Common issues:
# - Invalid join token
# - Workload identity rules don't match labels
# - Network connectivity to cluster
```

### **Problem: mTLS verification fails**
```bash
# Check ghostunnel logs
docker-compose -f docker-compose.real.yml logs ghostunnel

# Verify SPIFFE IDs match between:
# - Backend workload identity
# - Ghostunnel --verify-uri parameter
# - Environment variables
```

## 🎓 **What You'll See with Real Teleport**

1. **Real certificate issuance** in tbot logs
2. **Your cluster's SPIFFE IDs** in `/whoami` responses  
3. **Automatic rotation** every 10 minutes with new certificates
4. **Teleport audit events** in your cluster's audit log
5. **True zero-API-key authentication** end-to-end

## 📊 **Monitoring Your Demo**

```bash
# Watch certificate rotation
watch -n 10 'curl -s http://localhost:8443/whoami | jq .expires_in'

# Monitor Teleport audit logs
tsh ssh teleport-cluster
sudo tail -f /var/lib/teleport/log/events.log | jq 'select(.event == "workload_identity")'

# Check tbot status
docker-compose -f docker-compose.real.yml exec tbot-backend ps aux
```

## 🔑 **Key Insight**

With real Teleport, you get:
- **Production-grade security**: Real certificate validation  
- **Complete audit trail**: Every access logged in Teleport
- **Zero shared secrets**: No API keys anywhere in the system
- **Automatic lifecycle**: Certificates rotate without manual intervention

**Identity truly becomes infrastructure**, managed by your Teleport cluster rather than application configuration.
