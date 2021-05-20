## 目的
通过将路由器与switch相连的端口的reside-on-redirect-chassis设置为true，将ovn中的南北向流量修改为通过localnet发往gateway chassis，而不是通过tunnel

## 拓扑

```
underlay
                                     
                                 ----------- 
                                | ovn-outer |
                                 ----------- 
                                      |eth0     
                                      |     
----------------------------------external--------------------------------
      |eth1                           |eth1           |eth1          |eth1
      |                               |               |              | 
 -----------     ------------    -----------     ----------     -----------
 | ovn-hv1  |   | ovn-ctrl  |   | ovn-hv2   |   | ovn-gw1  |   |  ovn-gw2  | 
 -----------     ------------    -----------     ----------     -----------
      |               |               |               |              |
      |eth0           |eth0           |eth0           |eth0          |eth0 
-------------------------------------------------------------------------- 
                                 10.10.0.0/24

overlay 
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
         |   |   |        |   |   |      
        vm1  |  vm3      vm2  |  vm4     
             |                |
             |localnet        |localnet
             |vlan10          |vlan20
        ------------------------------
          |vlan10 |vlan10 |vlan20 |vlan20
          |       |       |       |
         bm1     bm2     bm3     bm4
```
其中:
* vm1(192.168.1.3)和vm2(192.168.2.3)位于ovn-hv1上
* vm3(192.168.1.4)和vm4(192.168.2.4)位于ovn-hv2上
* bm1(192.168.1.5)和bm3(192.168.2.5)位于ovn-outer上

## 构建试验环境

```
cd ovn_lab/lesson/localnet-redirect_type/
./start_compose.sh
```

## 测试南北向流量

vm2 ping 8.8.8.8

在ovn-hv1 eth1网卡上抓包
```
root@ovn-hv1:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:17:24.148329 00:00:01:01:02:0b > 00:00:01:01:02:04, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.2.3 > 8.8.8.8: ICMP echo request, id 258, seq 1, length 64
02:17:24.195493 00:00:01:01:02:04 > 00:00:01:01:02:0b, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 8.8.8.8 > 192.168.2.3: ICMP echo reply, id 258, seq 1, length 64
```

在ovn-gw1 eth1上抓包
```
root@ovn-gw1:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:16:56.035988 00:00:01:01:02:0b > 00:00:01:01:02:04, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.2.3 > 8.8.8.8: ICMP echo request, id 253, seq 1, length 64
02:16:56.036022 00:00:01:01:02:05 > 02:42:9e:ec:27:41, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 253, seq 1, length 64
02:16:56.120297 02:42:9e:ec:27:41 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 253, seq 1, length 64
02:16:56.120331 00:00:01:01:02:04 > 00:00:01:01:02:0b, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 8.8.8.8 > 192.168.2.3: ICMP echo reply, id 253, seq 1, length 64
```
发往网关的包通过localnet发往gateway chassis，路由在gateway chassis上进行处理

## 测试东西向流量

### 同logical switch
vm1 ping vm3

在ovn-hv2 eth1上抓包
```
root@ovn-hv2:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:06:19.500083 00:00:01:01:02:0a > 00:00:01:01:02:08, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.1.3 > 192.168.1.4: ICMP echo request, id 179, seq 1, length 64
02:06:19.500781 00:00:01:01:02:08 > 00:00:01:01:02:0a, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.1.4 > 192.168.1.3: ICMP echo reply, id 179, seq 1, length 64
```

同逻辑交换机上位于不同chassis的虚拟机间通信直接通过localnet进行

### 不同logical switch
vm2 ping vm3 

在ovn-hv1 eth1上抓包
```
root@ovn-hv1:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:13:41.656710 00:00:01:01:02:0b > 00:00:01:01:02:04, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.2.3 > 192.168.1.4: ICMP echo request, id 231, seq 1, length 64
02:13:41.658965 00:00:01:01:02:04 > 00:00:01:01:02:0b, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.1.4 > 192.168.2.3: ICMP echo reply, id 231, seq 1, length 64
```

在ovn-gw1 eth1上抓包
```
root@ovn-gw1:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:13:41.656749 00:00:01:01:02:0b > 00:00:01:01:02:04, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.2.3 > 192.168.1.4: ICMP echo request, id 231, seq 1, length 64
02:13:41.657345 00:00:01:01:02:03 > 00:00:01:01:02:08, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.2.3 > 192.168.1.4: ICMP echo request, id 231, seq 1, length 64
02:13:41.658475 00:00:01:01:02:08 > 00:00:01:01:02:03, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.1.4 > 192.168.2.3: ICMP echo reply, id 231, seq 1, length 64
02:13:41.658936 00:00:01:01:02:04 > 00:00:01:01:02:0b, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.1.4 > 192.168.2.3: ICMP echo reply, id 231, seq 1, length 64
```

在ovn-hv2 eth1上抓包
```
root@ovn-hv2:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:13:41.657388 00:00:01:01:02:03 > 00:00:01:01:02:08, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.2.3 > 192.168.1.4: ICMP echo request, id 231, seq 1, length 64
02:13:41.658446 00:00:01:01:02:08 > 00:00:01:01:02:03, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.1.4 > 192.168.2.3: ICMP echo reply, id 231, seq 1, length 64
```

发往网关的包通过localnet发往gateway chassis，在gateway chassis上进行路由后又通过localnet发往destination chassis，回复的包路径与此相反。

从上面的分析可以看出，此种设置有一个副作用，设置了此选项的路由器端口，凡是发往此端口进行路由的包对会在gateway chassis上进行路由处理