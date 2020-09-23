## 目标

```
underlay
     ----------------------externel------------------------- internet
              |                                 |
              | eth1                            | eth1
         -----------                       -----------
         |   gw1   |                       |   gw2   |
         -----------                       -----------
              | eth0                            | eth0
              |                                 |
     ------------------------internal------------------------
              |                 |               |
              | eth0            | eth0          | eth0
         -----------       ------------    -----------
         |computer1|       |controller|    |computer1|
         -----------       ------------    -----------

overlay topo
                 internet
                    |
         --------------------------  
         |                        |
         |    external-switch     |
         |                        |
         --------------------------
             |               |
             |10.20.0.100    |10.20.0.101   
         ---------       ---------
         |   R1  |       |   R2  |
         ---------       ---------
192.168.1.1|  |192.168.2.1   |192.168.4.1
      ------    ------        ---------
     |                |                |
-----------      -----------      ----------
| internal|      | internal|      | internal|
| switch1 |      | switch2 |      | switch3 |
-----------      -----------      -----------
  |    |           |     |              |
 vm1  vm3         vm2   vm4            vm5

```

- 通过"Router Specific Active-Backup"算法实现在有多个网关和多个logical router的情况下，ovn内部网络通过网关出外网时，均衡网关上的负载。
- 10.20.0.100和10.20.0.101是通往外部交换机的ip，可以通过此ip连接internet
- underlay网络有两个网关节点，分别为gw1和gw2
- 目标为R1下的主机vm1、vm2、vm3和vm4可以通过gw1访问外网，而R2下的主机vm5可以通过gw2访问外网，当gw1和gw2中的一个挂掉时，另一个作为网关起作用

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab/package
build_v2.sh
```


## run container

```
cd ovn_lab/lesson/list/lesson11
./start_compose.sh
```

## 构建controller

```
docker exec -it ovn-controller /root/create_topo_controller.sh
```

## 构建gw1

```
docker exec -it ovn-gw1 /root/create_topo_gw1.sh
```

## 构建gw2

```
docker exec -it ovn-gw2 /root/create_topo_gw2.sh
```


## 构建computer1

```
docker exec -it ovn-computer1 /root/create_topo_computer1.sh
```

## 构建computer2

```
docker exec -it ovn-computer2 /root/create_topo_computer2.sh
```


## 测试
### gw1
- tcpdump对eth1网卡抓包
```
yum install -y tcpdump
tcpdump -i eth1 -en
```

### gw2
- tcpdump对eth1网卡抓包
```
yum install -y tcpdump
tcpdump -i eth1 -en
```

### computer2
- vm3 ping 8.8.8.8
```
# ip netns exec vm1 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=2 ttl=126 time=48.6 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=126 time=48.0 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 2 received, 33% packet loss, time 2009ms
rtt min/avg/max/mdev = 48.020/48.327/48.635/0.378 ms
```

查看流经gw1和gw2 eth1网卡数据包，vm3 ping 8.8.8.8经过gw1，而没有经过gw2

- vm5 ping 8.8.8.8
```
# ip netns exec vm2 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=2 ttl=126 time=48.4 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=126 time=47.8 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 2 received, 33% packet loss, time 2000ms
rtt min/avg/max/mdev = 47.823/48.113/48.404/0.364 ms
```

查看流经gw1和gw2 eth1网卡的数据包，vm5 ping 8.8.8.8经过gw2, 而没有经过gw1

### 模拟gw1 down
- 在computer1中 vm1 ping 8.8.8.8

```
ip netns exec vm1 ping 8.8.8.8
```

- 在computer2中 vm5 ping 8.8.8.8

```
ip netns exec vm5 ping 8.8.8.8
```

- 查看流经gw1和gw2 eth1网卡的数据包

- 模拟gw1 down，在gw1中执行

```
/usr/share/openvswitch/scripts/ovs-ctl stop
```

- 查看流经gw1和gw2 eth1网卡的数据包

- 模拟gw1上线，在gw1中执行

```
/usr/share/openvswith/scripts/ovs-ctl start
ovs-vsctl set open . external-ids:system-id=gw1
```

