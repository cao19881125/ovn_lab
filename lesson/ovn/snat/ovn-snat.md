## 目标

```
topo
         internet
            |
  ------------------------  
  |     10.20.0.100      |
  |       router1        |
  | 10.0.0.1     10.1.0.1|
  ------------------------
      |             |
      |             |    
     vm1           vm2
   10.0.0.10     10.1.0.20  
```

- 继lesson4 router的架构，在其基础上添加snat出外网的功能
- 10.20.0.100 是通往外部交换机的ip，可以通过此ip连接internet
- 目标为vm1 和vm2可以通过router的snat功能通外网

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab
docker build -t ovn_lab:v1 .
```


## run container

```
cd ovn_lab/lesson/list/lesson5
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
- ping 8.8.8.8
```
# ip netns exec vm1 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=2 ttl=126 time=48.6 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=126 time=48.0 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 2 received, 33% packet loss, time 2009ms
rtt min/avg/max/mdev = 48.020/48.327/48.635/0.378 ms
```

### computer
- ping 8.8.8.8
```
# ip netns exec vm2 ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=2 ttl=126 time=48.4 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=126 time=47.8 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 2 received, 33% packet loss, time 2000ms
rtt min/avg/max/mdev = 47.823/48.113/48.404/0.364 ms
```

