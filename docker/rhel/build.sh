#!/bin/sh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

OVN_BRANCH=$1
GITHUB_SRC=$2

# Install deps
build_deps="rpm-build yum-utils automake autoconf openssl-devel \
epel-release libtool git openssl python3"

#yum update -y
yum -y install ${build_deps}

./install_ovn.sh $OVN_BRANCH $GITHUB_SRC

# remove unused packages to make the container light weight.
# for i in $(package-cleanup --leaves --all);
# do
#     yum remove -y $i; yum autoremove -y;
# done
yum -y remove ${build_deps}
# yum -y install yum-plugin-ovl
yum -y autoremove
rm -rf /build

