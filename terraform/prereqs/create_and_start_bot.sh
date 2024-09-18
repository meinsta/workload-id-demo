#! /usr/bin/env bash

set -euxo pipefail

TOKEN=$(tctl bots add terraform-dave --roles=terraform --format=json | jq -r '.token_id')
sleep 1
tbot start \
   --data-dir=/tmp/tbot \
   --destination-dir=/tmp/machine-id/terraform-dave \
   --token="$TOKEN" \
   --auth-server=teleport-16-ent.asteroid.earth:443 \
   --join-method=token
