## 目标
```
network topology
        --------------------------
        |         router         |
        | 10.20.1.1    10.20.2.1 |
        --------------------------
              |             |
              |             |
             vm1           vm2
         10.20.1.100   10.20.2.100
```

* vm1可以ping通10.20.1.1、10.20.2.1以及vm2
* vm2可以ping通10.20.2.1、10.20.1.1以及vm1
* vm1可以通过tcp访问vm2
* vm2不可以通过tcp访问vm1

## run container

```
cd ovn_lab
OVN_LAB_DIR=`pwd`
docker run -it -d --privileged -v $OVN_LAB_DIR/lesson:/root/ovn_lab/lesson --name 'ovn_lab' ovn_lab:v1 bash
docker exec -it ovn_lab bash
```

## create topology
```
start_ovs.sh
/root/ovn_lab/lesson/list/lesson10/create_topo.sh
```

## 配置vm1和vm2的默认路由
```
ip netns exec vm1 ip route add default via 10.20.1.1
ip netns exec vm2 ip route add default via 10.20.2.1
```

## add flow table

1.ovs端口1对10.20.1.1的ARP应答和ICMP应答
```
ovs-ofctl add-flow switch "table=0,in_port=1,arp,arp_tpa=10.20.1.1,arp_op=1 actions=load:0x2->NXM_OF_ARP_OP[],move:NXM_OF_ETH_SRC[]->NXM_OF_ETH_DST[],move:NXM_NX_ARP_SHA[]->NXM_NX_ARP_THA[],move:NXM_OF_ARP_SPA[]->NXM_OF_ARP_TPA[],mod_dl_src:92:14:02:ed:ed:46,load:0x921402eded46->NXM_NX_ARP_SHA[],load:0x0a140101->NXM_OF_ARP_SPA[],IN_PORT"
ovs-ofctl add-flow switch "table=0,in_port=1,icmp,nw_dst=10.20.1.1,icmp_type=8,icmp_code=0 actions=push:NXM_OF_ETH_SRC[],push:NXM_OF_ETH_DST[],pop:NXM_OF_ETH_SRC[],pop:NXM_OF_ETH_DST[],push:NXM_OF_IP_SRC[],push:NXM_OF_IP_DST[],pop:NXM_OF_IP_SRC[],pop:NXM_OF_IP_DST[],load:0xff->NXM_NX_IP_TTL[],load:0->NXM_OF_ICMP_TYPE[],IN_PORT"
```

2.ovs端口2对10.20.2.1的ARP应答和ICMP应答
```
ovs-ofctl add-flow switch "table=0,in_port=2,arp,arp_tpa=10.20.2.1,arp_op=1 actions=load:0x2->NXM_OF_ARP_OP[],move:NXM_OF_ETH_SRC[]->NXM_OF_ETH_DST[],move:NXM_NX_ARP_SHA[]->NXM_NX_ARP_THA[],move:NXM_OF_ARP_SPA[]->NXM_OF_ARP_TPA[],mod_dl_src:92:14:02:ed:ed:46,load:0x921402eded46->NXM_NX_ARP_SHA[],load:0x0a140201->NXM_OF_ARP_SPA[],IN_PORT"
ovs-ofctl add-flow switch "table=0,in_port=2,icmp,nw_dst=10.20.2.1,icmp_type=8,icmp_code=0 actions=push:NXM_OF_ETH_SRC[],push:NXM_OF_ETH_DST[],pop:NXM_OF_ETH_SRC[],pop:NXM_OF_ETH_DST[],push:NXM_OF_IP_SRC[],push:NXM_OF_IP_DST[],pop:NXM_OF_IP_SRC[],pop:NXM_OF_IP_DST[],load:0xff->NXM_NX_IP_TTL[],load:0->NXM_OF_ICMP_TYPE[],IN_PORT"
```

3.ovs端口1对10.20.2.1的ICMP应答
```
ovs-ofctl add-flow switch "table=0,in_port=1,icmp,nw_dst=10.20.2.1,icmp_type=8,icmp_code=0 actions=push:NXM_OF_ETH_SRC[],push:NXM_OF_ETH_DST[],pop:NXM_OF_ETH_SRC[],pop:NXM_OF_ETH_DST[],push:NXM_OF_IP_SRC[],push:NXM_OF_IP_DST[],pop:NXM_OF_IP_SRC[],pop:NXM_OF_IP_DST[],load:0xff->NXM_NX_IP_TTL[],load:0->NXM_OF_ICMP_TYPE[],IN_PORT"
```

4.ovs端口2对10.20.1.1的ICMP应答
```
ovs-ofctl add-flow switch "table=0,in_port=2,icmp,nw_dst=10.20.1.1,icmp_type=8,icmp_code=0 actions=push:NXM_OF_ETH_SRC[],push:NXM_OF_ETH_DST[],pop:NXM_OF_ETH_SRC[],pop:NXM_OF_ETH_DST[],push:NXM_OF_IP_SRC[],push:NXM_OF_IP_DST[],pop:NXM_OF_IP_SRC[],pop:NXM_OF_IP_DST[],load:0xff->NXM_NX_IP_TTL[],load:0->NXM_OF_ICMP_TYPE[],IN_PORT"
```

5.ovs端口1转发目标为10.20.2.100的ICMP
```
ovs-ofctl add-flow switch "table=0,in_port=1,icmp,nw_dst=10.20.2.100 actions=move:NXM_OF_ETH_DST[]->NXM_OF_ETH_SRC[],mod_dl_dst:02:ac:10:ff:01:31,output:2"
```

6.ovs端口2转发目标为10.20.1.100的ICMP
```
ovs-ofctl add-flow switch "table=0,in_port=2,icmp,nw_dst=10.20.1.100 actions=move:NXM_OF_ETH_DST[]->NXM_OF_ETH_SRC[],mod_dl_dst:02:ac:10:ff:01:30,output:1"
```

