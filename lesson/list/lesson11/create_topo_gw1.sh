#!/bin/bash -x

ovs-vsctl add-br br-int -- set Bridge br-int fail-mode=secure
ovs-vsctl set open . external-ids:ovn-remote=tcp:$OVN_SERVER:6642
ovs-vsctl set open . external-ids:system-id=gw1
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=$MY_IP

/usr/share/ovn/scripts/ovn-ctl stop_controller
/usr/share/ovn/scripts/ovn-ctl start_controller

ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth1
ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=physnet1:br-ex