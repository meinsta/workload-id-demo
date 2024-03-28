#! /usr/bin/env bash

set -euxo pipefail

ghostunnel client \
  --use-workload-api-addr unix:///Users/davesudia/.tbot-web/demo-web.sock \
  --listen localhost:8081 \
  --target localhost:8443 \
  --verify-uri spiffe://teleport-ent-15.asteroid.earth/workload-id-demo/demo-backend-1