7.ovs端口1转发目标为10.20.2.100的tcp
```
ovs-ofctl add-flow switch "table=0,priority=500,in_port=1,tcp,nw_dst=10.20.2.100 actions=move:NXM_OF_ETH_DST[]->NXM_OF_ETH_SRC[],mod_dl_dst:02:ac:10:ff:01:31,output:2"
```

8.ovs端口2转发目标为10.20.1.100的tcp
```
ovs-ofctl add-flow switch "table=0,priority=500,in_port=2,tcp,nw_dst=10.20.1.100 actions=move:NXM_OF_ETH_DST[]->NXM_OF_ETH_SRC[],mod_dl_dst:02:ac:10:ff:01:30,output:1"
```

9.ovs端口2丢弃tcp握手包
```
ovs-ofctl add-flow switch "table=0,priority=600,in_port=2,tcp,nw_dst=10.20.1.100,tcp_flags=+syn-ack action=drop"
```

## 测试
1.vm1主机ping 10.20.1.1
```
# ip netns exec vm1 ping 10.20.1.1 -c 3
PING 10.20.1.1 (10.20.1.1) 56(84) bytes of data.
64 bytes from 10.20.1.1: icmp_seq=1 ttl=255 time=0.552 ms
64 bytes from 10.20.1.1: icmp_seq=2 ttl=255 time=0.613 ms
64 bytes from 10.20.1.1: icmp_seq=3 ttl=255 time=0.592 ms

--- 10.20.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 0.552/0.585/0.613/0.037 ms
```

2.vm1主机ping 10.20.2.1
```
# ip netns exec vm1 ping 10.20.2.1 -c 3
PING 10.20.2.1 (10.20.2.1) 56(84) bytes of data.
64 bytes from 10.20.2.1: icmp_seq=1 ttl=255 time=0.275 ms
64 bytes from 10.20.2.1: icmp_seq=2 ttl=255 time=0.622 ms
64 bytes from 10.20.2.1: icmp_seq=3 ttl=255 time=0.619 ms

--- 10.20.2.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2013ms
rtt min/avg/max/mdev = 0.275/0.505/0.622/0.163 ms
```

3.vm1主机ping 10.20.2.100
```
# ip netns exec vm1 ping 10.20.2.100 -c 3
PING 10.20.2.100 (10.20.2.100) 56(84) bytes of data.
64 bytes from 10.20.2.100: icmp_seq=1 ttl=64 time=0.918 ms
64 bytes from 10.20.2.100: icmp_seq=2 ttl=64 time=0.097 ms
64 bytes from 10.20.2.100: icmp_seq=3 ttl=64 time=0.114 ms

--- 10.20.2.100 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 0.097/0.376/0.918/0.383 ms
```

4.vm2主机ping 10.20.2.1
```
# ip netns exec vm2 ping 10.20.2.1 -c 3
PING 10.20.2.1 (10.20.2.1) 56(84) bytes of data.
64 bytes from 10.20.2.1: icmp_seq=1 ttl=255 time=0.236 ms
64 bytes from 10.20.2.1: icmp_seq=2 ttl=255 time=0.571 ms
64 bytes from 10.20.2.1: icmp_seq=3 ttl=255 time=1.12 ms

--- 10.20.2.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 0.236/0.643/1.124/0.367 ms
```

5.vm2主机ping 10.20.1.1
```
# ip netns exec vm2 ping 10.20.1.1 -c 3
PING 10.20.1.1 (10.20.1.1) 56(84) bytes of data.
64 bytes from 10.20.1.1: icmp_seq=1 ttl=255 time=0.298 ms
64 bytes from 10.20.1.1: icmp_seq=2 ttl=255 time=0.560 ms
64 bytes from 10.20.1.1: icmp_seq=3 ttl=255 time=0.276 ms

--- 10.20.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2007ms
rtt min/avg/max/mdev = 0.276/0.378/0.560/0.129 ms
```

6.vm2主机ping 10.20.1.100
```
# ip netns exec vm2 ping 10.20.1.100 -c 3
PING 10.20.1.100 (10.20.1.100) 56(84) bytes of data.
64 bytes from 10.20.1.100: icmp_seq=1 ttl=64 time=0.480 ms
64 bytes from 10.20.1.100: icmp_seq=2 ttl=64 time=0.098 ms
64 bytes from 10.20.1.100: icmp_seq=3 ttl=64 time=0.058 ms

--- 10.20.1.100 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 0.058/0.212/0.480/0.190 ms
```

7.vm1主机tcp访问vm2主机
* 安装python和telnet
```
yum -y install python telnet
```
* 在vm2主机上启动SimpleHTTPServer
```
ip netns exec vm2 python -m SimpleHTTPServer
```
* 在vm1主机上连接vm2主机上的SimpleHTTPServer
```
# ip netns exec vm1 telnet 10.20.2.100 8000
Trying 10.20.2.100...
Connected to 10.20.2.100.
Escape character is '^]'.
get
<head>
<title>Error response</title>
</head>
<body>
<h1>Error response</h1>
<p>Error code 400.
<p>Message: Bad request syntax ('get').
<p>Error code explanation: 400 = Bad request syntax or unsupported method.
</body>
Connection closed by foreign host.
```

8.vm2主机tcp访问vm1主机
* 在vm1主机上启动SimpleHTTPServer
```
ip netns exec vm1 python -m SimpleHTTPServer
```
* 在vm2主机上连接vm1主机上的SimpleHTTPServer
```
# ip netns exec vm2 telnet 10.20.1.100 8000
Trying 10.20.1.100...
telnet: connect to address 10.20.1.100: Connection timed out
```
