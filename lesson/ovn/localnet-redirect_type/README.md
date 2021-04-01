## 目的
通过将分布式路由器端口的redirect-type设置为bridged，将ovn中的南北向流量修改为通过localnet发往gateway chassis，而不是通过tunnel

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

vm1 ping 8.8.8.8

在ovn-hv1 eth1网卡上抓包:
```
root@ovn-hv1:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:51:38.624594 aa:bb:cc:dd:ee:11 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 192.168.1.3 > 8.8.8.8: ICMP echo request, id 221, seq 1, length 64
02:51:38.670608 aa:bb:cc:dd:ee:33 > 00:00:01:01:02:0a, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 8.8.8.8 > 192.168.1.3: ICMP echo reply, id 221, seq 1, length 64
```

在ovn-gw1 eth1网卡上抓包:
```
root@ovn-gw1:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:51:38.624686 aa:bb:cc:dd:ee:11 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 192.168.1.3 > 8.8.8.8: ICMP echo request, id 221, seq 1, length 64
02:51:38.625460 00:00:01:01:02:05 > 02:42:a5:6e:ce:84, ethertype IPv4 (0x0800), length 98: 10.20.0.100 > 8.8.8.8: ICMP echo request, id 221, seq 1, length 64
02:51:38.669728 02:42:a5:6e:ce:84 > 00:00:01:01:02:05, ethertype IPv4 (0x0800), length 98: 8.8.8.8 > 10.20.0.100: ICMP echo reply, id 221, seq 1, length 64
02:51:38.670577 aa:bb:cc:dd:ee:33 > 00:00:01:01:02:0a, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 8.8.8.8 > 192.168.1.3: ICMP echo reply, id 221, seq 1, length 64
```

路由在source chassis进行处理，然后包通过localnet发送到gateway chassis。

## 测试东西向流量

### 同logical switch
vm1 ping vm3

在ovn-hv1 eth1上抓包
```
root@ovn-hv2:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:46:46.148378 00:00:01:01:02:0a > 00:00:01:01:02:08, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.1.3 > 192.168.1.4: ICMP echo request, id 177, seq 1, length 64
02:46:46.149075 00:00:01:01:02:08 > 00:00:01:01:02:0a, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.1.4 > 192.168.1.3: ICMP echo reply, id 177, seq 1, length 64
```

同逻辑交换机上位于不同chassis的虚拟机间通信直接通过localnet进行

### 不同logical switch
vm2 ping vm3 

在ovn-hv1 eth1上抓包
```
root@ovn-hv2:/# tcpdump -i eth1 -nn -e icmp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), capture size 262144 bytes
02:48:01.866316 aa:bb:cc:dd:ee:11 > 00:00:01:01:02:09, ethertype 802.1Q (0x8100), length 102: vlan 20, p 0, ethertype IPv4, 192.168.1.3 > 192.168.2.4: ICMP echo request, id 185, seq 7, length 64
02:48:01.866355 aa:bb:cc:dd:ee:22 > 00:00:01:01:02:0a, ethertype 802.1Q (0x8100), length 102: vlan 10, p 0, ethertype IPv4, 192.168.2.4 > 192.168.1.3: ICMP echo reply, id 185, seq 7, length 64
```

路由在source chassis上进行，然后通过localnet直接发送到destination chassis，同时网关的mac地址被修改为ovn-chassis-mac-mappings设置的mac地址
