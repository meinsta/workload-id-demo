#! /usr/bin/env bash

set -euxo pipefail

ghostunnel client \
  --use-workload-api-addr unix:///Users/davesudia/.tbot-web/demo-web.sock \
  --listen localhost:8081 \
  --target localhost:8443 \
  --verify-uri "spiffe://mwidemo.cloud.gravitational.io/apps/w2w-demo/backend-1"
