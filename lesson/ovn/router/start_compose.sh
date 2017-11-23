#!/bin/bash -x

docker network rm ovnnet
docker network create --gateway 10.10.0.1 --subnet 10.10.0.0/24 ovnnet
docker-compose up --force-recreate
