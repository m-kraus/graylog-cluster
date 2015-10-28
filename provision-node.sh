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
sed -i -e 's/#LimitMEMLOCK=infinity/#LimitMEMLOCK=infinity/g' /lib/systemd/system/elasticsearch.service
sed -i -e 's/#ES_JAVA_OPTS=/ES_JAVA_OPTS="-Djava.net.preferIPv4Stack=true"/g' /etc/sysconfig/elasticsearch
sed -i -e 's/#MAX_LOCKED_MEMORY=unlimited/MAX_LOCKED_MEMORY=unlimited/g' /etc/sysconfig/elasticsearch
systemctl daemon-reload
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


# graylog-server
yum -y install /vagrant/cache/graylog-server.rpm
cp /vagrant/node_${NODE}/graylog-server.conf /etc/graylog/server/server.conf

# plugins
cp /vagrant/install/plugin-output-splunk-0.3.0.jar /usr/share/graylog-server/plugin/
cp /vagrant/install/graylog-plugin-snmp-0.3.0.jar /usr/share/graylog-server/plugin/


# graylog-web
yum -y install /vagrant/cache/graylog-web.rpm
cp /vagrant/node_${NODE}/graylog-web.conf /etc/graylog/web/web.conf


# nginx
yum -y install nginx
cp /vagrant/node_${NODE}/nginx.conf /etc/nginx/nginx.conf
systemctl enable nginx
systemctl start nginx


# haproxy
yum -y install haproxy
systemctl enable haproxy.service
cp /vagrant/node_${NODE}/haproxy.cfg /etc/haproxy/haproxy.cfg
# SELINUX for port binding
setsebool -P haproxy_connect_any 1
systemctl start haproxy.service


# local syslogs
cp /vagrant/node_${NODE}/10-glog.conf /etc/rsyslog.d/10-glog.conf
systemctl restart rsyslog.service

