## 目标
> 在lesson4 router的基础上，增加em1,em1为主机上的网卡，测试ovn的localport type端口，本例中使用veth pair模拟em1
```
topo
  ----------------------------------    
  |              router1           |
  |      10.0.0.1          10.1.0.1|
  ----------------------------------
      |          |               |
      |          |               |    
     vm1        em1             vm2
   10.0.0.10  10.0.0.100     10.1.0.20  
```
- em1和vm1属于同一个logical switch
- vm1、em1、vm2可以通过dhcp获取到ip、default gateway
- vm1、em1、vm2可以互相ping通

## build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab
docker build -t ovn_lab:v1 .
```


## run container

```
cd ovn_lab/lesson/list/lesson8
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
- em1 ping vm1
```
# ping 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=254 time=0.446 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=254 time=0.556 ms
```

- em1 ping vm2

```
# ping 10.1.0.20
PING 10.1.0.20 (10.1.0.20) 56(84) bytes of data.
64 bytes from 10.1.0.20: icmp_seq=1 ttl=63 time=1.69 ms
64 bytes from 10.1.0.20: icmp_seq=2 ttl=63 time=0.130 ms
```

### computer


- ping em1

```
# ip netns exec vm2 ping 10.0.0.100
PING 10.0.0.100 (10.0.0.100) 56(84) bytes of data.
64 bytes from 10.0.0.100: icmp_seq=1 ttl=63 time=1.33 ms
64 bytes from 10.0.0.100: icmp_seq=2 ttl=63 time=0.131 ms
```

