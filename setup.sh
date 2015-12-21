#/bin/bash

OMD=false
SPLUNK=false

while :; do
    case $1 in
        -o)
            OMD=true
            ;;
        -s)
            SPLUNK=true
            ;;
        *)
            break
    esac

    shift
done


# download for caches

#graylog, https://packages.graylog2.org/el/7/
PACKAGE=graylog-server-1.3.1-1.noarch.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/graylog-server.rpm
    curl -v -j -k -L https://packages.graylog2.org/repo/el/7/1.3/x86_64/$PACKAGE > ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE graylog-server.rpm
    popd
fi
PACKAGE=graylog-web-1.3.1-1.noarch.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/graylog-web.rpm
    curl -v -j -k -L https://packages.graylog2.org/repo/el/7/1.3/x86_64/$PACKAGE > ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE graylog-web.rpm
    popd
fi

# epel
PACKAGE=epel-release-7-5.noarch.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/epel.rpm
    curl -v -j -k -L http://download.fedoraproject.org/pub/epel/7/x86_64/e/$PACKAGE > ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE epel.rpm
    popd
fi

# java, http://www.oracle.com/technetwork/java/javase/downloads/index.html
PACKAGE=jre-8u66-linux-x64.rpm
PACKAGEDIR=8u66-b17
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/jre.rpm
    curl -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/$PACKAGEDIR/$PACKAGE > ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE jre.rpm
    popd
fi

#elasticsearch, https://www.elastic.co/downloads/past-releases/
PACKAGE=elasticsearch-1.7.4.noarch.rpm
if [ ! -f ./cache/$PACKAGE ]; then
    rm ./cache/elasticsearch.rpm
    curl -v -j -k -L https://download.elasticsearch.org/elasticsearch/elasticsearch/$PACKAGE > ./cache/$PACKAGE
    pushd ./cache/
    ln -s $PACKAGE elasticsearch.rpm
    popd
fi
PACKAGE=elasticsearch-kopf.zip
if [ ! -f ./cache/$PACKAGE ]; then
    curl -v -j -k -L https://github.com/lmenezes/elasticsearch-kopf/archive/master.zip > ./cache/$PACKAGE
fi

# mongodb
PACKAGE=3.2.0-1.el7.x86_64.rpm
if [ ! -f ./cache/mongodb-org-$PACKAGE ]; then
    rm ./cache/mongodb-org.rpm
    curl -v -j -k -L https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-$PACKAGE > ./cache/mongodb-org-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-$PACKAGE mongodb-org.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-mongos-$PACKAGE ]; then
    rm ./cache/mongodb-org-mongos.rpm
    curl -v -j -k -L https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-mongos-$PACKAGE > ./cache/mongodb-org-mongos-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-mongos-$PACKAGE mongodb-org-mongos.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-server-$PACKAGE ]; then
    rm ./cache/mongodb-org-server.rpm
    curl -v -j -k -L https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-server-$PACKAGE > ./cache/mongodb-org-server-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-server-$PACKAGE mongodb-org-server.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-shell-$PACKAGE ]; then
    rm ./cache/mongodb-org-shell.rpm
    curl -v -j -k -L https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-shell-$PACKAGE > ./cache/mongodb-org-shell-$PACKAGE
    pushd ./cache/
    ln -s mongodb-org-shell-$PACKAGE mongodb-org-shell.rpm
    popd
fi
if [ ! -f ./cache/mongodb-org-tools-$PACKAGE ]; then
    rm ./cache/mongodb-org-tools.rpm
    curl -v -j -k -L https://repo.mongodb.org/yum/redhat/7/mongodb-org/stable/x86_64/RPMS/mongodb-org-tools-$PACKAGE > ./cache/mongodb-org-tools-$PACKAGE
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
if [ "$OMD" = true ]; then
    # omd01
    vagrant up omd01
    echo "OMD:
    OMD is now available at http://172.16.100.60/demosite using the credentials
    omdadmin:omd
    
    Use http://172.16.100.60/demosite/graylogapi/graylog/alerts/1?apikey=123456 for
    HTTP alerts from graylog streams"
fi    
if [ "$SPLUNK" = true ]; then
    # splunk01
    vagrant up splunk01
    echo "Splunk is now available at http://172.16.100.70:8000"
fi
