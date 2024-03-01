#! /usr/bin/env bash

set -euxo pipefail

apt-get -y update
apt-get -y install software-properties-common
apt-get -y install apt-transport-https
apt-get -y install wget
apt-get -y install awscli

# these are pre-release binaries
aws s3 cp s3://workload-id-demo-binaries/linux-arm64/teleport /usr/local/bin/teleport
aws s3 cp s3://workload-id-demo-binaries/linux-arm64/tbot /usr/local/bin/tbot

chmod +x /usr/local/bin/teleport
chmod +x /usr/local/bin/tbot

echo "-----> Install SystemD"

teleport install systemd > /etc/systemd/system/teleport.service

systemctl enable teleport
systemctl start teleport
systemctl enable tbot
systemctl start tbot