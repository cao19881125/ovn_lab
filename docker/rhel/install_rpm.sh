#!/bin/sh
set -o xtrace
set -o errexit

yum -y install epel-release
yum -y localinstall openvswitch-[0-9]*.el7.x86_64.rpm openvswitch-ipsec-*.el7.x86_64.rpm python3-openvswitch-*.el7.noarch.rpm
yum -y localinstall yum -y localinstall ovn-[0-9]*.el7.x86_64.rpm ovn-central-*.el7.x86_64.rpm ovn-host-*.x86_64.rpm \
    ovn-vtep-*.el7.x86_64.rpm ovn-docker-*.el7.x86_64.rpm

mkdir -p /opt/ovn
OVS_PKI="ovs-pki --dir=/opt/ovn/pki"
$OVS_PKI init
pushd /opt/ovn
$OVS_PKI req+sign ovn switch
popd
