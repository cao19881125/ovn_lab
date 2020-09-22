#!/bin/bash -x

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0


LOCAL_CHASSIS=`cat /etc/openvswitch/system-id.conf`
ovn-nbctl create Logical_Router name=router options:chassis=gw1
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

dhcp_sw1=`ovn-nbctl create DHCP_Options cidr=10.0.0.0/24 options="\"server_id\"=\"10.0.0.1\" \"server_mac\"=\"52:54:00:c1:68:50\" \"lease_time\"=\"3600\" \"router\"=\"10.0.0.1\""`
dhcp_sw2=`ovn-nbctl create DHCP_Options cidr=10.1.0.0/24 options="\"server_id\"=\"10.1.0.1\" \"server_mac\"=\"52:54:00:c1:68:60\" \"lease_time\"=\"3600\" \"router\"=\"10.1.0.1\""`

ovn-nbctl lsp-set-dhcpv4-options ls1-vm1 $dhcp_sw1
ovn-nbctl lsp-set-dhcpv4-options ls2-vm2 $dhcp_sw2

ovn-nbctl ls-add outside
ovn-nbctl lrp-add router router1-outside 02:ac:10:ff:00:02 10.20.0.100/24
ovn-nbctl lsp-add outside outside-router1
ovn-nbctl lsp-set-type outside-router1 router
ovn-nbctl lsp-set-addresses outside-router1 02:ac:10:ff:00:02
ovn-nbctl lsp-set-options outside-router1 router-port=router1-outside
ovn-nbctl lsp-add outside outside-localnet
ovn-nbctl lsp-set-addresses outside-localnet unknown
ovn-nbctl lsp-set-type outside-localnet localnet
ovn-nbctl lsp-set-options outside-localnet network_name=physnet1

ovn-nbctl lr-nat-add router snat 10.20.0.100 10.0.0.0/24
ovn-nbctl lr-nat-add router snat 10.20.0.100 10.1.0.0/24
ovn-nbctl lr-route-add router "0.0.0.0/0" 10.20.0.1
