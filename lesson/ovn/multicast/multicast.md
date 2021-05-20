
## 拓扑


```
topo
           --------------------      
           |        lr1       |      
           --------------------      
         1.1.1.1|       |1.1.2.1   
            -----       ------
            |                |
            |                |       
       -----------      -----------    
       |   ls1   |      |   ls2   |    
       -----------      -----------    
        |      |             |      
       vm1    vm2           vm5
    1.1.1.2  1.1.1.3      1.1.2.2

```


## run container

```
cd ovn_lab/lesson/ovn/multicast
./start_compose.sh
```

## 构建controller

```
docker exec -it ovn-controller bash
start_ovs.sh && start_ovn_northd.sh && start_ovn_controller.sh
/root/ovn_lab/create_topo_controller.sh
```


## 构建computer

```
docker exec -it ovn-computer bash
start_ovs.sh && start_ovn_controller.sh
/root/ovn_lab/create_topo_computer.sh
```

## 测试多播组
目前还没找到合适的工具将网卡加入多播组，暂时使用omping

### 安装omping
1. controller节点安装omping
```
docker exec -it ovn-controller bash
yum install omping
```

2. computer节点安装omping
```
docker exec -it ovn-computer bash
yum install omping
```

### 将vm1、vm2加入组播组
1. 将vm1加入组播组
```
docker exec -it ovn-controller bash
ip netns exec vm1 omping -m 224.1.1.1 1.1.1.2
```

2. 将vm2加入组播组
```
docker exec -it ovn-computer bash
ip netns exec vm2 omping -m 224.1.1.1 1.1.1.3
```

### 在vm5 ping组播组
```
docker exec -it ovn-computer bash
ip netns exec vm5 ping 224.1.1.1 -c 5 -t 64
```

结果:
```
[root@ovn-computer ovn_lab]# ip netns exec vm5 ping 224.1.1.1 -c 5 -t 64
PING 224.1.1.1 (224.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.3: icmp_seq=1 ttl=63 time=0.732 ms
64 bytes from 1.1.1.2: icmp_seq=1 ttl=63 time=1.25 ms (DUP!)
64 bytes from 1.1.1.3: icmp_seq=2 ttl=63 time=0.141 ms
64 bytes from 1.1.1.2: icmp_seq=2 ttl=63 time=0.210 ms (DUP!)
64 bytes from 1.1.1.3: icmp_seq=3 ttl=63 time=0.177 ms
64 bytes from 1.1.1.2: icmp_seq=3 ttl=63 time=0.268 ms (DUP!)
64 bytes from 1.1.1.3: icmp_seq=4 ttl=63 time=0.096 ms
64 bytes from 1.1.1.2: icmp_seq=4 ttl=63 time=0.146 ms (DUP!)
64 bytes from 1.1.1.3: icmp_seq=5 ttl=63 time=0.131 ms

--- 224.1.1.1 ping statistics ---
5 packets transmitted, 5 received, +4 duplicates, 0% packet loss, time 58ms
rtt min/avg/max/mdev = 0.096/0.349/1.246/0.366 ms
```