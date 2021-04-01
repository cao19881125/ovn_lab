#!/bin/bash -x

docker network create --gateway 10.10.0.1 --subnet 10.10.0.0/24 -o -mtu=1442 ovnnet_local
docker network create --gateway 10.20.0.1 --subnet 10.20.0.0/24 -o -mtu=1442 ovnnet_outer
docker-compose up --force-recreate -d

docker exec -it ovn-ctrl /root/create_topo_ctrl.sh
docker exec -it ovn-gw1 /root/create_topo_gw1.sh
docker exec -it ovn-gw2 /root/create_topo_gw2.sh
docker exec -it ovn-hv1 /root/create_topo_hv1.sh
docker exec -it ovn-hv2 /root/create_topo_hv2.sh
docker exec -it ovn-outer /root/create_topo_outer.sh