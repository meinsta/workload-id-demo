# AFTER State (Teleport, No API Keys)

This document explains how this demo represents the "AFTER" state where API keys have been eliminated using Teleport Workload Identity and Machine ID (tbot).

## Before → After (1-screen summary)

| Aspect | Before (API Keys) | After (Teleport Workload ID) |
|--------|-------------------|------------------------------|
| **Authentication** | Long-lived bearer secrets in env/config | Short-lived SVIDs via tbot and Workload API |
| **Authorization** | Headers on every request | mTLS between client and service |
| **Identity Binding** | No cryptographic binding | Identity proven by certificates |
| **Audit** | Limited audit | Auditable by Teleport |
| **Rotation** | Manual rotation of shared secrets | Automatic rotation via tbot |

## Architecture Overview

```
┌─────────────────┐    mTLS (no headers)    ┌─────────────────┐
│  web/index.js   │◄──────────────────────►│ backend/main.go │
│                 │                         │                 │
│ - No auth header│                         │ - /whoami route │
│ - /status UI    │                         │ - SVID logging  │
└─────────┬───────┘                         └─────────┬───────┘
          │                                           │
          ▼                                           ▼
┌─────────────────┐                         ┌─────────────────┐
│ testing/        │                         │ testing/        │
│ ghostunnel      │                         │ .cache/sockets/ │
│ (mTLS proxy)    │                         │ backend.sock    │
└─────────┬───────┘                         └─────────┬───────┘
          │                                           │
          ▼                                           ▼
┌─────────────────┐                         ┌─────────────────┐
│ testing/        │                         │ testing/        │
│ .cache/sockets/ │                         │ tbot-backend-   │
│ web.sock        │                         │ 1.yaml          │
└─────────┬───────┘                         └─────────┬───────┘
          │                                           │
          ▼                                           ▼
┌─────────────────┐                         ┌─────────────────┐
│ testing/        │                         │ Teleport        │
│ tbot-web.yaml   │                         │ Machine ID      │
│                 │                         │ (tbot)          │
└─────────────────┘                         └─────────────────┘
```

## Quickstart (Local)

```bash
# 1) prepare local sockets
./testing/bootstrap_sockets.sh

# 2) export your Teleport cluster address (dev)
export TELEPORT_PROXY_ADDR="example.teleport.sh:443"

# 3) run the AFTER demo (spawns tbot for web+backend, ghostunnel, backend)
./testing/demo-after.sh

# 4) see identity (no API key)
curl -k https://localhost:8081/whoami
# → { "spiffe_id": "spiffe://example/ns/demo/sa/web", "not_after": "...", "expires_in": "9m42s" }
```

## Why no API key anymore

### Authentication is cryptographic
The client presents a short-lived certificate issued by Teleport. Instead of:

```javascript
// BEFORE: API key in headers
const response = await fetch(url, {
  headers: {
    'Authorization': 'Bearer sk-1234567890abcdef...' // Long-lived secret
  }
});
```

We now have:

```javascript
// AFTER: mTLS handled by ghostunnel, no headers needed
const response = await fetch(url); // Identity proven by client cert
```

### Authorization is policy-driven
Who can reach the backend is controlled by Teleport roles and policies, not shared secrets.

### Rotation is automatic
tbot renews certificates before expiry. There's nothing to rotate in environment variables.

## Component Details

### Backend (`backend/main.go`)
- **SVID Logging**: Logs SPIFFE ID and certificate expiry on startup
- **Workload Socket**: Configurable via `--workload-socket` flag or `WORKLOAD_API_SOCKET` env
- **No Authorization Headers**: Explicitly avoids API key patterns
- **Identity Endpoint**: `/whoami` returns current SPIFFE ID and certificate status
- **mTLS Validation**: Uses `tlsconfig.AuthorizeID` to validate client certificates

### Web App (`web/index.js`)
- **No Auth Headers**: Removes all `Authorization` header usage
- **mTLS Comments**: Explains that authentication is handled by ghostunnel + SVID
- **Status UI**: `/status` endpoint shows certificate expiry countdown

### tbot Configurations
- **Repo-local Sockets**: Uses `testing/.cache/sockets/` instead of user-specific paths
- **Environment Overrides**: Supports `BACKEND_WORKLOAD_SOCKET` and `WEB_WORKLOAD_SOCKET`
- **Short TTL**: 10-minute credential TTL with 5-minute renewal interval

## Security Benefits

### Cryptographic Identity
- Each service has a unique SPIFFE ID backed by a certificate
- Certificates cannot be shared or stolen like API keys
- Identity is cryptographically bound to the workload

### Automatic Rotation
- Certificates rotate every 10 minutes automatically
- No manual key rotation processes
- No risk of forgotten key updates

### Comprehensive Audit
Access shows up in Teleport's audit log with detailed information:
- **Who**: Which workload identity accessed what
- **What**: Specific resource and operation
- **When**: Timestamp with session correlation
- **How**: mTLS handshake details and certificate chain

No shared secrets means no credential stuffing or lateral movement via compromised keys.

## File Structure

```
testing/
├── .cache/sockets/          # Local socket directory
│   ├── backend.sock         # Backend workload API socket
│   └── web.sock            # Web workload API socket
├── tbot-backend-1.yaml     # Backend tbot configuration
├── tbot-web.yaml           # Web tbot configuration
├── bootstrap_sockets.sh    # Socket directory setup
├── start-backend.sh        # Backend startup script
├── start-ghostunnel.sh     # Ghostunnel proxy startup
└── demo-after.sh          # End-to-end demo script
```

## Development Workflow

1. **Setup**: Run `./testing/bootstrap_sockets.sh` to create socket directories
2. **Configure**: Set `TELEPORT_PROXY_ADDR` to your cluster
3. **Demo**: Run `./testing/demo-after.sh` for full end-to-end flow
4. **Verify**: Check `/whoami` endpoint to see certificate details
5. **Monitor**: Watch automatic certificate rotation in logs

The key insight is that **identity becomes infrastructure**, not configuration. Services prove who they are through certificates managed by Teleport, not through secrets managed by developers.
