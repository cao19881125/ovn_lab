## 目标

```
underlay
                                         
                           ----------- 
                          | ovn-outer |
                           ----------- 
                                |     
                                |     
     ------------------------external------------------------
              |                 |               |
              |                 |               | 
         -----------       ------------    -----------
         | ovn-hv2  |     | ovn-ctrl  |   | ovn-hv1   |
         -----------       ------------    -----------
              |                 |               |
              |                 |               | 
     -------------------------------------------------------- 10.10.0.0/24

overlay topo
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
             |localnet        |localnet
             |vlan10          |vlan20
        ------------------------------
          |vlan10 |vlan10 |vlan20 |
          |       |       |       |
         bm1     bm2     bm3     bm4
```
- 通过localnet将ovn的虚拟网络和实际的物理网络在二层打通
- 逻辑交换机上的localnet端口在每个chassis上都存在，因此每个chassis上都要设置network
- 物理网络中的主机bm1、bm2、bm3和bm4可以和ovn中的虚拟主机vm1、vm2、vm3及vm4通信

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab/docker
./build_v2.sh
```


## run container

```
cd ../lesson/ovn/localnet
./start_compose.sh
```

## 创建拓扑
```
./start.sh
```

## 测试
### vm1 ping bm1 bm3
```
# docker exec -it ovn-hv1 bash
bash-4.4# ip netns exec vm1 ping 192.168.1.5 -c 2
PING 192.168.1.5 (192.168.1.5) 56(84) bytes of data.
64 bytes from 192.168.1.5: icmp_seq=1 ttl=64 time=1.10 ms
64 bytes from 192.168.1.5: icmp_seq=2 ttl=64 time=0.079 ms

--- 192.168.1.5 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.079/0.587/1.096/0.509 ms
bash-4.4# ip netns exec vm1 ping 192.168.2.5 -c 2
PING 192.168.2.5 (192.168.2.5) 56(84) bytes of data.
64 bytes from 192.168.2.5: icmp_seq=1 ttl=63 time=6.70 ms
64 bytes from 192.168.2.5: icmp_seq=2 ttl=63 time=0.071 ms

--- 192.168.2.5 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.071/3.384/6.698/3.314 ms
bash-4.4# exit
exit
```

### vm2 ping bm2 bm4
```
# docker exec -it ovn-hv1 bash
bash-4.4# ip netns exec vm2 ping 192.168.1.6 -c 2
PING 192.168.1.6 (192.168.1.6) 56(84) bytes of data.
64 bytes from 192.168.1.6: icmp_seq=1 ttl=63 time=5.22 ms
64 bytes from 192.168.1.6: icmp_seq=2 ttl=63 time=0.068 ms

--- 192.168.1.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.068/2.642/5.217/2.575 ms
bash-4.4# ip netns exec vm2 ping 192.168.2.6 -c 2
PING 192.168.2.6 (192.168.2.6) 56(84) bytes of data.
64 bytes from 192.168.2.6: icmp_seq=1 ttl=64 time=1.44 ms
64 bytes from 192.168.2.6: icmp_seq=2 ttl=64 time=0.069 ms

--- 192.168.2.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 0.069/0.753/1.438/0.685 ms
bash-4.4# exit
exit
```

### vm3 ping bm2 bm4
```
# docker exec -it ovn-hv2 bash
bash-4.4# ip netns exec vm3 ping 192.168.1.6 -c 2
PING 192.168.1.6 (192.168.1.6) 56(84) bytes of data.
64 bytes from 192.168.1.6: icmp_seq=1 ttl=64 time=1.25 ms
64 bytes from 192.168.1.6: icmp_seq=2 ttl=64 time=0.073 ms

--- 192.168.1.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.073/0.662/1.251/0.589 ms
bash-4.4# ip netns exec vm3 ping 192.168.2.6 -c 2
PING 192.168.2.6 (192.168.2.6) 56(84) bytes of data.
64 bytes from 192.168.2.6: icmp_seq=1 ttl=63 time=3.08 ms
64 bytes from 192.168.2.6: icmp_seq=2 ttl=63 time=0.072 ms

--- 192.168.2.6 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.072/1.574/3.077/1.503 ms
bash-4.4# exit
exit
```

### vm4 ping bm1 bm3
```
# docker exec -it ovn-hv2 bash
bash-4.4# ip netns exec vm4 ping 192.168.1.5 -c 2
PING 192.168.1.5 (192.168.1.5) 56(84) bytes of data.
64 bytes from 192.168.1.5: icmp_seq=1 ttl=63 time=3.55 ms
64 bytes from 192.168.1.5: icmp_seq=2 ttl=63 time=0.063 ms

--- 192.168.1.5 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.063/1.804/3.546/1.742 ms
bash-4.4# ip netns exec vm4 ping 192.168.2.5 -c 2
PING 192.168.2.5 (192.168.2.5) 56(84) bytes of data.
64 bytes from 192.168.2.5: icmp_seq=1 ttl=64 time=1.27 ms
64 bytes from 192.168.2.5: icmp_seq=2 ttl=64 time=0.085 ms

--- 192.168.2.5 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 2ms
rtt min/avg/max/mdev = 0.085/0.675/1.265/0.590 ms
bash-4.4# exit
exit
```

### bm1 ping 网关
```
# docker exec -it ovn-outer bash
bash-4.4# ip netns exec bm1 ping 192.168.1.1 -c 2
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=254 time=0.617 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=254 time=0.395 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 18ms
rtt min/avg/max/mdev = 0.395/0.506/0.617/0.111 ms
bash-4.4# ip netns exec bm1 ping 192.168.2.1 -c 2
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=254 time=0.438 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=254 time=0.358 ms

--- 192.168.2.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 64ms
rtt min/avg/max/mdev = 0.358/0.398/0.438/0.040 ms
bash-4.4# exit
exit
```

### bm3 ping 网关
```
# docker exec -it ovn-outer bash
bash-4.4# ip netns exec bm3 ping 192.168.1.1 -c 2
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=254 time=0.598 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=254 time=0.302 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 60ms
rtt min/avg/max/mdev = 0.302/0.450/0.598/0.148 ms
bash-4.4# ip netns exec bm3 ping 192.168.2.1 -c 2
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=254 time=0.445 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=254 time=0.317 ms

--- 192.168.2.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 64ms
rtt min/avg/max/mdev = 0.317/0.381/0.445/0.064 ms
bash-4.4# exit
exit
```