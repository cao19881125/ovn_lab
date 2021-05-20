#!/bin/bash -x

function add_vm2(){
  ip netns add vm2
  ovs-vsctl add-port br-int vm2 -- set interface vm2 type=internal
  ip link set vm2 address 02:ac:10:ff:01:32
  ip link set vm2 netns vm2
  ip netns exec vm2 ip addr add 1.1.1.3/24 dev vm2
  ip netns exec vm2 ip link set vm2 up
  ip netns exec vm2 sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=0
  ovs-vsctl set Interface vm2 external_ids:iface-id=ls1-vm2
  ip netns exec vm2 ip route add default via 1.1.1.1 dev vm2
}

function add_vm5() {
  ip netns add vm5
  ovs-vsctl add-port br-int vm5 -- set interface vm5 type=internal
  ip link set vm5 address 02:ac:11:ff:01:02
  ip link set  vm5 netns vm5
  ip netns exec vm5 ip addr add 1.1.2.2/24 dev vm5
  ip netns exec  vm5 ip link set vm5 up
  ovs-vsctl set Interface vm5 external_ids:iface-id=ls2-vm5
  ip netns exec vm5 ip route add default via 1.1.2.1 dev vm5
}


ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

stop_ovn_controller.sh
start_ovn_controller.sh

add_vm2
add_vm5
