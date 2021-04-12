#!/bin/sh

set -o xtrace
set -o errexit

OVN_BRANCH=$1
GITHUB_SRC=$2

# yum -y install @'Development Tools' rpm-build yum-utils epel-release
echo "build ovn packages"
git clone --depth 1 -b $OVN_BRANCH $GITHUB_SRC
cd ovn
sed -e 's/@VERSION@/0.0.1/' rhel/ovn-fedora.spec.in > /tmp/ovn.spec
yum-builddep -y /tmp/ovn.spec && rm -rf /tmp/ovn.spec
./boot.sh
./configure --with-ovs-source=../ovs && make dist && make rpm-fedora



