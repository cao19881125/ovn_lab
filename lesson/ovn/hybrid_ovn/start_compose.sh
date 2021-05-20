#!/bin/bash -x

docker network rm ovnnet_local
docker network create --gateway 10.10.0.1 --subnet 10.10.0.0/24 -o --mtu=1442 ovnnet_local
docker-compose up --force-recreate -d
