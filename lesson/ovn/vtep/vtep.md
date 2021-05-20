## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab
docker build -t ovn_lab:v1 .
```


## run container

```
cd ovn_lab/lesson/list/lesson7
./start_compose.sh
```

## 创建host-ovn拓扑

```
docker exec -it host-ovn bash
start_ovs.sh && start_ovn_northd.sh && start_ovn_controller.sh
/root/ovn_lab/create_topo_host_ovn.sh
```

### ping测试

```
# ip netns exec vm1 ping 10.0.0.2 -c 3
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.373 ms
64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=0.061 ms
64 bytes from 10.0.0.2: icmp_seq=3 ttl=64 time=0.061 ms

--- 10.0.0.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.061/0.165/0.373/0.147 ms
```

## 创建host-vtep拓扑

```
docker exec -it host-vtep bash
start_ovs.sh
/root/ovn_lab/create_topo_host_vtep.sh
```
### ping测试

```
# ip netns exec gateway ping 10.0.0.1 -c 3
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=0.890 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=64 time=0.077 ms
64 bytes from 10.0.0.1: icmp_seq=3 ttl=64 time=0.110 ms

--- 10.0.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2000ms
rtt min/avg/max/mdev = 0.077/0.359/0.890/0.375 ms
```

## 创建forward（host-vtep）

```
/root/ovn_lab/create_forward.sh
```

### vm1创建路由（host-ovn）

```
ip netns exec vm1 ip route add 10.0.1.0/24 via 10.0.0.3
```


### ping测试

```
# ip netns exec vm1 ping 10.0.1.1 -c 3
PING 10.0.1.1 (10.0.1.1) 56(84) bytes of data.
64 bytes from 10.0.1.1: icmp_seq=1 ttl=63 time=0.151 ms
64 bytes from 10.0.1.1: icmp_seq=2 ttl=63 time=0.119 ms
64 bytes from 10.0.1.1: icmp_seq=3 ttl=63 time=0.120 ms

--- 10.0.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 1999ms
rtt min/avg/max/mdev = 0.119/0.130/0.151/0.014 ms
```
