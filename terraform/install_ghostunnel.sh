#! /usr/bin/env bash

set -euxo pipefail

apt-get -y update
apt-get -y install wget

wget https://github.com/ghostunnel/ghostunnel/releases/download/v1.7.3/ghostunnel-linux-arm64

mv ghostunnel-linux-arm64 /usr/local/bin/ghostunnel

chmod +x /usr/local/bin/ghostunnel
