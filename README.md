# Maschinen

- glog01 (172.16.100.53):
  - Elasticsearch: http://172.16.100.53:9200/_plugin/kopf/
  - MongoDB (primary)
  - Graylog (master): http://172.16.100.53 (admin:admin)
  - HAProxy: 172.16.100.53:514, verteilt Round-Robin auf glog01/glog02/glog03:10514

- glog02 (172.16.100.54):
  - Elasticsearch: http://172.16.100.54:9200/_plugin/kopf/
  - MongoDB
  - Graylog: http://172.16.100.54 (admin:admin)
  - HAProxy: 172.16.100.54:514, verteilt Round-Robin auf glog01/glog02/glog03:10514

- glog03 (172.16.100.55):
  - Elasticsearch: http://172.16.100.55:9200/_plugin/kopf/
  - MongoDB
  - Graylog: http://172.16.100.55 (admin:admin)
  - HAProxy: 172.16.100.55:514, verteilt Round-Robin auf glog01/glog02/glog03:10514

- omd01 (172.16.100.60):
  - OMD: http://172.16.100.60/demosite (omdadmin:omd)
  - URL für stream-alerts via HTTP: http://172.16.100.60/demosite/graylogapi/graylog/alerts/1?apikey=123456

- splunk01 (172.16.100.70):
  - Splunk: http://172.16.100.70:8000


# Graylog Cluster Setup

## Vagrant

Da zur reprodzierbaren Installation von Graylog ein Workaround notwendig ist, ist das initiale Setup der Maschinen im Skript ```setup.sh``` gebündelt, das die Provisionierungss-Skripten in der notwendigen Reihenfolge ausführt.

```
./setup.sh
```

Zur Installation von Splunk muss das RPM für x86_64 von http://de.splunk.com/download heruntergeladen und ins Verzeichnis ```cache``` gelegt werden. Getestet wurde die Installation mit der Version ```splunk-6.2.5-272645-linux-2.6-x86_64.rpm```.

Anschließend kann mit ```vagrant up``` der Grayog-Cluster gestartet werden. Die ```omd01``` und ```splunk01``` werden nicht automatisch gestartet. Diese müssen explizit mit ```vagrant up omd01``` oder ```vagrant up splunk01``` gestartet werden.

## Lasttests

Kurze Lasttests auf einem Macbook Pro mit diesem Vagrant-Setup konnten ca. 700 Nachrichten/Sekunde verarbeiten. Die schnelle SSD des Macbook trug hier einen großen Teil bei.

Zum Einsatz kam das Tool ```loggen``` aus dem ```syslog-ng```-Projekt mit diesem Aufruf gleichzeitig auf allen 3 nodes:

```
/vagrant/loggen --size 300 --rate 300 --interval 600 --syslog-proto 127.0.0.1 514 --loop-reading --read-file=/vagrant/sample.log
```

Syslog (TCP) war dazu auf allen 3 nodes ohne weitere Änderungen aktiviert.

## Installationsskripte

### Graylog-Nodes

Die Installationsschritte sind als Shellskripte in ```provision-node.sh``` und ```provision-firststart.sh``` festgehalten.

Da der Graylog-Server anscheinend einmal als ```root``` gestartet werden muss, um korrekt zu funktioneren, wir ihn aber unter dem Benutzer ```graylog``` betreiben, muss ein Workaround verwendet werden: nach der Installation wird der Graylog-Server einmal als ```root``` gestartet und wieder gestoppt, anschließend die Berechtigungen auf den Benutzer ```graylog``` zurückgesetzt.

Um möglichst einfach Syslog-Events über TCP auf Port 514 entgegen nehmen zu können, ist auf allen drei Nodes ain HAProxy installiert, der ankommende Events auf Port 514 im Round-Robin-Verfahren auf alle drei Graylog-Nodes mit dem TCP Port 10514 weiterleitet; da Graylog als Benutzer ```graylog``` läuft, darf der Dienst nicht ohne weiteres privilegierte Ports verwenden. 

### OMD

Die Installationsschritte sind als Shellskript in ```provision-omd.sh``` festgehalten.

Es wird eine Demo-Site ```demosite``` angelegt und der Proof-of-Concept einer REST-API zum Empfang von Graylog-Stream-Alerts in OMD ```graylogapi``` installliert.

