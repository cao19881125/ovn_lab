#!/bin/sh

/usr/share/ovn/scripts/ovn-ctl start_northd

ovn-nbctl set-connection ptcp:6641:0.0.0.0
ovn-sbctl set-connection ptcp:6642:0.0.0.0