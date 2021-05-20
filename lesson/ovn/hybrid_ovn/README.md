
## 拓扑
```
topo

  ---------------------         ---------------------
  |         ls1       |         |         ls2       |
  |     10.0.0.0/24   |         |     10.0.0.0/24   |
  ---------------------         ---------------------
      |           |                  |           |             
      |           |                  |           |
      |         br_tunnel--vxlan--br_tunnel      |
      |           |                  |           |
      |           |                  |           |
     vm1         tp1                tp1         vm2            
   10.0.0.10   10.0.0.100        10.0.0.200  10.0.0.20         
      |           |                  |           |             
      ----node1----                  ----node2----             
```
- 两个node ovn1 和 ovn2，上面分别部署一套ovn环境
- 分别在两个node上创建一个ovs bridge br-tunnel，用vxlan打通
- br-tunnel与logical switch的br-int用patch port联通
- ovn-tunnel上分别创建一个端口tp1，仅仅是为了测试用

## 构建

```
cd ovn_lab/lesson/ovn/hybrid_ovn/
./start_compose.sh
```

### 构建ovn1

```
docker exec -it ovn1 bash
start_ovs.sh && start_ovn_northd.sh && start_ovn_controller.sh
/root/ovn_lab/create_topo_ovn1.sh
```

### 构建ovn2

```
docker exec -it ovn2 bash
start_ovs.sh && start_ovn_northd.sh && start_ovn_controller.sh
/root/ovn_lab/create_topo_ovn2.sh
```

## 测试
测试两套ovn之间的连通性
### 在ovn1中执行

```
# ip netns exec vm1 ping 10.0.0.20
PING 10.0.0.20 (10.0.0.20) 56(84) bytes of data.
64 bytes from 10.0.0.20: icmp_seq=1 ttl=64 time=3.14 ms
64 bytes from 10.0.0.20: icmp_seq=2 ttl=64 time=0.153 ms
```

```
# ip netns exec vm1 ping 10.0.0.200
PING 10.0.0.200 (10.0.0.200) 56(84) bytes of data.
64 bytes from 10.0.0.200: icmp_seq=1 ttl=64 time=3.11 ms
64 bytes from 10.0.0.200: icmp_seq=2 ttl=64 time=0.236 ms
64 bytes from 10.0.0.200: icmp_seq=3 ttl=64 time=0.174 ms
```

### 在ovn2中执行

```
# ip netns exec vm2 ping 10.0.0.10
PING 10.0.0.10 (10.0.0.10) 56(84) bytes of data.
64 bytes from 10.0.0.10: icmp_seq=1 ttl=64 time=1.73 ms
64 bytes from 10.0.0.10: icmp_seq=2 ttl=64 time=0.175 ms
```


```
# ip netns exec vm2 ping 10.0.0.100
PING 10.0.0.100 (10.0.0.100) 56(84) bytes of data.
64 bytes from 10.0.0.100: icmp_seq=1 ttl=64 time=13.0 ms
64 bytes from 10.0.0.100: icmp_seq=2 ttl=64 time=0.164 ms
64 bytes from 10.0.0.100: icmp_seq=3 ttl=64 time=0.151 ms
```

