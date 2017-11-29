## 目标

- host2 实时同步host1 上的ovsdb

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab
docker build -t ovn_lab:v1 .
```


## run container

```
cd ovn_lab/lesson/list/lesson6
./start_compose.sh
```

## 测试
### host1

```
docker exec -it host1 bash
start_ovs.sh
ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6640:0.0.0.0
```

#### 创建一些db数据

```
/root/ovn_lab/create_topo_host1.sh
```

#### 查看数据
```
# ovsdb-client dump Open_vSwitch Open_vSwitch
Open_vSwitch table
_uuid                                bridges                                cur_cfg datapath_types   db_version external_ids                                                                                        iface_types                                                   manager_options next_cfg other_config ovs_version ssl statistics system_type system_version
------------------------------------ -------------------------------------- ------- ---------------- ---------- --------------------------------------------------------------------------------------------------- ------------------------------------------------------------- --------------- -------- ------------ ----------- --- ---------- ----------- --------------
5b0c3fab-a817-42a8-8654-33786909d31f [19b30922-627c-4fc5-9628-fdf6b321bdcc] 3       [netdev, system] "7.15.0"   {hostname="host1", rundir="/var/run/openvswitch", system-id="57bb798d-0054-467c-8255-5160b24e48c5"} [geneve, gre, internal, lisp, patch, stt, system, tap, vxlan] []              3        {}           "2.7.90"    []  {}         centos      "7"
```
- system-id="57bb798d-0054-467c-8255-5160b24e48c5"

```
# ovsdb-client dump Open_vSwitch Bridge
Bridge table
_uuid                                auto_attach controller datapath_id        datapath_type datapath_version external_ids fail_mode flood_vlans flow_tables ipfix mcast_snooping_enable mirrors name   netflow other_config ports                                                                                                              protocols rstp_enable rstp_status sflow status stp_enable
------------------------------------ ----------- ---------- ------------------ ------------- ---------------- ------------ --------- ----------- ----------- ----- --------------------- ------- ------ ------- ------------ ------------------------------------------------------------------------------------------------------------------ --------- ----------- ----------- ----- ------ ----------
19b30922-627c-4fc5-9628-fdf6b321bdcc []          []         "00002209b319c54f" ""            "2.7.90"         {}           []        []          {}          []    false                 []      br-int []      {}           [3ad50144-017b-4e5e-aacc-20ee27e8ee25, 6eaae248-9784-4d73-97e4-9e1b97998cfa, bc59e604-4ece-4c47-80eb-a680eb1871eb] []        false       {}          []    {}     false
```

```
# ovsdb-client dump Open_vSwitch Port
Port table
_uuid                                bond_active_slave bond_downdelay bond_fake_iface bond_mode bond_updelay cvlans external_ids fake_bridge interfaces                             lacp mac name   other_config protected qos rstp_statistics rstp_status statistics status tag trunks vlan_mode
------------------------------------ ----------------- -------------- --------------- --------- ------------ ------ ------------ ----------- -------------------------------------- ---- --- ------ ------------ --------- --- --------------- ----------- ---------- ------ --- ------ ---------
3ad50144-017b-4e5e-aacc-20ee27e8ee25 []                0              false           []        0            []     {}           false       [db38d432-a0ed-4a1e-8d0e-db3ddf86efb1] []   []  br-int {}           false     []  {}              {}          {}         {}     []  []     []
6eaae248-9784-4d73-97e4-9e1b97998cfa []                0              false           []        0            []     {}           false       [06391dd5-e301-4f30-b0a3-e92979dbbd14] []   []  "vm1"  {}           false     []  {}              {}          {}         {}     []  []     []
bc59e604-4ece-4c47-80eb-a680eb1871eb []                0              false           []        0            []     {}           false       [604a23ce-940a-4530-b4f8-5fe931b76a17] []   []  "vm2"  {}           false     []  {}              {}          {}         {}     []  []     []
```

```
# ovsdb-client dump Open_vSwitch Interface
Interface table
_uuid                                admin_state bfd bfd_status cfm_fault cfm_fault_status cfm_flap_count cfm_health cfm_mpid cfm_remote_mpids cfm_remote_opstate duplex error external_ids ifindex ingress_policing_burst ingress_policing_rate lacp_current link_resets link_speed link_state lldp mac mac_in_use          mtu  mtu_request name   ofport ofport_request options other_config statistics                                                                                                                                                                  status                    type
------------------------------------ ----------- --- ---------- --------- ---------------- -------------- ---------- -------- ---------------- ------------------ ------ ----- ------------ ------- ---------------------- --------------------- ------------ ----------- ---------- ---------- ---- --- ------------------- ---- ----------- ------ ------ -------------- ------- ------------ --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------- --------
06391dd5-e301-4f30-b0a3-e92979dbbd14 down        {}  {}         []        []               []             []         []       []               []                 []     []    {}           0       0                      0                     []           0           []         down       {}   []  []                  []   []          "vm1"  1      []             {}      {}           {collisions=0, rx_bytes=760, rx_crc_err=0, rx_dropped=0, rx_errors=0, rx_frame_err=0, rx_over_err=0, rx_packets=12, tx_bytes=928, tx_dropped=0, tx_errors=0, tx_packets=12} {driver_name=openvswitch} internal
604a23ce-940a-4530-b4f8-5fe931b76a17 down        {}  {}         []        []               []             []         []       []               []                 []     []    {}           0       0                      0                     []           0           []         down       {}   []  []                  []   []          "vm2"  2      []             {}      {}           {collisions=0, rx_bytes=684, rx_crc_err=0, rx_dropped=0, rx_errors=0, rx_frame_err=0, rx_over_err=0, rx_packets=11, tx_bytes=928, tx_dropped=0, tx_errors=0, tx_packets=12} {driver_name=openvswitch} internal
db38d432-a0ed-4a1e-8d0e-db3ddf86efb1 down        {}  {}         []        []               []             []         []       []               []                 []     []    {}           4       0                      0                     []           0           []         down       {}   []  "22:09:b3:19:c5:4f" 1500 []          br-int 65534  []             {}      {}           {collisions=0, rx_bytes=0, rx_crc_err=0, rx_dropped=17, rx_errors=0, rx_frame_err=0, rx_over_err=0, rx_packets=0, tx_bytes=0, tx_dropped=0, tx_errors=0, tx_packets=0}      {driver_name=openvswitch} internal
```

### host2

```
docker exec -it host2 bash
start_ovs.sh
```

#### 查看Open_vSwitch表

```
# ovsdb-client dump Open_vSwitch Open_vSwitch
Open_vSwitch table
_uuid                                bridges cur_cfg datapath_types   db_version external_ids                                                                                        iface_types                                                   manager_options next_cfg other_config ovs_version ssl statistics system_type system_version
------------------------------------ ------- ------- ---------------- ---------- --------------------------------------------------------------------------------------------------- ------------------------------------------------------------- --------------- -------- ------------ ----------- --- ---------- ----------- --------------
3e8c9e76-28e4-43e6-867f-056d6cef787d []      0       [netdev, system] "7.15.0"   {hostname="host2", rundir="/var/run/openvswitch", system-id="cd7e9934-e5d7-4f03-9c4c-1fa3f2ff94df"} [geneve, gre, internal, lisp, patch, stt, system, tap, vxlan] []              0        {}           "2.7.90"    []  {}         centos      "7"
```
- system-id="cd7e9934-e5d7-4f03-9c4c-1fa3f2ff94df"

#### 设置作为backup db同步host1

```
ovs-appctl -t ovsdb-server ovsdb-server/set-active-ovsdb-server tcp:10.10.0.10:6640
ovs-appctl -t ovsdb-server ovsdb-server/connect-active-ovsdb-server
```

```
# ovs-appctl -t ovsdb-server ovsdb-server/sync-status
state: backup
replicating: tcp:10.10.0.10:6640
database: Open_vSwitch
```

#### 查看db

```
# ovsdb-client dump Open_vSwitch Open_vSwitch
Open_vSwitch table
_uuid                                bridges                                cur_cfg datapath_types   db_version external_ids                                                                                        iface_types                                                   manager_options next_cfg other_config ovs_version ssl statistics system_type system_version
------------------------------------ -------------------------------------- ------- ---------------- ---------- --------------------------------------------------------------------------------------------------- ------------------------------------------------------------- --------------- -------- ------------ ----------- --- ---------- ----------- --------------
5b0c3fab-a817-42a8-8654-33786909d31f [19b30922-627c-4fc5-9628-fdf6b321bdcc] 3       [netdev, system] "7.15.0"   {hostname="host1", rundir="/var/run/openvswitch", system-id="57bb798d-0054-467c-8255-5160b24e48c5"} [geneve, gre, internal, lisp, patch, stt, system, tap, vxlan] []              3        {}           "2.7.90"    []  {}         centos      "7"
```
- system-id变为了host1的id


```
ovsdb-client dump Open_vSwitch Bridge
ovsdb-client dump Open_vSwitch Port
ovsdb-client dump Open_vSwitch Interface
```
- 这些表都同host1一样


### 修改测试
#### host1
```
ovs-vsctl add-port br-int vm3 -- set interface vm3 type=internal
```

```
# ovs-vsctl show
5b0c3fab-a817-42a8-8654-33786909d31f
    Bridge br-int
        Port br-int
            Interface br-int
                type: internal
        Port "vm1"
            Interface "vm1"
                type: internal
        Port "vm3"
            Interface "vm3"
                type: internal
        Port "vm2"
            Interface "vm2"
                type: internal
    ovs_version: "2.7.90"
