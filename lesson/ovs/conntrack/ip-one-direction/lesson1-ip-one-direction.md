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
/root/ovn_lab/lesson/list/lesson1/create_topo.sh
```

## add flow

#### 允许arp协议通过
```
ovs-ofctl add-flow br-int table=0,priority=100,arp,action=normal
```

#### untrack状态的ip包送到conntrack并回来后发到1表
```

ovs-ofctl add-flow br-int table=0,priority=100,ip,ct_state=-trk,action=ct\(table=1\)
```


#### vm1进来的new状态的ip包commit到conntrack并发到2端口
```
ovs-ofctl add-flow br-int table=1,in_port=1,ip,ct_state=+trk+new,action=ct\(commit\),2

```

#### vm1进来的est状态的包发到2端口

```
ovs-ofctl add-flow br-int table=1,in_port=1,ip,ct_state=+trk+est,action=2

```

#### vm2进来的new状态的包直接drop

```
ovs-ofctl add-flow br-int table=1,in_port=2,ip,ct_state=+trk+new,action=drop

```

#### vm2进来的est状态的包发到1端口

```
ovs-ofctl add-flow br-int table=1,in_port=2,ip,ct_state=+trk+est,action=1
```

## 测试
### vm1 ping vm2
```
# ip netns exec vm1 ping 10.0.0.20
PING 10.0.0.20 (10.0.0.20) 56(84) bytes of data.
64 bytes from 10.0.0.20: icmp_seq=1 ttl=64 time=0.314 ms
64 bytes from 10.0.0.20: icmp_seq=2 ttl=64 time=0.217 ms
```

### vm2 ping vm1

```
# ip netns exec vm2 ping 10.0.0.10 -w 3
PING 10.0.0.10 (10.0.0.10) 56(84) bytes of data.

--- 10.0.0.10 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 2999ms
```

