#!/bin/bash -x

ETH=`ip -o a | grep 192.168.200.1 | awk '{print $2}'`

ovs-vsctl add-br br-int
ovs-vsctl add-port br-int $ETH
ovs-vsctl add-port br-int net.90 -- set interface net.90 type=internal -- set port net.90 tag=90
ip address del 192.168.200.1/24 dev $ETH
ip address add 192.168.200.1/24 dev net.90
ip link set net.90 up

