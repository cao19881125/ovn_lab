#!/bin/bash -x

docker network rm ovnnet_local
docker network rm ovnnet_outer

docker network create --gateway 10.10.0.1 --subnet 10.10.0.0/24 -o --mtu=1442 ovnnet_local
docker network create -o --mtu=1442 ovnnet_outer
docker-compose up --force-recreate -d