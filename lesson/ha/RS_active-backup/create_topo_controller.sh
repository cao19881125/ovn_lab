#!/bin/bash -x

/usr/share/ovn/scripts/ovn-ctl start_northd

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0


ovn-nbctl ls-add internal1-switch
ovn-nbctl ls-add internal2-switch
ovn-nbctl ls-add internal3-switch
ovn-nbctl ls-add external-switch

ovn-nbctl lsp-add external-switch external-localnet
ovn-nbctl lsp-set-addresses external-localnet unknown
ovn-nbctl lsp-set-type external-localnet localnet
ovn-nbctl lsp-set-options external-localnet network_name=ext


ovn-nbctl lr-add R1
ovn-nbctl lrp-add R1 internal1-port 00:00:01:01:02:03 192.168.1.1/24
ovn-nbctl lrp-add R1 internal2-port 00:00:01:01:02:04 192.168.2.1/24

ovn-nbctl lrp-add R1 external-port 00:00:01:01:02:05 10.20.0.100/24

ovn-nbctl lr-add R2
ovn-nbctl lrp-add R2 internal3-port 00:00:01:01:03:02 192.168.4.1/24

ovn-nbctl lrp-add R2 external-port2 00:00:01:01:03:03 10.20.0.101/24

ovn-nbctl $OVN_NBDB lsp-add internal1-switch r1-internal1-port \
          -- lsp-set-options r1-internal1-port router-port=internal1-port \
          -- lsp-set-type r1-internal1-port router \
          -- lsp-set-addresses r1-internal1-port router

ovn-nbctl $OVN_NBDB lsp-add internal2-switch r1-internal2-port \
          -- lsp-set-options r1-internal2-port router-port=internal2-port \
          -- lsp-set-type r1-internal2-port router \
          -- lsp-set-addresses r1-internal2-port router

ovn-nbctl $OVN_NBDB lsp-add external-switch r1-external-port \
          -- lsp-set-options r1-external-port router-port=external-port \
          -- lsp-set-type r1-external-port router \
          -- lsp-set-addresses r1-external-port router


ovn-nbctl $OVN_NBDB lsp-add internal3-switch r2-internal3-port \
          -- lsp-set-options r2-internal3-port router-port=internal3-port \
          -- lsp-set-type r2-internal3-port router \
          -- lsp-set-addresses r2-internal3-port router

ovn-nbctl $OVN_NBDB lsp-add external-switch r2-external-port \
          -- lsp-set-options r2-external-port router-port=external-port2 \
          -- lsp-set-type r2-external-port router \
          -- lsp-set-addresses r2-external-port router

ovn-nbctl ha-chassis-group-add hagrp1
ovn-nbctl ha-chassis-group-add-chassis hagrp1 gw1 30
ovn-nbctl ha-chassis-group-add-chassis hagrp1 gw2 20

ovn-nbctl set Logical_Router_Port external-port ha-chassis-group=`ovn-nbctl --bare --columns _uuid find ha_chassis_group name=hagrp1`

ovn-nbctl ha-chassis-group-add hagrp2
ovn-nbctl ha-chassis-group-add-chassis hagrp2 gw1 20
ovn-nbctl ha-chassis-group-add-chassis hagrp2 gw2 30

ovn-nbctl set Logical_Router_Port external-port2 ha-chassis-group=`ovn-nbctl --bare --columns _uuid find ha_chassis_group name=hagrp2`

ovn-nbctl $OVN_NBDB lr-nat-add R1 snat 10.20.0.100 192.168.0.0/22
ovn-nbctl lr-route-add R1 "0.0.0.0/0" 10.20.0.1

ovn-nbctl $OVN_NBDB lr-nat-add R2 snat 10.20.0.101 192.168.4.0/22
ovn-nbctl lr-route-add R2 "0.0.0.0/0" 10.20.0.1


ovn-nbctl lsp-add internal1-switch vm1
ovn-nbctl lsp-set-addresses vm1 "00:00:01:01:02:0a 192.168.1.3"

ovn-nbctl lsp-add internal2-switch vm2
ovn-nbctl lsp-set-addresses vm2 "00:00:01:01:02:0b 192.168.2.3"

ovn-nbctl lsp-add internal1-switch vm3
ovn-nbctl lsp-set-addresses vm3 "00:00:01:01:02:08 192.168.1.4"

ovn-nbctl lsp-add internal2-switch vm4
ovn-nbctl lsp-set-addresses vm4 "00:00:01:01:02:09 192.168.2.4"

ovn-nbctl lsp-add internal3-switch vm5
ovn-nbctl lsp-set-addresses vm5 "00:00:01:01:03:04 192.168.4.2"
