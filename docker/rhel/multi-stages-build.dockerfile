FROM centos:7 as ovs_builder
ARG OVN_BRANCH
ARG GITHUB_SRC

RUN yum -y install @'Development Tools' rpm-build yum-utils epel-release
WORKDIR /build
COPY rhel/build_ovs_rpm.sh ./
RUN chmod +x build_ovs_rpm.sh
RUN ./build_ovs_rpm.sh

FROM ovs_builder as ovn_builder
ARG OVN_BRANCH
ARG GITHUB_SRC
WORKDIR /build
COPY rhel/build_ovn_rpm.sh ./
RUN chmod +x build_ovn_rpm.sh
RUN ./build_ovn_rpm.sh $OVN_BRANCH $GITHUB_SRC

FROM centos:7
WORKDIR /root
COPY --from=ovs_builder /build/ovs/rpm/rpmbuild/RPMS/x86_64/*.rpm ./
COPY --from=ovs_builder /build/ovs/rpm/rpmbuild/RPMS/noarch/*.rpm ./
COPY --from=ovn_builder /build/ovn/rpm/rpmbuild/RPMS/x86_64/*.rpm ./
COPY rhel/install_rpm.sh ./
RUN ./install_rpm.sh
COPY script/start_con.sh /start_con.sh
COPY script/generate_dhclient_script_for_fullstack.sh /tmp/generate_dhclient_script_for_fullstack.sh
RUN yum -y install vim-minimal net-tools iputils uuid which dhclient conntrack-tools \
    nmap iperf socat && \
    yum -y autoremove && yum clean all && rm -rf /var/cache/yum
RUN chmod +x /start_con.sh /tmp/generate_dhclient_script_for_fullstack.sh && \
    /tmp/generate_dhclient_script_for_fullstack.sh /
VOLUME ["/var/log/openvswitch", \
"/var/lib/openvswitch", "/var/run/openvswitch", "/etc/openvswitch", \
"/var/log/ovn", "/var/lib/ovn", "/var/run/ovn", "/etc/ovn", \
"/run", "/tmp"]
ENTRYPOINT ["/start_con.sh"]
