## 目标

![image](https://raw.githubusercontent.com/cao19881125/picture_cloud/master/job1-gateway.png)

- 在gateway中使用ovn构建虚拟网络
- 使outer-compute可以ping通inner-computer的192.168.10.10


## 环境构建
### build image

```
git clone https://github.com/cao19881125/ovn_lab.git
cd ovn_lab
docker build -t ovn_lab:v1 .
```

### run container

```
cd ovn_lab/lesson/list/job1
./start_compose.sh
```

### outer-computer

```
docker exec -it outer-computer bash
start_ovs.sh
/root/ovn_lab/create_topo_outer_computer.sh
```

### inner-computer

```
docker exec -it inner-computer bash
start_ovs.sh
/root/ovn_lab/create_topo_inner_computer.sh
```

