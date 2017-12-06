#!/bin/bash -x

ovs-vsctl add-br br0 -- set Bridge br0 fail-mode=secure
ovs-vsctl add-port br0 vtep-gateway -- set interface vtep-gateway type=internal
ip link set vtep-gateway address 02:ac:10:ff:01:03
ip netns add gateway
ip link set vtep-gateway netns gateway
ip netns exec gateway ip link set vtep-gateway up
ip netns exec gateway ip address add 10.0.0.3/24 dev vtep-gateway
ovsdb-tool create /etc/openvswitch/vtep.db /usr/share/openvswitch/vtep.ovsschema
ovs-appctl -t ovsdb-server ovsdb-server/add-db /etc/openvswitch/vtep.db
ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6640:0.0.0.0
vtep-ctl add-ps br0
vtep-ctl set Physical_Switch br0 tunnel_ips=10.10.0.20
/usr/share/openvswitch/scripts/ovs-vtep --log-file=/var/log/openvswitch/ovs-vtep.log --pidfile=/var/run/openvswitch/ovs-vtep.pid --detach br0
ovs-vsctl set open . external-ids:ovn-remote=tcp:10.10.0.10:6642
ovs-vsctl set open . external-ids:ovn-encap-type=vxlan
ovs-vsctl set open . external-ids:ovn-encap-ip=10.10.0.20
ovn-controller-vtep -vconsole:emer -vfile:info --log-file=/var/log/openvswitch/ovn-controller-vtep.log --vtep-db=unix:/var/run/openvswitch/db.sock --ovnsb-db=tcp:10.10.0.10:6642 --detach --monitor 
vtep-ctl add-ls ls0
vtep-ctl bind-ls br0 vtep-gateway 0 ls0
