## 目标

```
topo
  ------------------------    
  |       router1        |
  | 10.0.0.1     10.1.0.1|
  ------------------------
      |             |
      |             |    
     vm1           vm2
   10.0.0.10     10.1.0.20  
```

- vm1和vm2可以通过dhcp获取到ip、default gateway
- vm1和vm2可以互相ping通

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab
docker build -t ovn_lab:v1 .
```


## run container

```
cd ovn_lab/lesson/list/lesson4
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


## 测试
### controller
- ping 网关
```
# ip netns exec vm1 ping 10.0.0.1 -c 3
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=254 time=0.290 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=254 time=0.252 ms
64 bytes from 10.0.0.1: icmp_seq=3 ttl=254 time=0.243 ms

--- 10.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.243/0.261/0.290/0.027 ms
```

- ping vm2

```
# ip netns exec vm1 ping 10.1.0.20 -c 3
PING 10.1.0.20 (10.1.0.20) 56(84) bytes of data.
64 bytes from 10.1.0.20: icmp_seq=1 ttl=63 time=1.11 ms
64 bytes from 10.1.0.20: icmp_seq=2 ttl=63 time=0.127 ms
64 bytes from 10.1.0.20: icmp_seq=3 ttl=63 time=0.205 ms

--- 10.1.0.20 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.127/0.482/1.116/0.449 ms
```

### computer
- ping网关
```
# ip netns exec vm2 ping 10.1.0.1 -c 3
PING 10.1.0.1 (10.1.0.1) 56(84) bytes of data.
64 bytes from 10.1.0.1: icmp_seq=1 ttl=254 time=0.252 ms
64 bytes from 10.1.0.1: icmp_seq=2 ttl=254 time=0.315 ms
64 bytes from 10.1.0.1: icmp_seq=3 ttl=254 time=0.327 ms

--- 10.1.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 1999ms
rtt min/avg/max/mdev = 0.252/0.298/0.327/0.032 ms
```

- ping vm1

```
# ip netns exec vm2 ping 10.0.0.10 -c 3
PING 10.0.0.10 (10.0.0.10) 56(84) bytes of data.
64 bytes from 10.0.0.10: icmp_seq=1 ttl=63 time=0.880 ms
64 bytes from 10.0.0.10: icmp_seq=2 ttl=63 time=0.133 ms
64 bytes from 10.0.0.10: icmp_seq=3 ttl=63 time=0.134 ms

--- 10.0.0.10 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.133/0.382/0.880/0.352 ms
```

