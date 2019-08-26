#!/bin/bash -x

function add_vm1() {
    ip netns add vm1
    ovs-vsctl add-port switch vm1 -- set interface vm1 type=internal
    ip link set vm1 address 02:ac:10:ff:01:30
    ip link set vm1 netns vm1
    ip netns exec vm1 ip link set vm1 up
    ip netns exec vm1 ip address add 10.20.1.100/24 dev vm1
}

function add_vm2() {
    ip netns add vm2
    ovs-vsctl add-port switch vm2 -- set interface vm2 type=internal
    ip link set vm2 address 02:ac:10:ff:01:31
    ip link set vm2 netns vm2
    ip netns exec vm2 ip link set vm2 up
    ip netns exec vm2 ip address add 10.20.2.100/24 dev vm2
}

ovs-vsctl add-br switch -- set Bridge switch fail-mode=secure

add_vm1

add_vm2
