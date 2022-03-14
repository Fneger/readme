# Filecoin lotus部署步骤

## 1.部署ceph集群

ceph集群搭建硬件要求

每OSD 1GB内存

一台主机需要日志等相关数据需要一个SSD

一台主机需要两块SSD做OSD前端缓存（针对OSD设备是机械硬盘的情况）

至少需要2n+1个mon

## 2.安装相关驱动

### 安装显卡驱动

### 安装htop工具

### 安装nvtop工具

### CPU开启性能模式

## 3.编译安装lotus

## 4.配置lotus相关环境变量

## 5.启动lotus节点

### 配置lotus节点公网IP

### 创建lotus钱包

## 6.启动lotus miner

### new-miner-checklist

```
# 新矿工节点上线CheckList

## 1. 机器CheckList
- [ ] 所有Miner和计算Worker用户名必须一致
- [ ] hostname按照以下格式命名:
  - Miner-192-168-1-3
  - Daemon-192-168-1-4
  - WorkerP-192-168-1-5 (PreCommit Worker)
  - WorkerC-192-168-1-6 (Commit Worker)
- [ ] 禁用所有机器(Miner和Worker)的swap
- [ ] Ubuntu系统禁用自动更新
- [ ] 显卡驱动禁用自动更新

## 2. 部署CheckList
- [ ] 设置Miner和Worker机器SSH免密码登录
- [ ] Ubuntu apt源更新为国内镜像(无国际线路的情况)
- [ ] 安装基础依赖库
  ```sh
  sudo apt update
  sudo apt install -y make pkg-config mesa-opencl-icd ocl-icd-opencl-dev libclang-dev libhwloc-dev hwloc gcc git bzr jq tree openssh-server python3 cpufrequtils
```
- [ ] 安装显卡驱动
  ```
  sudo ./NVIDIA-Linux-x86_64-xxx.xx.xx.run
  ```
- [ ] 时钟校验
  ```sh
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  ntpdate ntp.aliyun.com
  ```
- [ ] Seal-miner的NVME SSD组Raid5，挂载，设置目录挂载权限
- [ ] NVME SSD批量组Raid0，挂载，设置挂载目录的权限
  - 更新挂载路径
  - 更新起始盘符
  - 更新`--raid-devices`数量
  - 更新分区数量
  - 更新用户名和组
- [ ] 给Deamon、Miner和C2-worker上拷贝证明参数

### 3. Deamon CheckList
**Deamon 启动说明**
用一台独立的机器启动一个带公网IP的Deamon备用节点，然后在Winning-PoSt-miner和Window-PoSt-miner上再分别启动一个节点，PoSt-miner通过内网连接各自机器上的Deamon。

- [ ] 检查独立Deamon机器的公网和端口是否能通(远程telnet)
- [ ] 配置独立Deamon的环境变量，初始化并启动Deamon
- [ ] 配置独立Deamon的`ListenAddress`为公网IP和端口，同步到最新高度
- [ ] 启动Winning-PoSt-miner和Window-PoSt-miner上的Deamon并同步到最新高度

### 4. Miner CheckList
- [ ] 配置Miner的环境变量，初始化Miner(默认为Seal-miner)
  ```sh
  lotus-miner init --owner f3xxxxxxxx
  ```
- [ ] 修改Miner的配置文件，更改[API]、[Storage]、[Fees]中的相关配置
  ```toml
  MaxPreCommitGasFee = "0.15 FIL"
  MaxCommitGasFee = "0.3 FIL"
  ```
- [ ] 复制`LOTUS_MINER`目录到Winning-PoSt-miner和Window-PoSt-miner上
- [ ] Seal-miner、Winning-PoSt-miner、Window-PoSt-miner分别挂载存储
- [ ] 启动Seal-miner，配置扇区ID分配的Server
- [ ] 启动Winning-PoSt-miner、Window-PoSt-miner
- [ ] 设置Miner sectorstore.json 中的`CanStore`为`false`
- [ ] Seal-miner、Winning-PoSt-miner、Window-PoSt-miner attach存储
  ```sh
  lotus-miner storage attach --store --init /home/ubuntu/sectorsdir/storage
  ```
- [ ] 为Window-PoSt、PreCommitSector和ProveCommitSector设置独立的钱包
- [ ] inotify+rsync实时备份Seal-miner、Winning-PoSt-miner、Window-PoSt-miner

### 5. Worker CheckList
- [ ] 配置Worker的环境变量，更改调度配置文件
- [ ] 检查显卡驱动是否正常
- [ ] 检查缓存盘是否正确挂载
- [ ] PreCommit Worker设置性能模式`sudo cpufreq-set -g performance`
- [ ] 批量启动P1 + P2 Worker
- [ ] 批量启动C2 Worker
```

### 初始化矿工

```
lotus-miner init --owner=<address>  --worker=<address> --no-local-storage
```

--worker可后续添加
--no-local-storage 指定特定储存位置，建议使用

### 指定miner储存位置

密封缓存文件储存位置
lotus-miner storage attach --init --seal <PATH_FOR_SEALING_STORAGE>
密封完成后，移动到下列指定储存位置
lotus-miner storage attach --init --store <PATH_FOR_LONG_TERM_STORAGE>
列出储存位置
lotus-miner storage list

### 启动miner

### miner多钱包配置

### 修改miner配置文件

## 7.启动worker
```

## 7.备份

## 8.启动系统监控工具（待开发）

## Ulimit 问题：Too many open files (os error 24)

miner 在运行过程中可能会出现这个错误 `Too many open files (os error 24)`， 导致程序退出，解决的方法就是设置系统中最大允许的文件打开数量：

`ulimit` 命令分别可以作用于 `soft` 类型和 `hard` 类型，`soft` 表示可以超出，但只是警告 `hard` 表示绝对不能超出，两者的值一般是不一样的:

```
# 查看当前值（默认是 soft 值）：
ulimit -a | grep -ni "open"
# 查看当前值 soft 值：
ulimit -Sa | grep -ni "open"
# 查看当前值 hard 值：
ulimit -Ha | grep -ni "open"

# 临时修改（只对当前 Shell 有用，修改立即生效）：
# 修改为 1048576 （默认修改的是 soft 值）：
ulimit -n 1048576  # 等效于 ulimit -Sn 1048576
# 临时修改 hard 值为 1048576
ulimit -Hn 1048576
# 可同时修改 soft 和 hard 的值：
ulimit -SHn 1048576

# 针对正在运行中的miner进程，可以通过以下命令修改：
prlimit --pid <PID> --nofile=1048576:1048576
# 通过以下命令查看修改：
cat /proc/<PID>/limits

# 永久修改（重新登录或重启生效）: 
# 把文件 /etc/systemd/user.conf  和 /etc/systemd/system.conf 中的字段修改如下：
DefaultLimitNOFILE=1048576
# 并修改 /etc/security/limits.conf 文件，添加如下内容：
* hard nofile 1048576
* soft nofile 1048576
```

