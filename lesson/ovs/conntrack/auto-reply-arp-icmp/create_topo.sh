#!/bin/bash -x

function add_vm1(){
ip netns add vm1
ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 address 02:ac:10:ff:01:30
ip link set vm1 netns vm1
ip netns exec vm1 ip link set vm1 up
ip netns exec vm1 ip address add 10.0.0.10/24 dev vm1
}


ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

add_vm1

