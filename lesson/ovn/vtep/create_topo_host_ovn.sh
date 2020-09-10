#!/bin/bash -x


function add_vm1(){

ip netns add vm1
ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
ip link set vm1 address 02:ac:10:ff:01:30
ip link set vm1 netns vm1
ovs-vsctl set Interface vm1 external_ids:iface-id=inside-vm1
pkill dhclient
ip netns exec vm1 dhclient vm1

}

function add_vm2(){
ip netns add vm2
ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
ip link set vm2 address 02:ac:10:ff:01:31
ip link set vm2 netns vm2
ovs-vsctl set Interface vm2 external_ids:iface-id=inside-vm2
pkill dhclient
ip netns exec vm2 dhclient vm2
}

function add_br_int(){
ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:127.0.0.1:6642
ovs-vsctl set open . external-ids:ovn-encap-type=vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=10.10.0.10
ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0
}

add_br_int
stop_ovn_controller.sh
start_ovn_controller.sh

LOCAL_CHASSIS=`ovn-sbctl show | grep Chassis | awk '{print $2}' | sed 's/"//g'`

#ovn-nbctl lr-add router1
ovn-nbctl create Logical_Router name=router1 options:chassis=$LOCAL_CHASSIS
#ovn-nbctl create Logical_Router name=router1 options:chassis=br0
ovn-nbctl ls-add inside
ovn-nbctl lrp-add router1 router1-inside 02:ac:10:ff:00:01 10.0.0.100/24
ovn-nbctl lsp-add inside inside-router1
ovn-nbctl lsp-set-type inside-router1 router
ovn-nbctl lsp-set-addresses inside-router1 02:ac:10:ff:00:01
ovn-nbctl lsp-set-options inside-router1 router-port=router1-inside
ovn-nbctl lsp-add inside inside-vm1
ovn-nbctl lsp-set-addresses inside-vm1 "02:ac:10:ff:01:30 10.0.0.1"
ovn-nbctl lsp-set-port-security inside-vm1 "02:ac:10:ff:01:30 10.0.0.1"

ovn-nbctl lsp-add inside inside-vm2
ovn-nbctl lsp-set-addresses inside-vm2 "02:ac:10:ff:01:31 10.0.0.2"
ovn-nbctl lsp-set-port-security inside-vm2 "02:ac:10:ff:01:31 10.0.0.2"
dhcptemp=`ovn-nbctl create DHCP_Options cidr=10.0.0.0/24 options="\"server_id\"=\"10.0.0.100\" \"server_mac\"=\"02:ac:10:ff:01:29\" \"lease_time\"=\"3600\" \"router\"=\"10.0.0.100\""`

ovn-nbctl lsp-set-dhcpv4-options inside-vm1 $dhcptemp
ovn-nbctl lsp-set-dhcpv4-options inside-vm2 $dhcptemp

add_vm1
add_vm2

ovn-nbctl lsp-add inside inside-vtep-gateway
ovn-nbctl lsp-set-addresses inside-vtep-gateway "02:ac:10:ff:01:03 10.0.0.3"
ovn-nbctl lsp-set-type inside-vtep-gateway vtep
ovn-nbctl lsp-set-options inside-vtep-gateway vtep-physical-switch=br0 vtep-logical-switch=ls0
ovn-nbctl lsp-set-dhcpv4-options inside-vtep-gateway $dhcptemp
