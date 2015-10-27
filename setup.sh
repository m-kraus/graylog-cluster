#/bin/bash

XOMIT=false

while :; do
    case $1 in
        -x)
            XOMIT=true
            ;;
        *)
            break
    esac

    shift
done


# download for caches

#graylog
PACKAGE=graylog-1.1.6.tgz
if [ ! -f ./cache/$PACKAGE ]; then
    wget https://packages.graylog2.org/releases/graylog2-server/$PACKAGE -O ./cache/$PACKAGE
fi
PACKAGE=graylog-web-interface-1.1.6.tgz
if [ ! -f ./cache/$PACKAGE ]; then
    wget https://packages.graylog2.org/releases/graylog2-web-interface/$PACKAGE -O ./cache/$PACKAGE
fi

# epel
PACKAGE=epel-release-7-5.noarch.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/epel.rpm
    wget http://download.fedoraproject.org/pub/epel/7/x86_64/e/$PACKAGE -O ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE epel.rpm
    popd
fi

# java
PACKAGE=jre-8u60-linux-x64.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/jre.rpm
    curl -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u60-b27/$PACKAGE > ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE jre.rpm
    popd
fi

#elasticsearch
PACKAGE=elasticsearch-1.7.1.noarch.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/elasticsearch.rpm
    wget https://download.elasticsearch.org/elasticsearch/elasticsearch/$PACKAGE -O ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE elasticsearch.rpm
    popd
fi
PACKAGE=elasticsearch-kopf.zip
if [ ! -f ./cache/$PACKAGE ]; then
    wget https://github.com/lmenezes/elasticsearch-kopf/archive/master.zip -O ./cache/$PACKAGE
fi

# mongodb
PACKAGE=3.0.6-1.el7.x86_64.rpm
if [ ! -f ./cache/mongodb-org-$PACKAGE ]; then
    rm ./cache/mongodb-org.rpm
    wget https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-$PACKAGE -O ./cache/mongodb-org-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-$PACKAGE mongodb-org.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-mongos-$PACKAGE ]; then
    rm ./cache/mongodb-org-mongos.rpm
    wget https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-mongos-$PACKAGE -O ./cache/mongodb-org-mongos-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-mongos-$PACKAGE mongodb-org-mongos.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-server-$PACKAGE ]; then
    rm ./cache/mongodb-org-server.rpm
    wget https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-server-$PACKAGE -O ./cache/mongodb-org-server-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-server-$PACKAGE mongodb-org-server.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-shell-$PACKAGE ]; then
    rm ./cache/mongodb-org-shell.rpm
    wget https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-shell-$PACKAGE -O ./cache/mongodb-org-shell-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-shell-$PACKAGE mongodb-org-shell.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-tools-$PACKAGE ]; then
    rm ./cache/mongodb-org-tools.rpm
    wget https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-tools-$PACKAGE -O ./cache/mongodb-org-tools-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-tools-$PACKAGE mongodb-org-tools.rpm
    popd
fi


# bring up machines without provisionioning
vagrant up --no-provision glog01
vagrant up --no-provision glog02
vagrant up --no-provision glog03

# provision glog01 last because of mongodb replication
vagrant provision --provision-with node glog02
vagrant provision --provision-with node glog03
vagrant provision --provision-with node glog01

# first-start workaround
vagrant provision --provision-with firststart glog01
vagrant provision --provision-with firststart glog02
vagrant provision --provision-with firststart glog03
echo "Elasticsearch:
Elasticsearch admin is now available at http://172.16.100.53:9200/_plugin/kopf/

Graylog:
Graylog is available at http://172.16.100.53 using the credentials admin:admin
First configure a new global syslog-tcp input listenting on port 10514, since
this task can unfortunately not be automated at the moment.

HAProxy:
HAProxy is listening on TCP port 514 for incoming syslog messages to be
forwarded (round robin) to all graylog nodes listening on port 10514.

Since Elasticsearch and Graylog are clustered and HAproxy is set up on each
node, you can also use 172.16.100.54 or 172.16.100.55"

# "-x" was supplied to ommit building of omd01/splunk01
if [ "$XOMIT" = false ]; then
    # omd01
    vagrant up omd01
    echo "OMD:
    OMD is now available at http://172.16.100.60/demosite using the credentials
    omdadmin:omd
    
    Use http://172.16.100.60/demosite/graylogapi/graylog/alerts/1?apikey=123456 for
    HTTP alerts from graylog streams"
    
    # splunk01
    vagrant up splunk01
    echo "Splunk is now available at http://172.16.100.70:8000"
fi
