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

function add_vm3() {
    ip netns add vm3
    ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
    ip link set vm3 netns vm3
    ip netns exec vm3 ip link set vm3 address 00:00:01:01:02:08
    ip netns exec vm3 ip addr add 192.168.1.4/24 dev vm3
    ip netns exec vm3 ip link set vm3 up
    ip netns exec vm3 ip route add default via 192.168.1.1
    ovs-vsctl set Interface vm3 external_ids:iface-id=vm3
}

function add_vm4() {
    ip netns add vm4
    ovs-vsctl add-port br-int vm4 -- set interface vm4 type=internal
    ip link set vm4 netns vm4
    ip netns exec vm4 ip link set vm4 address 00:00:01:01:02:09
    ip netns exec vm4 ip addr add 192.168.2.4/24 dev vm4
    ip netns exec vm4 ip link set vm4 up
    ip netns exec vm4 ip route add default via 192.168.2.1
    ovs-vsctl set Interface vm4 external_ids:iface-id=vm4
}

add_vm3
add_vm4

ovs-vsctl --may-exist add-br br-ext1
ovs-vsctl br-set-external-id br-ext1 bridge-id br-ext1
ovs-vsctl add-port br-ext1 eth1

ovs-vsctl set open . external-ids:ovn-bridge-mappings=ext1:br-ext1