```
#### host2

```
# ovs-vsctl show
5b0c3fab-a817-42a8-8654-33786909d31f
    Bridge br-int
        Port br-int
            Interface br-int
                type: internal
        Port "vm1"
            Interface "vm1"
                type: internal
        Port "vm3"
            Interface "vm3"
                type: internal
        Port "vm2"
            Interface "vm2"
                type: internal
    ovs_version: "2.7.90"
```

### 停掉host1
#### host1
```
stop_ovs.sh
```
#### host2

```
ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
370: eth0@if371: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:0a:0a:00:14 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.10.0.20/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:aff:fe0a:14/64 scope link
       valid_lft forever preferred_lft forever
```
- 可以看到，处于backup状态的ovsdb，虽然实时同步了host1的db，但是并没有在本地生效

#### 关闭同步连接
```
ovs-appctl -t ovsdb-server ovsdb-server/disconnect-active-ovsdb-server
```

```
# ovs-appctl -t ovsdb-server ovsdb-server/sync-status
state: active
```
- 关闭后，backup状态的ovsdb变为了active状态


```
# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
3: ovs-system: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether e2:a5:61:20:8d:39 brd ff:ff:ff:ff:ff:ff
4: vm2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether 6a:9c:b7:09:c4:22 brd ff:ff:ff:ff:ff:ff
5: br-int: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether 22:09:b3:19:c5:4f brd ff:ff:ff:ff:ff:ff
6: vm1: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether 4a:15:62:52:f4:73 brd ff:ff:ff:ff:ff:ff
7: vm3: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN qlen 1000
    link/ether 86:ad:f0:20:16:3e brd ff:ff:ff:ff:ff:ff
370: eth0@if371: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP
    link/ether 02:42:0a:0a:00:14 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.10.0.20/24 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:aff:fe0a:14/64 scope link
       valid_lft forever preferred_lft forever
```
- 看到，db中的记录生效



