#!/bin/bash -x

docker network rm net122
docker network rm net200
docker network create --gateway 192.168.122.254 --subnet 192.168.122.0/24 net122
docker network create --gateway 192.168.200.254 --subnet 192.168.200.0/24 net200
docker-compose up --force-recreate
