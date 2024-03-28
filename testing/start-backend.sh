#! /usr/bin/env bash

set -euxo pipefail

export BACKEND_SOCKET_PATH="unix:///Users/davesudia/.tbot-backend-1/demo-backend-1.sock"
export BACKEND_APPROVED_CLIENT_SPIFFEID="spiffe://teleport-ent-15.asteroid.earth/workload-id-demo/demo-web"
export BACKEND_NAME="Backend 1"
export BACKEND_INFRA="VM"
export BACKEND_PORT="8443"

cd ../backend && go run main.go
