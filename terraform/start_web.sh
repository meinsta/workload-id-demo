#! /usr/bin/env bash

set -euxo pipefail

apt update -y
apt install -y wget

# install node/npm
curl -sL https://deb.nodesource.com/setup_20.x -o /tmp/nodesource_setup.sh
bash /tmp/nodesource_setup.sh
apt install -y nodejs

# pull code
cd / && git clone https://github.com/asteroid-earth/workload-id-demo.git && \
  cd /workload-id-demo/web && \
  npm install

# create group
groupadd -g 3001 workload-id-web
# create user
useradd -u 3001 -g 3001 workload-id-web
# make user owner of demo-backend
chown -R workload-id-web:workload-id-web /workload-id-demo
chown -R workload-id-web:workload-id-web /usr/bin/npm

# run app
cat << 'EOF' > /etc/systemd/system/demo-web.service
[Unit]
Description=Workload ID Demo Web
After=network.target

[Service]
Type=simple
User=workload-id-web
Group=workload-id-web
Restart=on-failure
Environment="WEB_PORT=8080"
Environment="WEB_GHOSTUNNEL_PORT=8081"
WorkingDirectory=/workload-id-demo/web
ExecStart=npm start
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/run/demo-web.pid
LimitNOFILE=524288

[Install]
WantedBy=multi-user.target
EOF

systemctl enable demo-backend
systemctl start demo-backend
