## 目标
![image](https://github.com/cao19881125/picture_cloud/blob/master/ovs-snat.png?raw=true)

- vm1和vm2分属两个网络
- 在br-int流表中使用conntrack实现vm1->vm2的snat

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
/root/ovn_lab/lesson/list/lesson3/create_topo.sh
```

## add flow
#### 添加vm1 ->虚拟网关10.0.0.1的arp reply

```
ovs-ofctl add-flow br-int table=0,in_port=1,arp,arp_tpa=10.0.0.1,arp_op=1,actions=move:"NXM_OF_ETH_SRC[]->NXM_OF_ETH_DST[]",mod_dl_src:"02:ac:10:ff:01:01",load:"0x02->NXM_OF_ARP_OP[]",move:"NXM_NX_ARP_SHA[]->NXM_NX_ARP_THA[]",load:"0x02ac10ff0101->NXM_NX_ARP_SHA[]",move:"NXM_OF_ARP_SPA[]->NXM_OF_ARP_TPA[]",load:"0x0a000001->NXM_OF_ARP_SPA[]",in_port

```


#### 添加vm2 到虚拟网关10.1.0.1的arp和icmp

```
ovs-ofctl add-flow br-int table=0,in_port=2,arp,arp_tpa=10.1.0.1,arp_op=1,actions=move:"NXM_OF_ETH_SRC[]->NXM_OF_ETH_DST[]",mod_dl_src:"02:ac:10:ff:05:01",load:"0x02->NXM_OF_ARP_OP[]",move:"NXM_NX_ARP_SHA[]->NXM_NX_ARP_THA[]",load:"0x02ac10ff0501->NXM_NX_ARP_SHA[]",move:"NXM_OF_ARP_SPA[]->NXM_OF_ARP_TPA[]",load:"0x0a010001->NXM_OF_ARP_SPA[]",in_port
```
#### 配置vm1和vm2的默认路由

```
ip netns exec vm1 ip route add default via 10.0.0.1
ip netns exec vm2 ip route add default via 10.1.0.1
```



#### 添加vm1 -> vm2的snat

```
ovs-ofctl add-flow br-int table=0,in_port=1,ip,nw_dst=10.1.0.0/24,action=ct\(commit,table=1,nat\(src=10.1.0.1\)\)
ovs-ofctl add-flow br-int table=0,in_port=2,ip,nw_dst=10.1.0.1,actions=ct\(nat,table=1\)

```
- 从vm1发过来的ip包，目标网络为10.1.0.0/24的，发往conntrack，使其执行nat操作，将源IP改为10.1.0.1，处理完转送1表
- 从vm2发过来的ip包，目标ip为网关的，发往conntrack匹配已经存在的记录，使其修改目标ip，处理完转送1表

```
ovs-ofctl add-flow br-int table=1,ip,nw_src=10.1.0.1,nw_dst=10.1.0.20,actions=mod_dl_src:"02:ac:10:ff:05:01",mod_dl_dst:"02:ac:10:ff:01:31",vm2
ovs-ofctl add-flow br-int table=1,ip,nw_dst=10.0.0.10,actions=mod_dl_src:"02:ac:10:ff:01:01",mod_dl_dst:"02:ac:10:ff:01:30",vm1

```
- 源ip为10.1.0.1，目标ip为10.1.0.20的包，修改源mac和目标mac为其对应的mac，这一条匹配从vm1->vm2的request
- 目标ip为10.0.0.10的包，修改源mac为网关（10.0.0.1）的mac，修改目标mac为10.0.0.10的mac

#### 测试
```
# ip netns exec vm1 ping 10.1.0.20
PING 10.1.0.20 (10.1.0.20) 56(84) bytes of data.
64 bytes from 10.1.0.20: icmp_seq=1 ttl=64 time=0.289 ms
64 bytes from 10.1.0.20: icmp_seq=2 ttl=64 time=0.072 ms
```



## 总结
结合以上实验可知
### ct(commit,table=1,nat(src=10.1.0.1))

- 提交到CT，使其记录为snat，修改数据包的源ip
- 仅仅修改了源ip，源mac和目标mac均未变
- 修改后的记录转发到1表

### ct(table=1,nat)
- 去CT里面找已经存在的nat记录并匹配
- CT修改数据包的目标IP，并转发到1表
- 仅仅修改了目标IP，mac地址均未修改



