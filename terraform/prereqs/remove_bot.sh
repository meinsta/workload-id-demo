#! /usr/bin/env bash

set -euxo pipefail

tctl bots rm terraform-dave
rm -rf /tmp/machine-id/terraform-dave
rm -rf /tmp/tbot
