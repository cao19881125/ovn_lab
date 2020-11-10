## 目标

```
underlay
ext physical network---------       -----------ext physical network
                       |                 | 
                       |   -----------   |
                       ----|   gw    |----
                           ----------- 
                                |     
                                |     
     ------------------------internal------------------------
              |                 |               |
              |                 |               | 
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
         |   |   |        |   |   |      
        vm1  |  vm3      vm2  |  vm4     
             |                |
             |l2gateway       |l2gateway
        -----------ext1  ----------ext2
          |      |         |     |
          |      |         |     |
         bm1    bm2       bm3   bm4
```
- 通过l2gateway将ovn的虚拟网络和实际的物理网络在二层打通
- 物理网络中的主机bm1、bm2、bm3和bm4可以和ovn中的虚拟主机vm1、vm2、vm3及vm4通信

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab/docker
./build_v2.sh
```


## run container

```
cd ../lesson/ovn/l2gateway
./start_compose.sh
```

## 创建拓扑
```
./start.sh
```

## 测试
1. 进入ovn-gw容器
```
docker exec -it ovn-gw bash
```

2. bm1 ping vm1
```
# ip netns exec bm1 ping 192.168.1.3 -c 2
PING 192.168.1.3 (192.168.1.3) 56(84) bytes of data.
64 bytes from 192.168.1.3: icmp_seq=1 ttl=64 time=1.85 ms
64 bytes from 192.168.1.3: icmp_seq=2 ttl=64 time=0.125 ms

--- 192.168.1.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.125/0.988/1.852/0.864 ms
```

3. bm1 ping 网关192.168.1.1
```
# ip netns exec bm1 ping 192.168.1.1 -c 2
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=254 time=1.92 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=254 time=0.291 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.291/1.104/1.918/0.814 ms
```

4. bm1 ping vm2
```
# ip netns exec bm1 ping 192.168.2.3 -c 2
PING 192.168.2.3 (192.168.2.3) 56(84) bytes of data.
64 bytes from 192.168.2.3: icmp_seq=1 ttl=63 time=1.19 ms
64 bytes from 192.168.2.3: icmp_seq=2 ttl=63 time=0.119 ms

--- 192.168.2.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 0.119/0.652/1.186/0.534 ms

```

5. bm1 ping bm2
```
# ip netns exec bm1 ping 192.168.1.6 -c 2
PING 192.168.1.6 (192.168.1.6) 56(84) bytes of data.
64 bytes from 192.168.1.6: icmp_seq=1 ttl=64 time=0.665 ms
64 bytes from 192.168.1.6: icmp_seq=2 ttl=64 time=0.048 ms

--- 192.168.1.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 58ms
rtt min/avg/max/mdev = 0.048/0.356/0.665/0.309 ms
```

6. bm1 ping bm3
```
# ip netns exec bm1 ping 192.168.2.5 -c 2
PING 192.168.2.5 (192.168.2.5) 56(84) bytes of data.
64 bytes from 192.168.2.5: icmp_seq=1 ttl=63 time=4.62 ms
64 bytes from 192.168.2.5: icmp_seq=2 ttl=63 time=0.058 ms

--- 192.168.2.5 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.058/2.340/4.623/2.283 ms
```

7. bm3 ping vm2
```
# ip netns exec bm3 ping 192.168.2.3 -c 2
PING 192.168.2.3 (192.168.2.3) 56(84) bytes of data.
64 bytes from 192.168.2.3: icmp_seq=1 ttl=64 time=2.22 ms
64 bytes from 192.168.2.3: icmp_seq=2 ttl=64 time=0.127 ms

--- 192.168.2.3 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.127/1.175/2.224/1.049 ms
```

8. bm3 ping 网关192.168.2.1
```
# ip netns exec bm3 ping 192.168.2.1 -c 2
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=254 time=0.465 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=254 time=0.292 ms

--- 192.168.2.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 22ms
rtt min/avg/max/mdev = 0.292/0.378/0.465/0.088 ms
```

9. bm3 ping vm3
```
# ip netns exec bm3 ping 192.168.1.4 -c 2
PING 192.168.1.4 (192.168.1.4) 56(84) bytes of data.
64 bytes from 192.168.1.4: icmp_seq=1 ttl=63 time=1.15 ms
64 bytes from 192.168.1.4: icmp_seq=2 ttl=63 time=0.121 ms

--- 192.168.1.4 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.121/0.634/1.148/0.514 ms
```

10. bm3 ping bm4
```
# ip netns exec bm3 ping 192.168.2.6 -c 2
PING 192.168.2.6 (192.168.2.6) 56(84) bytes of data.
64 bytes from 192.168.2.6: icmp_seq=1 ttl=64 time=0.662 ms
64 bytes from 192.168.2.6: icmp_seq=2 ttl=64 time=0.049 ms

--- 192.168.2.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 45ms
rtt min/avg/max/mdev = 0.049/0.355/0.662/0.307 ms
```

11. bm3 ping bm2
```
# ip netns exec bm3 ping 192.168.1.6 -c 2
PING 192.168.1.6 (192.168.1.6) 56(84) bytes of data.
64 bytes from 192.168.1.6: icmp_seq=1 ttl=63 time=2.19 ms
64 bytes from 192.168.1.6: icmp_seq=2 ttl=63 time=0.046 ms

--- 192.168.1.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.046/1.116/2.186/1.070 ms
```