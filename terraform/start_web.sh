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

# run app
cat << 'EOF' > /etc/systemd/system/demo-web.service
[Unit]
Description=Workload ID Demo Web
After=network.target

[Service]
Type=simple
User=root
Group=root
Restart=on-failure
Environment="WEB_PORT=80"
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
