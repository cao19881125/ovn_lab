#!/bin/bash -x

function add_vm(){
ip netns add $1
ovs-vsctl add-port br-int $1 -- set interface $1 type=internal
ip link set $1 netns $1
ip netns exec $1 ip address add 172.0.0.$2/24 dev $1
ip netns exec $1 ip link set $1 up
}


ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set-controller br-int tcp:$ONOS_IP:6653


add_vm vm1 1
add_vm vm2 2

ovs-vsctl add-port br-int vx1 -- set Interface vx1 type=vxlan options:remote_ip=$VXLAN_REMOTE

