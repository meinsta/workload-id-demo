#! /usr/bin/env bash

set -euxo pipefail

mkdir /etc/tbot
TOKEN=$(tctl bots add workload-id-demo-backend-2-bot --roles=workload-id-demo-backend-1-spiffe-bot --format=json | jq -r '.token_id')
WORKLOAD_IDENTITY_EXPERIMENT=1 tbot start \
   --destination-dir=/opt/machine-id/demo-backend-1-bot \
   --token="$TOKEN" \
   --auth-server=teleport-ent-15.asteroid.earth:443 \
   --join-method=token \
   --config ./tbot.yaml