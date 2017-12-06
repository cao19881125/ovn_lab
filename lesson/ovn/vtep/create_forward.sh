#!/bin/bash -x

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

ovs-vsctl add-br br-int

ovs-vsctl add-port br-int forward-gateway -- set interface forward-gateway type=internal
ip link set forward-gateway address 02:ac:10:ff:11:03
ip link set forward-gateway netns gateway
ip netns exec gateway ip link set forward-gateway up
ip netns exec gateway ip address add 10.0.1.3/24 dev forward-gateway

ovs-vsctl add-port br-int forward-ns1 -- set interface forward-ns1 type=internal
ip link set forward-ns1 address 02:ac:10:ff:11:01
ip netns add forward-ns1
ip link set forward-ns1 netns forward-ns1
ip netns exec forward-ns1 ip link set forward-ns1 up
ip netns exec forward-ns1 ip address add 10.0.1.1/24 dev forward-ns1
ip netns exec forward-ns1 ip route add 10.0.0.0/24 via 10.0.1.3

ovs-vsctl add-port br-int forward-ns2 -- set interface forward-ns2 type=internal
ip link set forward-ns2 address 02:ac:10:ff:11:02
ip netns add forward-ns2
ip link set forward-ns2 netns forward-ns2
ip netns exec forward-ns2 ip link set forward-ns2 up
ip netns exec forward-ns2 ip address add 10.0.1.2/24 dev forward-ns2
ip netns exec forward-ns2 ip route add 10.0.0.0/24 via 10.0.1.3
