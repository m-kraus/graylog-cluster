# Graylog demo cluster

This project emerged from an research & development task kindly sponsored by [ConSol* Consulting & Solutions](https://www.consol.de/).

## Created virtual machines

- __glog01__ (172.16.100.53):
  - Elasticsearch: http://172.16.100.53:9200/_plugin/kopf/
  - MongoDB (primary)
  - Graylog (master): http://172.16.100.53 (admin:admin)
  - HAProxy: 172.16.100.53:514, distributes incoming TCP syslog messages round-robin to glog01/glog02/glog03:10514

- __glog02__ (172.16.100.54):
  - Elasticsearch: http://172.16.100.54:9200/_plugin/kopf/
  - MongoDB
  - Graylog: http://172.16.100.54 (admin:admin)
  - HAProxy: 172.16.100.54:514, distributes incoming TCP syslog messages round-robin to glog01/glog02/glog03:10514

- __glog03__ (172.16.100.55):
  - Elasticsearch: http://172.16.100.55:9200/_plugin/kopf/
  - MongoDB
  - Graylog: http://172.16.100.55 (admin:admin)
  - HAProxy: 172.16.100.55:514, distributes incoming TCP syslog messages round-robin to glog01/glog02/glog03:10514

- [ __omd01__ (172.16.100.60) ]:
  - OMD: http://172.16.100.60/demosite (omdadmin:omd)
  - URL for sending stream-alerts via HTTP to graylogapi on omd01: http://172.16.100.60/demosite/graylogapi/graylog/alerts/1?apikey=123456

- [ __splunk01__ (172.16.100.70) ]:
  - Splunk: http://172.16.100.70:8000

## Graylog demo cluster setup

You need to have git, Virtualbox and Vagrant installed, to run this demo cluster.

First of all clone this repository:
```
git clone https://github.com/m-kraus/graylog-cluster.git && cd graylog-cluster/
```

A reproducible installation of a graylog cluster has to be a done in a certain order. For this purpose ```setup.sh``` calls the steps of ```vagrant up``` and ```vagrant --provision-with``` in the necessary order.

To bring up the whole demo cluster, simply type
```
./setup.sh
```

Furthermore ```setup.sh``` downloads the needed packages of Graylog, Elasticsearch and others and stores them in the ```cache``` subfolder for later reuse.

The nodes ```omd01``` and ```splunk01``` are not created automatically. Use the switch ```-o``` to create the node ```omd01``` and the switch ```-s``` to create the node ```splunk01```:
```
./setup.sh [-o] [-s]
```

To install Splunk on the node ```splunk01```, you have to download the RPM for x86_64 from http://de.splunk.com/download manually and put it into the directory ```cache```. The installation has been tested with version ```splunk-6.2.5-272645-linux-2.6-x86_64.rpm```.

To start or stop the demo cluster, you can use ```start.sh``` or ```stop.sh```:
```
./start.sh [-o] [-s]
./stop.sh
```

## Installation scripts

### Graylog nodes

The necessary installation steps are kept as simple shell scripts within the vagrant provisioning scripts ```provision-node.sh``` and ```provision-firststart.sh```.

The script ```node-firststart.sh``` creates also a syslog TCP input listening on port 10514 using the HTTP REST API of Graylog. See the JSON payload in ```create_input.json```.

Each node is configured to send its syslog messages via rsyslog to Graylog using this configuration in ```/etc/rsyslog.d/10-glog.conf```:
```
$PreserveFQDN on
 
 $template GRAYLOGRFC5424,"<%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% %app-name% %procid% %msg%\n"
 *.* @@172.16.100.5X:10514;GRAYLOGRFC5424
```

### OMD Labs Edition

For further information about [OMD Labs Edition](https://labs.consol.de/de/omd/) see [https://labs.consol.de/de/omd/](https://labs.consol.de/de/omd/).

The necessary installation and configuration steps are kept in ```provision-omd.sh```.

An OMD site called ```demosite``` will be created and the current proof-of-concept of the ```graylogapi``` REST_API to receive Graylog alerts will be installed.

Sample health checks for the Graylog cluster are also preinstalled.

TODO describe health checks

## Recommendations

Graylog server runs as user ```graylog```, so opening privileged ports (<1024) is not permitted without additional effort. To ease the reception of syslog messages on the standard port, HAProxy is installed on all 3 nodes of the demo cluster. It redirects incoming messages from port 514 (TCP) round-robin to all three nodes on port port 10514 (TCP).
Forwarding incoming messages on port 514 (UDP) is not possible in the demo cluster. For a production environment, a load balancer is recommended to forward incoming TCP and UDP messages.

TODO describe firewall settings

### Configuration

The configuration files are kept for reference in the subfolders ```node_glog01```, ```node_glog02``` and ```node_glog03```.

### Common

- NTP has to be configured. The demo cluster uses time synchronization features of Virtualbox, which should be sufficient for this purpose.

### Elasticsearch

The following setting have to be configured in ```/etc/elasticsearch/elasticsearch.yml```:

- set ```network.host: 172.16.100.53``` explicitly.

- define the cluster name using ```cluster.name: graylog2```.

- ```node.name: "elasticsearch_glog0X"``` should be set for easier identification of Elasticsearch nodes.

- A cluster of equal Elasticsearch nodes has to have ```discovery.zen.minimum_master_nodes: 2``` set, otherwise the nodes won't connect reliably. 

- The following settings are also needed for reliable clustering:
  - ```discovery.zen.ping.timeout: 30```
  - ```discovery.zen.ping.multicast.enabled: false```
  - ```discovery.zen.ping.unicast.hosts: ["172.16.100.53:9300", "172.16.100.54:9300", "172.16.100.55:9300"]```

- Installation of a web based UI is recommended, in this demo setup we use  https://github.com/lmenezes/elasticsearch-kopf

- Using 3 Elasticsearch nodes simplifies rolling updates and restarts. Elasticsearch sharding with replicas needs more nodes as well.

- For Elasticsearch you should have focus on spaciously dimensioned and fast disk space, as well as a reasonable amount of memory.

The Elasticsearch docs provide helpful information for [Full cluster restarts](https://www.elastic.co/guide/en/elasticsearch/reference/current/restart-upgrade.html) and [Rolling upgrades](https://www.elastic.co/guide/en/elasticsearch/reference/current/rolling-upgrades.html). Especially disabling shard relocation is quite important, since it prevents wasting a lot of unnecessary IO.

### Graylog server

The following settings have to be configured in ```/etc/graylog/server/server.conf```:

- Exactly one Graylog node needs to have ```is_master = true``` set.

- Settings for Elasticsearch have to be identical as in the Elasticsearch configuration file:
  - ```elasticsearch_cluster_name = graylog2```
  - ```elasticsearch_discovery_zen_ping_multicast_enabled = false```
  - ```elasticsearch_discovery_zen_ping_unicast_hosts = 172.16.100.53:9300,172.16.100.54:9300,172.16.100.55:9300```
  - ```elasticsearch_cluster_discovery_timeout = 30000```
  - ```elasticsearch_network_host = 172.16.100.53```
  - ```elasticsearch_discovery_initial_state_timeout = 30s```

- configure the desired sharding strategy using ```elasticsearch_shards = 5``` and ```elasticsearch_replicas = 1```

- ```elasticsearch_node_name =  "graylog_glog0X"``` should be set for easier identification of Graylog nodes within Elasticsearch.

- set ```password_secret = ...``` as described in the configuration file using ```pwgen -N 1 -s 96``` to the same value on all nodes.

- set ```root_username = ...``` and ```root_password_sha2 = ...``` to the same value on all nodes. As described in the configuration file you can use ```echo -n yourpassword | shasum -a 256``` to generate the password hash.

- configure how to reach the MongoDB replica set using ```mongodb_uri = mongodb://172.16.100.53:27017,172.16.100.54:27017,172.16.100.55:27017/graylog2```

- Graylog nodes have to have access to the same MongoDB database or to a MongoDB replica set, to be able to form a cluster.

- Using 3 Graylog nodes simplifies rolling updates or restarts.

- When you have to bootstrap the whole demo cluster, you should have an eye if Graylog is started correctly, since it has to reach Elasticsearch and the MongoDB replica set in a timely manner. If not, a simple ```systemctl restart graylog-server``` and ```systemctl restart graylog-web``` should be enough. 


### MongoDB

- For a high availability setup, it is recommended to configure MongoDB as a replica set. See the script ```provision-node.sh``` for details.

- Configure the MongoDB PRIMARY on the Graylog ```master``` node.

- You may keep the MongoDB journal files small configuring ```smallfiles=true```

### Graylog web interface

- Can run on a single or on each Graylog node. Load balancing or running behind a proxy is possible.

- From a performance perspective it makes sense, running the web interface on separate nodes.

## Simple throughput tests

Short tests on a Macbook Pro using this demo cluster showed a maximum throughput of about 700 messages per second. The fast SSD of the Macbook surely helped a lot here.

We used the tool ```loggen``` from the ```syslog-ng```-project using the following call from all 3 nodes:
```
/vagrant/loggen --size 300 --rate 300 --interval 600 --syslog-proto 127.0.0.1 10514 --loop-reading --read-file=/vagrant/sample.log
```

The syslog TCP input was activated on all 3 nodes without any changes.