Ein beispielhaftes Monitoring des Graylog-Clusters ist ebenfalls mit an Bord.

## Manuelle Installationsskripte

Das Erstellen des Syslog-TCP-Inputs kann leider nicht automatisiert werden. Nach dem ersten Start muss unter http://172.16.100.53/system/inputs mit "Launch new input" ein neuer "Syslog TCP" Input angelegt werden. Der "Title" kann frei gewählt werden, "Port" muss auf 10514 geändert werden und der Haken bei "Global input" gesetzt werden.

## Empfehlungen

### Konfiguration

Die Konfigurationsdateien der beteiligten Komponenten liegen in den Verzeichnissen ```node_glog01```, ```node_glog02``` und ```node_glog03``` und sollten aufmerksam studiert werden.

### Allgemein

- NTP sollte unbedingt korrekt konfiguriert sein. Im Demo-Cluster werden nur Virtualbox-interne Zeitfunktionen benutzt, was aber in diesem Zusammenhang genügt.

### Elasticsearch

Die folgenden Einstellungen sind in ```elasticsearch.yml``` vorzunehmen.

- Der ```cluster.name: graylog2``` muss gesetzt werden.

- Der ```node.name: "elasticsearch_glog01"``` sollte zur leichteren Identifizierbarkeit gesetzt sein.

- Ein Cluster von gleichberechtigten Elasticsearch nodes sollte  ```discovery.zen.minimum_master_nodes: 2``` gesetzt haben, sonst wollen sich die Cluster nicht miteinander in Verbindung setzen.

- Folgende Einstellungen sind für das Clusterung ebenso notwendig:
  - ```discovery.zen.ping.timeout: 30```
  - ```discovery.zen.ping.multicast.enabled: false```
  - ```discovery.zen.ping.unicast.hosts: ["172.16.100.53:9300", "172.16.100.54:9300", "172.16.100.55:9300"]```

- Die Installation einer WebUI ist empfohlen, z.B. https://github.com/lmenezes/elasticsearch-kopf

- Mindestens 3 nodes sind empfohlen; rolling updates oder restarts sind damit sehr einfach möglich.

- Speicherplatz sollte großzügig dimensioniert sein

- Der Arbeitsspeicher für Elasticsearch ist im Demo-Setup auf genau 1GB festgelegt. Elasticsearch reserviert diesen Bereich sofort beim Start.

### Graylog Server

Die folgenden Einstellunge sind in der Konfigurationsdatei des Graylog-Servers vorzunehmen:

- Graylog nodes müssen einen node als ```is_master = true``` konfiguriert haben.

- Die Einstellungen für Elasticsearch müssen übereinstimmen.
  - Graylog nodes müssen den gleichen ```elasticsearch_cluster_name = graylog2``` gesetzt haben.
  - ```elasticsearch_node_name =  "graylog_glog01"``` sollte zur leichteren Identifizierbarkeit gesetzt werden.

- Damit sich Graylog nodes zu einem Cluster zusammenschließen müssen sie auf dieselbe MongoDB-Datenbank zugreifen oder auf ein MongoDB Replica Set zugreifen.

- 3 nodes sind empfohlen; rolling updates oder restarts sind damit einfach möglich.

- Vorsicht ist geboten, wenn man alle Graylog nodes gleichzeitig neu startet. Hierbei kann unter Umständen der graylog-server nicht zuverlässig gestartet werden und muss ggf. manuell per ```systemctl start graylog-server``` wieder aktiviert werden.

### MongoDB

- Die Konfiguration eines MongoDB Replica Sets ist empfohlen.

- Der PRIMARY ist am zweckmäßigsten dort zu setzen, wo auch der Graylog ```master``` konfiguriert ist.

- Um nicht zuviel Speicherplatz durch die Journal-Dateien zu verlieren kann ```smallfiles=true``` gesetzt werden.

- Speicherplatz sollte großzügig dimensioniert sein

### Graylog Webinterface

- Kann auf dem ```master``` mitlaufen, könnte auch mehrfach auf separaten nodes installiert und ggfs. hinter einem Loadbalancer. Dann ist die Konfiguration von LDAP auf allen Webinterfaces empfohlen.

- Aus Performancegründen kann es sinnvoll sein, das Webinterface separat zu betreiben.

