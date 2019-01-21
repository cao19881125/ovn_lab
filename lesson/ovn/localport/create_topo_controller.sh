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

function add_em1(){
ip link add em1 type veth peer name em1-1
ip link set em1 address 02:ac:10:ff:01:35
ovs-vsctl add-port br-int em1-1
ovs-vsctl set Interface em1-1 external_ids:iface-id=ls1-em1
ip link set em1-1 up
pkill dhclient
dhclient em1
}

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:0.0.0.0:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

stop_ovn_controller.sh
start_ovn_controller.sh

LOCAL_CHASSIS=`ovn-sbctl show | grep Chassis | awk '{print $2}' | sed 's/"//g' | awk 'NR==1{print}'`
ovn-nbctl create Logical_Router name=router options:chassis=$LOCAL_CHASSIS
ovn-nbctl ls-add lswitch1
ovn-nbctl ls-add lswitch2

ovn-nbctl lrp-add router lr-ls1 52:54:00:c1:68:50 10.0.0.1/24
ovn-nbctl lrp-add router lr-ls2 52:54:00:c1:68:60 10.1.0.1/24

ovn-nbctl lsp-add lswitch1 ls1-lr1
ovn-nbctl lsp-set-type ls1-lr1 router
ovn-nbctl lsp-set-addresses ls1-lr1 52:54:00:c1:68:50
ovn-nbctl lsp-set-options ls1-lr1 router-port=lr-ls1


ovn-nbctl lsp-add lswitch2 ls2-lr1
ovn-nbctl lsp-set-type ls2-lr1 router
ovn-nbctl lsp-set-addresses ls2-lr1 52:54:00:c1:68:60
ovn-nbctl lsp-set-options ls2-lr1 router-port=lr-ls2

ovn-nbctl lsp-add lswitch1 ls1-vm1
ovn-nbctl lsp-set-addresses ls1-vm1 "02:ac:10:ff:01:30 10.0.0.10"
ovn-nbctl lsp-set-port-security ls1-vm1 "02:ac:10:ff:01:30 10.0.0.10"

ovn-nbctl lsp-add lswitch2 ls2-vm2
ovn-nbctl lsp-set-addresses ls2-vm2 "02:ac:10:ff:01:31 10.1.0.20"
ovn-nbctl lsp-set-port-security ls2-vm2 "02:ac:10:ff:01:31 10.1.0.20"

ovn-nbctl lsp-add lswitch1 ls1-em1
ovn-nbctl lsp-set-addresses ls1-em1 "02:ac:10:ff:01:35 10.0.0.100"

dhcp_sw1=`ovn-nbctl create DHCP_Options cidr=10.0.0.0/24 options="\"server_id\"=\"10.0.0.1\" \"server_mac\"=\"52:54:00:c1:68:50\" \"lease_time\"=\"3600\" \"router\"=\"10.0.0.1\""`
dhcp_sw2=`ovn-nbctl create DHCP_Options cidr=10.1.0.0/24 options="\"server_id\"=\"10.1.0.1\" \"server_mac\"=\"52:54:00:c1:68:60\" \"lease_time\"=\"3600\" \"router\"=\"10.1.0.1\""`

ovn-nbctl lsp-set-dhcpv4-options ls1-vm1 $dhcp_sw1
ovn-nbctl lsp-set-dhcpv4-options ls2-vm2 $dhcp_sw2
ovn-nbctl lsp-set-dhcpv4-options ls1-em1 $dhcp_sw1

add_vm1

add_em1
