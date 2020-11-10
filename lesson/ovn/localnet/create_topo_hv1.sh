#!/bin/bash -x

/usr/share/openvswitch/scripts/ovs-ctl start --system-id=random
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure

ovs-vsctl set open . external-ids:ovn-bridge=br-int
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller


function add_vm1() {
    ip netns add vm1
    ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
    ip link set vm1 netns vm1
    ip netns exec vm1 ip link set vm1 address 00:00:01:01:02:0a
    ip netns exec vm1 ip addr add 192.168.1.3/24 dev vm1
    ip netns exec vm1 ip link set vm1 up
    ip netns exec vm1 ip route add default via 192.168.1.1
    ovs-vsctl set Interface vm1 external_ids:iface-id=vm1
}

function add_vm2() {
    ip netns add vm2
    ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
    ip link set vm2 netns vm2
    ip netns exec vm2 ip link set vm2 address 00:00:01:01:02:0b
    ip netns exec vm2 ip addr add 192.168.2.3/24 dev vm2
    ip netns exec vm2 ip link set vm2 up
    ip netns exec vm2 ip route add default via 192.168.2.1
    ovs-vsctl set Interface vm2 external_ids:iface-id=vm2
}

add_vm1
add_vm2

ovs-vsctl --may-exist add-br br-ext1
ovs-vsctl br-set-external-id br-ext1 bridge-id br-ext1
ovs-vsctl add-port br-ext1 eth1

ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext1:br-ext1