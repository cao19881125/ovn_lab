FROM centos:7

ARG OVN_BRANCH
ARG GITHUB_SRC

copy rhel/build.sh /build.sh
copy script/install_ovn.sh /install_ovn.sh
RUN /build.sh $OVN_BRANCH $GITHUB_SRC
COPY script/start_con.sh /start_con.sh
COPY script/generate_dhclient_script_for_fullstack.sh /tmp/generate_dhclient_script_for_fullstack.sh
RUN chmod +x start_con.sh /tmp/generate_dhclient_script_for_fullstack.sh
RUN /tmp/generate_dhclient_script_for_fullstack.sh ""

VOLUME ["/var/log/openvswitch", \
"/var/lib/openvswitch", "/var/run/openvswitch", "/etc/openvswitch", \
"/var/log/ovn", "/var/lib/ovn", "/var/run/ovn", "/etc/ovn", \
"/run", "/tmp"]
ENTRYPOINT ["./start_con.sh"]
