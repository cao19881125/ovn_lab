#!/bin/bash -x

function add_vm2(){
ip netns add vm2
ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
ip link set vm2 address 02:ac:10:ff:01:31
ip link set vm2 netns vm2
ovs-vsctl set Interface vm2 external_ids:iface-id=ls2-vm2
ip netns exec vm2 ip address add 10.0.0.20/24 dev vm2
ip netns exec vm2 ip link set vm2 up
}

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:0.0.0.0:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ovn-nbctl ls-add lswitch2


ovn-nbctl lsp-add lswitch2 ls2-vm2
ovn-nbctl lsp-set-addresses ls2-vm2 "02:ac:10:ff:01:31 10.0.0.20"
ovn-nbctl lsp-set-port-security ls2-vm2 "02:ac:10:ff:01:31 10.0.0.20"

dhcp_sw2=`ovn-nbctl create DHCP_Options cidr=10.0.0.0/24 options="\"server_id\"=\"10.0.0.1\" \"server_mac\"=\"52:54:00:c1:68:51\" \"lease_time\"=\"3600\" \"router\"=\"10.0.0.1\""`

ovn-nbctl lsp-set-dhcpv4-options ls2-vm2 $dhcp_sw2

add_vm2

ovs-vsctl add-br br-tunnel

ovs-vsctl add-port br-tunnel tp1 -- set interface tp1 type=internal

ovs-vsctl add-port br-tunnel p1 -- set interface p1 type=patch options:peer=p2
ovs-vsctl add-port br-int p2 -- set interface p2 type=patch options:peer=p1

ovn-nbctl lsp-add lswitch2 ls-patch
ovn-nbctl lsp-set-addresses ls-patch unknown

ovs-vsctl set Interface p2 external_ids:iface-id=ls-patch

ip address add 10.0.0.200/24 dev tp1

ip link set tp1 up

ovs-vsctl add-port br-tunnel vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=10.10.0.10 options:key=100
