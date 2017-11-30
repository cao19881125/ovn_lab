#!/bin/bash -x

ovs-vsctl add-br br-int
ovs-vsctl add-port br-int eth0
ovs-vsctl add-port br-int eth0.90 -- set interface eth0.90 type=internal -- set port eth0.90 tag=90
ip address add 192.168.200.101/24 dev eth0.90
ip address del 192.168.200.101/24 dev eth0
ip link set eth0.90 up
ovs-vsctl add-port br-int eth0.1 -- set interface eth0.1 type=internal -- set port eth0.1 tag=1
ip address add 192.168.10.10/24 dev eth0.1
ip link set eth0.1 up

ip route add 192.168.10.0/24 via 192.168.200.111
