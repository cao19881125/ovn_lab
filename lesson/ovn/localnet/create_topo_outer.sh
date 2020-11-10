#!/bin/bash -x

/usr/share/openvswitch/scripts/ovs-ctl start --system-id=random

ovs-vsctl --may-exist add-br br-ext1
ovs-vsctl br-set-external-id br-ext1 bridge-id br-ext1
ovs-vsctl add-port br-ext1 eth1

ovs-vsctl add-port br-ext1 bm1 tag=10 -- set interface bm1 type=internal
ip link set bm1 address 02:ac:10:ff:01:03
ip netns add bm1
ip link set bm1 netns bm1
ip netns exec bm1 ip link set bm1 up
ip netns exec bm1 ip address add 192.168.1.5/24 dev bm1
ip netns exec bm1 ip route add default via 192.168.1.1

ovs-vsctl add-port br-ext1 bm2 tag=10 -- set interface bm2 type=internal
ip link set bm2 address 02:ac:10:ff:01:04
ip netns add bm2
ip link set bm2 netns bm2
ip netns exec bm2 ip link set bm2 up
ip netns exec bm2 ip address add 192.168.1.6/24 dev bm2
ip netns exec bm2 ip route add default via 192.168.1.1

ovs-vsctl add-port br-ext1 bm3 tag=20 -- set interface bm3 type=internal
ip link set bm3 address 02:ac:10:ff:01:05
ip netns add bm3
ip link set bm3 netns bm3
ip netns exec bm3 ip link set bm3 up
ip netns exec bm3 ip address add 192.168.2.5/24 dev bm3
ip netns exec bm3 ip route add default via 192.168.2.1

ovs-vsctl add-port br-ext1 bm4 tag=20 -- set interface bm4 type=internal
ip link set bm4 address 02:ac:10:ff:01:06
ip netns add bm4
ip link set bm4 netns bm4
ip netns exec bm4 ip link set bm4 up
ip netns exec bm4 ip address add 192.168.2.6/24 dev bm4
ip netns exec bm4 ip route add default via 192.168.2.1