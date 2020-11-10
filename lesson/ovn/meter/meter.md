
## 拓扑


```
topo
                    internet
                        |
  ----------------------------------------------  
  |                 10.20.0.100                |
  |                   router1                  |
  |      10.0.0.1                   10.1.0.1   |
  ----------------------------------------------
      |           |                |          |
      |           |                |          |
     vm1         vm2              vm3        vm4
   10.0.0.10   10.0.0.11        10.1.0.10  10.1.0.11  
```


## run container

```
cd ovn_lab/lesson/ovn/meter
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

## 限制到vm2的网速
### 先测试不加限制的网速

在computer上
```
ip netns exec vm2 bash
iperf3 -s
```

在controller上
```
ip netns exec vm1 bash
iperf3 -c 10.0.0.11
```

结果

```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  18.6 GBytes  16.0 Gbits/sec  586             sender
[  5]   0.00-10.04  sec  18.6 GBytes  15.9 Gbits/sec                  receiver
```

### 限制到vm2的网速到1000kbps

```
ovn-nbctl qos-add lswitch1 to-lport 100 'outport == "ls1-vm2"' rate=1000
```

再测一遍，结果

```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  1.81 MBytes  1.52 Mbits/sec  324             sender
[  5]   0.00-10.04  sec  1.37 MBytes  1.15 Mbits/sec                  receiver
```

### 添加dnat并限制dnat网速


```
ovn-nbctl qos-del lswitch1

ovn-nbctl lr-nat-add router dnat 10.20.0.102 10.0.0.11

ovn-nbctl qos-add outside to-lport 110 'outport == "outside-router1"' rate=1000
```

添加了一个dnat到vm2，同样在computer节点的vm2上执行iperf3服务端

在controller的host网络中执行iperf3客户端


```
iperf3 -c 10.20.0.102
```

```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  1.79 MBytes  1.50 Mbits/sec  262             sender
[  5]   0.00-10.04  sec  1.37 MBytes  1.15 Mbits/sec                  receiver
```
限速成功


### 测试snat限速

- 在controller的host network中用iperf分别监听9998和8888两个端口
- 在vm1和vm2中分别用iperf做为客户端去连接host的9999和8888端口，测试速度

#### 添加限速

```
ovn-nbctl qos-add outside from-port 110 'inport=="outside-router1"' rate=1000
```

#### 在controller上执行监听

启动两个shell分别执行
```
iperf3 -s -p 9999
```
```
iperf3 -s -p 8888
```
#### 在vm1和vm2中同时执行
vm1中

```
iperf3 -c 10.20.0.10 -p 9999
```

vm2中

```
iperf3 -c 10.20.0.10 -p 8888
```

#### 结果
vm1

```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  2.00 MBytes  1.68 Mbits/sec  228             sender
[  5]   0.00-10.04  sec  1.02 MBytes   855 Kbits/sec                  receiver
```

vm2

```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec   588 KBytes   482 Kbits/sec  185             sender
[  5]   0.00-10.04  sec   462 KBytes   377 Kbits/sec                  receiver
```
