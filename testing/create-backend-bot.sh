#! /usr/bin/env bash

set -euxo pipefail

mkdir /Users/davesudia/.tbot-backend-1
mkdir /Users/davesudia/.tbot-backend-1/workload-id-demo
TOKEN=$(tctl bots add workload-id-demo-backend-1-testing-bot --roles=workload-id-demo-backend-1-spiffe-bot --format=json | jq -r '.token_id')
sleep 1
WORKLOAD_IDENTITY_EXPERIMENT=1 tbot start \
   --token="$TOKEN" \
   --auth-server=teleport-ent-15.asteroid.earth:443 \
   --join-method=token \
   --config ./tbot-backend-1.yaml