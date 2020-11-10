#!/bin/bash -x

/usr/share/openvswitch/scripts/ovs-ctl start 
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl br-set-external-id br-int bridge-id br-int

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:system-id=gw
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl --may-exist add-br br-ext1
ovs-vsctl br-set-external-id br-ext1 bridge-id br-ext1

ovs-vsctl add-port br-ext1 bm1 -- set interface bm1 type=internal
ip link set bm1 address 02:ac:10:ff:01:03
ip netns add bm1
ip link set bm1 netns bm1
ip netns exec bm1 ip link set bm1 up
ip netns exec bm1 ip address add 192.168.1.5/24 dev bm1
ip netns exec bm1 ip route add default via 192.168.1.1

ovs-vsctl add-port br-ext1 bm2 -- set interface bm2 type=internal
ip link set bm2 address 02:ac:10:ff:01:04
ip netns add bm2
ip link set bm2 netns bm2
ip netns exec bm2 ip link set bm2 up
ip netns exec bm2 ip address add 192.168.1.6/24 dev bm2
ip netns exec bm2 ip route add default via 192.168.1.1

ovs-vsctl --may-exist add-br br-ext2
ovs-vsctl br-set-external-id br-ext2 bridge-id br-ext2

ovs-vsctl add-port br-ext2 bm3 -- set interface bm3 type=internal
ip link set bm3 address 02:ac:10:ff:01:05
ip netns add bm3
ip link set bm3 netns bm3
ip netns exec bm3 ip link set bm3 up
ip netns exec bm3 ip address add 192.168.2.5/24 dev bm3
ip netns exec bm3 ip route add default via 192.168.2.1

ovs-vsctl add-port br-ext2 bm4 -- set interface bm4 type=internal
ip link set bm4 address 02:ac:10:ff:01:06
ip netns add bm4
ip link set bm4 netns bm4
ip netns exec bm4 ip link set bm4 up
ip netns exec bm4 ip address add 192.168.2.6/24 dev bm4
ip netns exec bm4 ip route add default via 192.168.2.1

ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext1:br-ext1,ext2:br-ext2
