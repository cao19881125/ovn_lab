#!/bin/bash

containers=(ovn-ctrl ovn-gw1 ovn-gw2 ovn-hv1 ovn-hv2 ovn-outer)

for container in ${containers[@]};do
    docker stop $container
    docker rm $container
done

docker network rm ovnnet_local
docker network rm ovnnet_outer
