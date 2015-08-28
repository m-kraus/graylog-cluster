#!/bin/bash


NODE=${1:?'no node'}
PROXY=${2:-unset}


# prerequisites
yum -y install unzip


# epel
yum -y install /vagrant/cache/epel.rpm


# java
yum -y install /vagrant/cache/jre.rpm


# elasticsearch
yum -y install /vagrant/cache/elasticsearch.rpm
cp /vagrant/node_${NODE}/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
cp /vagrant/node_${NODE}/elasticsearch.service /lib/systemd/system/elasticsearch.service
systemctl daemon-reload
cp /vagrant/node_${NODE}/elasticsearch.sysconfig /etc/sysconfig/elasticsearch
unzip /vagrant/cache/elasticsearch-kopf.zip
mv elasticsearch-kopf-master/ /usr/share/elasticsearch/plugins/kopf
systemctl enable elasticsearch.service
systemctl start elasticsearch.service


# mongodb
yum -y install /vagrant/cache/mongodb-org.rpm /vagrant/cache/mongodb-org-mongos.rpm /vagrant/cache/mongodb-org-server.rpm /vagrant/cache/mongodb-org-shell.rpm /vagrant/cache/mongodb-org-tools.rpm
cp /vagrant/node_${NODE}/mongod.conf /etc/mongod.conf
chkconfig mongod on
systemctl restart mongod
if [[ "${NODE}" == "glog01" ]]; then
    sleep 10
    echo 'rs.conf()' | mongo 172.16.100.53
    echo 'rs.initiate()' | mongo 172.16.100.53
    echo 'rs.add("172.16.100.54:27017")' | mongo 172.16.100.53
    echo 'rs.add("172.16.100.55:27017")' | mongo 172.16.100.53
    echo 'rs.conf()' | mongo 172.16.100.53
fi


# graylog user and directories
groupadd -r graylog
useradd -r -g graylog -d /var/lib/graylog-server -s /sbin/nologin -c "You know, for logs" graylog
mkdir -p /var/run/graylog
mkdir -p /var/log/graylog
mkdir -p /var/lib/graylog-server/

# graylog-server
tar xzvf /vagrant/cache/graylog-1.1.6.tgz
mv graylog-1.1.6 /opt/graylog
mkdir -p /etc/graylog/server
cp /vagrant/node_${NODE}/graylog-server.conf /etc/graylog/server/server.conf
cp /vagrant/node_${NODE}/graylog-server.log4j /etc/graylog/server/log4j.xml
cp /vagrant/node_${NODE}/graylog-server.service /lib/systemd/system/graylog-server.service
cp /vagrant/node_${NODE}/graylog-server.sysconfig /etc/sysconfig/graylog-server
systemctl daemon-reload
systemctl enable graylog-server.service

# splunk plugin
cp /vagrant/install/plugin-output-splunk-0.3.0.jar /opt/graylog/plugin/

# WORKAROUND NECESSARY:
# service does not start when not called this way (as root) initially
# firststart provision script calls workaround after all nodes are set up
chown -R graylog: /opt/graylog/
chown -R graylog: /var/run/graylog
chown -R graylog: /var/log/graylog
chown -R graylog: /var/lib/graylog-server/

# graylog-web
tar xzvf /vagrant/cache/graylog-web-interface-1.1.6.tgz
mv graylog-web-interface-1.1.6 /opt/graylog-web-interface
chown -R graylog: /opt/graylog-web-interface/
mkdir -p /etc/graylog/web
cp /vagrant/node_${NODE}/graylog-web.conf /etc/graylog/web/web.conf
cp /vagrant/node_${NODE}/graylog-web.service /lib/systemd/system/graylog-web.service
cp /vagrant/node_${NODE}/graylog-web.logger /etc/graylog/web/logger.xml
systemctl daemon-reload
systemctl enable graylog-web.service


# nginx
yum -y install nginx
cp /vagrant/node_${NODE}/nginx.conf /etc/nginx/nginx.conf
systemctl enable nginx
systemctl start nginx


# haproxy
yum -y install haproxy
systemctl enable haproxy.service
systemctl start haproxy.service
#TODO# bind to port 514!
cp /vagrant/node_${NODE}/haproxy.cfg /etc/haproxy/haproxy.cfg
# SELINUX for port binding
setsebool -P haproxy_connect_any 1


# local syslogs
cp /vagrant/node_${NODE}/10-glog.conf /etc/rsyslog.d/10-glog.conf
systemctl restart rsyslog.service
