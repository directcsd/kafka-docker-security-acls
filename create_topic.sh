#/bin/bash

kafka-topics --bootstrap-server localhost:9093 --create --topic first_topic --command-config client-properties/adminclient.properties --partitions 1 --replication-factor 1

kafka-acls --bootstrap-server localhost:9093 --command-config client-properties/adminclient.properties --topic first_topic --allow-principal User:producer --producer --add

kafka-acls --bootstrap-server localhost:9093 --command-config client-properties/adminclient.properties --topic first_topic --allow-principal User:consumer --consumer --add --group "*"
