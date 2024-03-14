#! /usr/bin/env bash

set -euxo pipefail

tctl bots rm workload-id-demo-backend-2-bot
rm -rf /opt/machine-id/demo-backend-1-storage
rm -rf /opt/machine-id/demo-backend-1-bot
rm -rf /etc/tbot
