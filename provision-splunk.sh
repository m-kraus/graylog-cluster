#!/bin/bash

# splunk user
useradd splunk
groupadd splunk

# splunk rpm install
yum install -y /vagrant/cache/splunk-*-x86_64.rpm

# environment
echo "export SPLUNK_HOME=/opt/splunk" > /etc/profile.d/splunk.sh
export SPLUNK_HOME=/opt/splunk

# permissions
chown -R splunk:splunk $SPLUNK_HOME

# systemd
echo "[Unit]
Description=Splunk Enterprise
Wants=network.target
After=network.target
[Service]
User=splunk
RemainAfterExit=yes
ExecStart=/opt/splunk/bin/splunk start
ExecStop=/opt/splunk/bin/splunk stop
ExecReload=/opt/splunk/bin/splunk restart
[Install]
WantedBy=multi-user.target" > /usr/lib/systemd/system/splunk.service

ln -sf /usr/lib/systemd/system/splunk.service /etc/systemd/system/multi-user.target.wants/splunk.service

systemctl daemon-reload

# first run
sudo -H -u splunk $SPLUNK_HOME/bin/splunk start --accept-license
sudo -H -u splunk $SPLUNK_HOME/bin/splunk stop

# enable free license
echo "
[license]
active_group = Free
" >> /opt/splunk/etc/system/local/server.conf

# enable and start
systemctl enable splunk.service
systemctl start splunk.service

