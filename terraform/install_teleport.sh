#! /usr/bin/env bash

set -euxo pipefail

TELEPORT_VERSION="17"

apt-get -y update
apt-get -y install software-properties-common
apt-get -y install apt-transport-https
apt-get -y install libnss3-tools
apt-get -y install wget
apt-get -y install dnsutils

echo "-----> Downloading Teleport"
curl https://apt.releases.teleport.dev/gpg \
-o /usr/share/keyrings/teleport-archive-keyring.asc

source /etc/os-release

echo "deb [signed-by=/usr/share/keyrings/teleport-archive-keyring.asc] \
https://apt.releases.teleport.dev/${ID?} ${VERSION_CODENAME?} stable/v$TELEPORT_VERSION" \
| tee /etc/apt/sources.list.d/teleport.list > /dev/null 

apt-get -y update
apt-get -y install teleport
echo "-----> Install SystemD"
teleport install systemd

systemctl enable teleport
systemctl start teleport
systemctl enable tbot
systemctl start tbot