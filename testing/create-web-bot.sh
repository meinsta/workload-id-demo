#! /usr/bin/env bash

set -euxo pipefail

mkdir /Users/davesudia/.tbot-web
mkdir /Users/davesudia/.tbot-web/workload-id-demo
TOKEN=$(tctl bots add workload-id-demo-web-testing-bot --roles=workload-id-demo-web-spiffe-bot --format=json | jq -r '.token_id')
sleep 1
WORKLOAD_IDENTITY_EXPERIMENT=1 tbot start \
   --token="$TOKEN" \
   --auth-server=mwidemo.cloud.gravitational.io:443 \
   --join-method=token \
   --config ./tbot-web.yaml