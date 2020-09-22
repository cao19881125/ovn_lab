#!/bin/bash -x

function add_vm1(){
    ip netns add vm1
    ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
    ip link set vm1 address 02:ac:10:ff:01:30
    ip link set vm1 netns vm1
    ovs-vsctl set Interface vm1 external_ids:iface-id=ls1-vm1
    pkill dhclient
    ip netns exec vm1 dhclient vm1
}

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

add_vm1