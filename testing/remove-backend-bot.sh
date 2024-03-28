#! /usr/bin/env bash

set -euxo pipefail

rm -rf /opt/machine-id/demo-backend-1-storage
rm -rf /opt/machine-id/demo-backend-1-bot
rm -rf /etc/tbot/spiffe/demo-backend-1
rm -rf /Users/davesudia/.tbot-backend-1/demo-backend-1.sock
rm -rf /Users/davesudia/.tbot-backend-1
tctl bots rm workload-id-demo-backend-1-testing-bot
