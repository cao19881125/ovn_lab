#!/bin/sh

docker exec -it ovn-ctrl /root/create_topo_ctrl.sh

docker exec -it ovn-gw /root/create_topo_gw.sh

docker exec -it ovn-hv1 /root/create_topo_hv1.sh

docker exec -it ovn-hv2 /root/create_topo_hv2.sh