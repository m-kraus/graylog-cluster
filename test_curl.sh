#!/bin/bash

curl -vX POST http://172.16.100.60/demosite/graylogapi/graylog/alerts/1?apikey=123456 -d @test_curl.json --header "Content-Type: application/json"
