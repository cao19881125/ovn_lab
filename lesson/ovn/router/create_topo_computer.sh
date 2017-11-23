#!/bin/bash -x

function add_vm2(){
ip netns add vm2
ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
ip link set vm2 address 02:ac:10:ff:01:31
ip link set vm2 netns vm2
ovs-vsctl set Interface vm2 external_ids:iface-id=ls2-vm2
pkill dhclient
ip netns exec vm2 dhclient vm2
}


ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

stop_ovn_controller.sh
start_ovn_controller.sh

add_vm2
