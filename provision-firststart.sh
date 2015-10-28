#!/bin/bash


NODE=${1:?'no node'}
PROXY=${2:-unset}


systemctl start graylog-server
systemctl start graylog-web


if [[ "${NODE}" == "glog01" ]]; then
	# wait for graylog-server to be started
	for x in $(seq 60); do
		curl -XGET http://admin:admin@172.16.100.53:12900/system/inputs --silent
	    [ $? == 0 ] && break;
	    printf "."
	    sleep 0.5;
	done
	# create syslog tcp input on port 10514
	curl -XPOST http://admin:admin@172.16.100.53:12900/system/inputs -d @/vagrant/create_input.json --header "Content-Type: application/json"
fi
