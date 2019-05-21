#!/bin/bash -x

docker network rm onos_network
docker network create --gateway 10.10.0.1 --subnet 10.10.0.0/24 -o --mtu=1442 onos_network
docker-compose up --force-recreate -d
