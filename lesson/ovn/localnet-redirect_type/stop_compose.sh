#!/bin/bash

docker-compose down

docker network rm ovnnet_local
docker network rm ovnnet_outer
docker network rm ovnnet_physical
