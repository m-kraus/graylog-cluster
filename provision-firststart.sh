#!/bin/bash

# WORKAROUND: service does not start when not called this way (as root) initially
/opt/graylog/bin/graylogctl start -f /etc/graylog/server/server.conf -d
sleep 30
/opt/graylog/bin/graylogctl stop
sleep 30
rm /opt/graylog/log/graylog-server.log
# END WORKAROUND

# permissions
chown -R graylog: /opt/graylog/
chown -R graylog: /var/run/graylog
chown -R graylog: /var/log/graylog
chown -R graylog: /var/lib/graylog-server/

# start services
systemctl start graylog-server.service
systemctl start graylog-web.service

# WORKAROUND haproxy not listening on port 514 initially
systemctl restart haproxy
