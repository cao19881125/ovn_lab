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
cd ovn_lab/docker
./build_v2.sh
```


## run container

```
cd ../lesson/list/lesson12
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
tcpdump -i eth1 -en
```

### gw2
- tcpdump对eth1网卡抓包
```
tcpdump -i eth1 -en
```

### computer2
- vm3 ping 8.8.8.8
```
bash-4.4# ip netns exec vm3 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=111 time=69.6 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=111 time=68.1 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=111 time=66.9 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 66.931/68.194/69.555/1.094 ms
```

gw1和gw2上eth1网卡抓包情况
* gw1
```
bash-4.4# tcpdump -i eth1 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
05:42:57.601792 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 229, seq 1, length 64
05:42:57.669686 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 229, seq 1, length 64
05:42:58.602767 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 229, seq 2, length 64
05:42:58.670617 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 229, seq 2, length 64
05:42:59.603904 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 229, seq 3, length 64
05:42:59.670650 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 229, seq 3, length 64
05:43:02.912365 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype ARP (0x0806), length 42: Request who-has 10.20.0.100 tell 10.20.0.1, length 28
05:43:02.912758 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype ARP (0x0806), length 42: Reply 10.20.0.100 is-at 00:00:01:01:02:05, length 28
```
* gw2
```
bash-4.4# tcpdump -i eth1 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
```

- vm5 ping 8.8.8.8
```
bash-4.4# ip netns exec vm5 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=111 time=66.4 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=111 time=61.6 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=111 time=66.10 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 61.597/64.978/66.968/2.403 ms
```

gw1和gw2上eth1网卡抓包情况
* gw1 
```
bash-4.4# tcpdump -i eth1 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
```

* gw2
```
bash-4.4# tcpdump -i eth1 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
05:44:15.442479 00:00:01:01:03:03 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.101 > 8.8.8.8: ICMP echo request, id 239, seq 1, length 64
05:44:15.508117 02:42:ab:94:0e:fd > 00:00:01:01:03:03, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.101: ICMP echo reply, id 239, seq 1, length 64
05:44:16.444047 00:00:01:01:03:03 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.101 > 8.8.8.8: ICMP echo request, id 239, seq 2, length 64
05:44:16.505444 02:42:ab:94:0e:fd > 00:00:01:01:03:03, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.101: ICMP echo reply, id 239, seq 2, length 64
05:44:17.445767 00:00:01:01:03:03 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.101 > 8.8.8.8: ICMP echo request, id 239, seq 3, length 64
05:44:17.512551 02:42:ab:94:0e:fd > 00:00:01:01:03:03, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.101: ICMP echo reply, id 239, seq 3, length 64
```

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

从抓包结果可以看出，vm1 ping 8.8.8.8的数据包走gw1，而vm5 ping 8.8.8.8的数据包走gw2

- 模拟gw1 down，在gw1中执行

```
/usr/share/openvswitch/scripts/ovs-ctl stop
```

- 查看流经gw1和gw2 eth1网卡的数据包

gw2 上抓包
```
05:49:01.426523 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 224, seq 159, length 64
05:49:01.487683 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 224, seq 159, length 64
05:49:01.824345 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype ARP (0x0806), length 42: Request who-has 10.20.0.100 tell 10.20.0.1, length 28
05:49:01.825100 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype ARP (0x0806), length 42: Reply 10.20.0.100 is-at 00:00:01:01:02:05, length 28
05:49:01.838191 00:00:01:01:03:03 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.101 > 8.8.8.8: ICMP echo request, id 255, seq 142, length 64
05:49:01.901665 02:42:ab:94:0e:fd > 00:00:01:01:03:03, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.101: ICMP echo reply, id 255, seq 142, length 64
05:49:02.428075 00:00:01:01:02:05 > 02:42:ab:94:0e:fd, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 224, seq 160, length 64
05:49:02.493525 02:42:ab:94:0e:fd > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 224, seq 160, length 64
```

gw1下线后，vm1和vm2 ping 8.8.8.8的数据包都经过gw2

- 模拟gw1上线，在gw1中执行

```
/usr/share/openvswith/scripts/ovs-ctl start
ovs-vsctl set open . external-ids:system-id=gw1
```

此时vm1 ping 8.8.8.8的数据包经过gw1，而vm5 ping 8.8.8.8的数据包经过gw2

