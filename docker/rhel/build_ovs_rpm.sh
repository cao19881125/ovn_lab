
#!/bin/sh

set -o xtrace
set -o errexit

# yum -y install @'Development Tools' rpm-build yum-utils epel-release
git clone --depth 1 -b master https://github.com/openvswitch/ovs.git
echo "building ovs userspace packages"
cd ovs
sed -e 's/@VERSION@/0.0.1/' rhel/openvswitch-fedora.spec.in > /tmp/ovs.spec
yum-builddep -y /tmp/ovs.spec && rm -rf /tmp/ovs.spec
./boot.sh && ./configure && make rpm-fedora
