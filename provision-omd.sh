#!/bin/bash


cd /tmp


# epel
yum -y install /vagrant/cache/epel.rpm


# omd
rpm -Uvh "https://labs.consol.de/repo/testing/rhel7/i386/labs-consol-testing.rhel7.noarch.rpm"
yum install -y omd-2.*


# prerequisites
yum install -y python-pip
pip install nagios-plugin-elasticsearch
yum install -y python-docopt python-requests


# install graylogapi
tar xzvf /vagrant/install/graylogapi_2015-08-26.tar.gz
mv graylogapi/share/graylogapi/ /omd/versions/default/share/
mv graylogapi/skel/etc/graylogapi/ /omd/versions/default/skel/etc/


# site
omd create demosite
omd stop demosite
omd config demosite set CORE nagios
omd config demosite set DEFAULT_GUI thruk

mv graylogapi/site/etc/graylogapi/apikeys /omd/sites/demosite/etc/graylogapi/
mv graylogapi/site/etc/nagios/conf.d/graylog* /omd/sites/demosite/etc/nagios/conf.d/

cp /vagrant/node_omd01/check_* /omd/sites/demosite/local/lib/nagios/plugins/
cp /vagrant/node_omd01/*.cfg /omd/sites/demosite/etc/nagios/conf.d/

chown -R demosite: /omd/sites/demosite/etc/graylogapi/
chown -R demosite: /omd/sites/demosite/etc/nagios/conf.d/
chown -R demosite: /omd/sites/demosite/local/lib/nagios/plugins/

cd /omd/sites/demosite/etc/apache/conf.d/
ln -s ../../graylogapi/graylogapi.conf .

omd start demosite
