#!/bin/bash -x

function add_vm1(){
ip netns add vm1
ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 address 02:ac:10:ff:01:30
ip link set vm1 netns vm1
ovs-vsctl set Interface vm1 external_ids:iface-id=ls1-vm1
ip netns exec vm1 ip address add 10.0.0.10/24 dev vm1
ip netns exec vm1 ip link set vm1 up
}

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:0.0.0.0:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ovn-nbctl ls-add lswitch1


ovn-nbctl lsp-add lswitch1 ls1-vm1
ovn-nbctl lsp-set-addresses ls1-vm1 "02:ac:10:ff:01:30 10.0.0.10"
ovn-nbctl lsp-set-port-security ls1-vm1 "02:ac:10:ff:01:30 10.0.0.10"



add_vm1

ovs-vsctl add-br br-tunnel

ovs-vsctl add-port br-tunnel tp1 -- set interface tp1 type=internal

ovs-vsctl add-port br-tunnel p1 -- set interface p1 type=patch options:peer=p2
ovs-vsctl add-port br-int p2 -- set interface p2 type=patch options:peer=p1

ovn-nbctl lsp-add lswitch1 ls-patch
ovn-nbctl lsp-set-addresses ls-patch unknown

ovs-vsctl set Interface p2 external_ids:iface-id=ls-patch

ip address add 10.0.0.100/24 dev tp1

ip link set tp1 up

ovs-vsctl add-port br-tunnel vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=10.10.0.20 options:key=100
