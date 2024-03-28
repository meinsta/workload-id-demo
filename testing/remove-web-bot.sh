#! /usr/bin/env bash

set -euxo pipefail

rm -rf /opt/machine-id/demo-web-storage
rm -rf /opt/machine-id/demo-web-bot
rm -rf /etc/tbot/spiffe/demo-web
rm -rf /Users/davesudia/.tbot-web/demo-web.sock
rm -rf /Users/davesudia/.tbot-web
tctl bots rm workload-id-demo-web-testing-bot
