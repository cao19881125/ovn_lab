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
                    |               
                    |10.20.0.100       
                ---------      
                |   R1  |      
                ---------       
        192.168.1.1|  |192.168.2.1   
             ------    ------       
            |                |       
        -----------      -----------    
        | internal|      | internal|    
        | switch1 |      | switch2 |    
        -----------      -----------    
          |    |           |     |      
         vm1  vm3         vm2   vm4     
```

- active-back高可用。通过多个gateway实现ha，其中一个gateway为active，其余gateway为backup。
- 10.20.0.100是通往外部交换机的ip，可以通过此ip连接internet
- underlay网络有两个网关节点，分别为gw1和gw2
- 目标为R1下的主机vm1、vm2、vm3和vm4可以通过gw1访问外网，当gw1一个挂掉时，网关切换到gw2

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab/docker
./build_v2.sh
```


## run container

```
cd ../lesson/list/lesson11
./start_compose.sh
```

## 构建controller

```
docker exec -it ovn-ctrl /root/create_topo_ctrl.sh
```

## 构建gw1

```
docker exec -it ovn-gw1 /root/create_topo_gw1.sh
```

## 构建gw2

```
docker exec -it ovn-gw2 /root/create_topo_gw2.sh
```


## 构建hv1

```
docker exec -it ovn-hv1 /root/create_topo_hv1.sh
```

## 构建hv2

```
docker exec -it ovn-hv2 /root/create_topo_hv2.sh
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

### hv1
- vm1 ping 8.8.8.8
```
bash-4.4# ip netns exec vm1 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=111 time=47.8 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=111 time=52.9 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=111 time=67.8 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 5ms
rtt min/avg/max/mdev = 47.839/56.181/67.835/8.496 ms
```

gw1和gw2上eth1网卡抓包情况
* gw1
```
bash-4.4# tcpdump -i eth1 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
07:24:43.937479 00:00:01:01:02:05 > 02:42:1e:ba:10:34, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 282, seq 1, length 64
07:24:43.985135 02:42:1e:ba:10:34 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 282, seq 1, length 64
07:24:44.938527 00:00:01:01:02:05 > 02:42:1e:ba:10:34, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 282, seq 2, length 64
07:24:44.991220 02:42:1e:ba:10:34 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 282, seq 2, length 64
07:24:45.940549 00:00:01:01:02:05 > 02:42:1e:ba:10:34, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 282, seq 3, length 64
07:24:46.008173 02:42:1e:ba:10:34 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 282, seq 3, length 64
```
* gw2
```
[root@localhost ~]# docker exec -it ovn-gw2 bash
bash-4.4# tcpdump -i eth1 -en
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
```

### 模拟gw1 down
- 在computer1中 vm1 ping 8.8.8.8

```
ip netns exec vm1 ping 8.8.8.8
```

- 查看流经gw1和gw2 eth1网卡的数据包

从抓包结果可以看出，vm1 ping 8.8.8.8的数据包走gw1

- 模拟gw1 down，在gw1中执行

```
/usr/share/openvswitch/scripts/ovs-ctl stop
```

- 查看流经gw1和gw2 eth1网卡的数据包

gw2 上抓包
```
length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 618, seq 528, length 64
08:29:08.582071 02:42:1e:ba:10:34 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 618, seq 528, length 64
```

gw1下线后，vm1和vm2 ping 8.8.8.8的数据包都经过gw2

- 模拟gw1上线，在gw1中执行

```
/usr/share/openvswith/scripts/ovs-ctl start
ovs-vsctl set open . external-ids:system-id=gw1
```

此时vm1 ping 8.8.8.8的数据包又经过gw1与外网通信

