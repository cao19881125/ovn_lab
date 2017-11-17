### 目标
构造一个虚拟ip，自动回复arp包和icmp包

### run container

```
cd ovn_lab
OVN_LAB_DIR=`pwd`
docker run -it -d --privileged -v $OVN_LAB_DIR/lesson:/root/ovn_lab/lesson --name 'ovn_lab' ovn_lab:v1 bash

docker exec -it ovn_lab bash
```

### create topology

```
start_ovs.sh
/root/ovn_lab/lesson/list/lesson2/create_topo.sh
```

### arp reply
#### add flow
```
ovs-ofctl add-flow br-int table=0,in_port=1,arp,arp_tpa=10.0.0.1,arp_op=1,actions=move:"NXM_OF_ETH_SRC[]->NXM_OF_ETH_DST[]",mod_dl_src:"02:ac:10:ff:01:01",load:"0x02->NXM_OF_ARP_OP[]",move:"NXM_NX_ARP_SHA[]->NXM_NX_ARP_THA[]",load:"0x02ac10ff0101->NXM_NX_ARP_SHA[]",move:"NXM_OF_ARP_SPA[]->NXM_OF_ARP_TPA[]",load:"0x0a000001->NXM_OF_ARP_SPA[]",in_port

```
#### 测试
```
# ip netns exec vm1 ping 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
# ip netns exec vm1 ip neigh
10.0.0.1 dev vm1 lladdr 02:ac:10:ff:01:01 REACHABLE
```
可以看到vm1成功拿到了10.0.0.1的虚拟mac地址

#### 解析
- move:"NXM_OF_ETH_SRC[]->NXM_OF_ETH_DST[]"  将请求的源mac作为reply的目标mac
- mod_dl_src:"02:ac:10:ff:01:01" 修改reply的源mac为虚拟网关的mac
- load:"0x02->NXM_OF_ARP_OP[]" 修改arp包类型为reply包
- move:"NXM_NX_ARP_SHA[]->NXM_NX_ARP_THA[]" 将request包中的源mac赋值给reply的目标mac
- load:"0x02ac10ff0101->NXM_NX_ARP_SHA[]" 设置reply的源mac
- move:"NXM_OF_ARP_SPA[]->NXM_OF_ARP_TPA[]" 将request包中的源ip赋值给reply的目标ip
- load:"0x0a000001->NXM_OF_ARP_SPA[]" 设置reply包的源ip 为虚拟网关的ip，格式为十进制转换为对应的16进制
- in_port 从进入端口发回去


### icmp reply
#### add flow

```
ovs-ofctl add-flow br-int table=0,in_port=1,icmp,nw_dst=10.0.0.1,icmp_type=8,icmp_code=0,actions=push:"NXM_OF_ETH_SRC[]",push:"NXM_OF_ETH_DST[]",pop:"NXM_OF_ETH_SRC[]",pop:"NXM_OF_ETH_DST[]",push:"NXM_OF_IP_SRC[]",push:"NXM_OF_IP_DST[]",pop:"NXM_OF_IP_SRC[]",pop:"NXM_OF_IP_DST[]",load:"0xff->NXM_NX_IP_TTL[]",load:"0->NXM_OF_ICMP_TYPE[]",in_port

```

#### 测试

```
# ip netns exec vm1 ping 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=255 time=0.343 ms
64 bytes from 10.0.0.1: icmp_seq=2 ttl=255 time=0.160 ms
```

#### 解析
- push:"NXM_OF_ETH_SRC[]"  将源mac push到栈顶
- push:"NXM_OF_ETH_DST[]"  将目标mac push到栈顶
- pop:"NXM_OF_ETH_SRC[]"   从栈顶取一个mac赋值给源mac
- pop:"NXM_OF_ETH_DST[]"   从栈顶取一个mac赋值给目标mac

==以上的这四步完成了源mac和目标mac的互换，后面的源ip于目标ip的互换同理==
