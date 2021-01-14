#!/bin/bash -x

function add_vm1(){
  ip netns add vm1
  ovs-vsctl add-port br-int vm1 -- set interface vm1 type=internal
  ip link set vm1 address 02:ac:10:ff:01:31
  ip link set vm1 netns vm1
  ip netns exec vm1 ip addr add 1.1.1.2/24 dev vm1
  ip netns exec vm1 ip link set vm1 up
  ip netns exec vm1 sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
  ovs-vsctl set Interface vm1 external_ids:iface-id=ls1-vm1
  ip netns exec vm1 ip route add default via 1.1.1.1 dev vm1
}

function add_vm3(){
  ip netns add vm3
  ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
  ip link set vm3 address 02:ac:10:ff:01:33
  ip link set vm3 netns vm3
  ip netns exec vm3 ip addr add 1.1.1.5/24 dev vm3
  ip netns exec vm3 ip link set vm3 up
  ip netns exec vm3 sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
  ovs-vsctl set Interface vm3 external_ids:iface-id=ls1-vm3
  ip netns exec vm3 ip route add default via 1.1.1.1 dev vm3
}

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:0.0.0.0:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

stop_ovn_controller.sh
start_ovn_controller.sh

sleep 1
LOCAL_CHASSIS=`ovn-sbctl show | grep Chassis | awk '{print $2}' | sed 's/"//g' | awk 'NR==1{print}'`
ovn-nbctl create Logical_Router name=router options:chassis=$LOCAL_CHASSIS

ovn-nbctl lr-add lr1
ovn-nbctl lrp-add lr1 lr1-s1 00:de:ad:ff:01:01 1.1.1.1/24
ovn-nbctl lrp-add lr1 lr1-s2 00:de:ad:ff:01:02 1.1.2.1/24

ovn-nbctl ls-add ls1
ovn-nbctl lsp-add ls1 s1-lr1
ovn-nbctl lsp-set-type s1-lr1 router
ovn-nbctl lsp-set-addresses s1-lr1 00:de:ad:ff:01:01 
ovn-nbctl lsp-set-options s1-lr1 router-port=lr1-s1

ovn-nbctl ls-add ls2
ovn-nbctl lsp-add ls2 s2-lr1
ovn-nbctl lsp-set-type s2-lr1 router
ovn-nbctl lsp-set-addresses s2-lr1 00:de:ad:ff:01:02
ovn-nbctl lsp-set-options s2-lr1 router-port=lr1-s2

ovn-nbctl lsp-add ls1 ls1-vm1
ovn-nbctl lsp-set-addresses ls1-vm1 "02:ac:10:ff:01:31 1.1.1.2"
ovn-nbctl lsp-set-port-security ls1-vm1 "02:ac:10:ff:01:31 1.1.1.2"

ovn-nbctl lsp-add ls1 ls1-vm2
ovn-nbctl lsp-set-addresses ls1-vm2 "02:ac:10:ff:01:32 1.1.1.3"
ovn-nbctl lsp-set-port-security ls1-vm2 "02:ac:10:ff:01:32 1.1.1.3"

ovn-nbctl lsp-add ls1 ls1-vm3
ovn-nbctl lsp-set-addresses ls1-vm3 "02:ac:10:ff:01:33 1.1.1.5"
ovn-nbctl lsp-set-port-security ls1-vm3 "02:ac:10:ff:01:33 1.1.1.5"

ovn-nbctl lsp-add ls2 ls2-vm5
ovn-nbctl lsp-set-addresses ls2-vm5 "02:ac:11:ff:01:02 1.1.2.2"
ovn-nbctl lsp-set-port-security ls2-vm5 "02:ac:11:ff:01:02 1.1.2.2"

ovn-nbctl set Logical_Switch ls1 other_config:mcast_querier="false" other_config:mcast_snoop="true"
ovn-nbctl set Logical_Switch ls2 other_config:mcast_querier="false" other_config:mcast_snoop="true"
ovn-nbctl set logical_router lr1 options:mcast_relay="true"

add_vm1
add_vm3