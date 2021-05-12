# ceph 分布式存储服务器部署

## 磁盘相关操作命令

查看是否4K对齐
sudo fdisk -lu
测试磁盘读写速度
sudo hdparm -tT /dev/sda
找出SATA硬盘的连接速度
sudo hdparm -I /dev/sda | grep -i speed
查看SATA接口支持的连接速度

dmesg | grep -i sata | grep 'link up'

## 硬件要求

### RAM内存

元数据服务器和监视器必须可以尽快地提供它们的数据，所以他们应该有足够的内存，至少每进程 1GB 。 OSD 的日常运行不需要那么多内存（如每进程 500MB ）差不多了；然而在恢复期间它们占用内存比较大（如每进程每 TB 数据需要约 1GB 内存）。通常内存越多越好

要谨慎地规划数据存储配置，因为其间涉及明显的成本和性能折衷。来自操作系统的并行操作和到单个硬盘的多个守护进程并发读、写请求操作会极大地降低性能。文件系统局限性也要考虑： btrfs 尚未稳定到可以用于生产环境的程度，但它可以同时记日志并写入数据，而 xfs 和 ext4 却不能
因为 Ceph 发送 ACK 前必须把所有数据写入日志（至少对 xfs 和 ext4 来说是），因此均衡日志和 OSD 性能相当重要

Tip 不顾分区而在单个硬盘上运行多个OSD，这样不明智！
Tip 不顾分区而在运行了OSD的硬盘上同时运行监视器或元数据服务器也不明智！

推荐独立的驱动器用于安装操作系统和软件，另外每个 OSD 守护进程占用一个驱动器

Ceph 允许你在每块硬盘驱动器上运行多个 OSD ，但这会导致资源竞争并降低总体吞吐量； Ceph 也允许把日志和对象数据存储在相同驱动器上，但这会增加记录写日志并回应客户端的延时，因为 Ceph 必须先写入日志才会回应确认了写动作。 btrfs(暂时未稳定到工厂环境应用版本) 文件系统能同时写入日志数据和对象数据， xfs 和 ext4 却不能

Ceph 最佳实践指示，你应该分别在单独的硬盘运行操作系统、 OSD 数据和 OSD 日志

Important 我们建议发掘 SSD 的用法来提升性能。然而在大量投入 SSD 前，我们强烈建议核实 SSD 的性能指标，并在测试环境下衡量性能
正因为 SSD 没有移动机械部件，所以它很适合 Ceph 里不需要太多存储空间的地方。相对廉价的 SSD 很诱人，慎用！可接受的 IOPS 指标对选择用于 Ceph 的 SSD 还不够，用于日志和 SSD 时还有几个重要考量：

写密集语义： 记日志涉及写密集语义，所以你要确保选用的 SSD 写入性能和硬盘相当或好于硬盘。廉价 SSD 可能在加速访问的同时引入写延时，有时候高性能硬盘的写入速度可以和便宜 SSD 相媲美。
顺序写入： 在一个 SSD 上为多个 OSD 存储多个日志时也必须考虑 SSD 的顺序写入极限，因为它们要同时处理多个 OSD 日志的写入请求。
分区对齐： 采用了 SSD 的一个常见问题是人们喜欢分区，却常常忽略了分区对齐，这会导致 SSD 的数据传输速率慢很多，所以请确保分区对齐了。
SSD 用于对象存储太昂贵了，但是把 OSD 的日志存到 SSD 、把对象数据存储到独立的硬盘可以明显提升性能。 osd journal 选项的默认值是 /var/lib/ceph/osd/$cluster-$id/journal ，你可以把它挂载到一个 SSD 或 SSD 分区，这样它就不再是和对象数据一样存储在同一个硬盘上的文件了。

Tip 如果在只有一块硬盘的机器上运行 OSD ，要把数据和操作系统分别放到不同分区；一般来说，我们推荐操作系统和数据分别使用不同的硬盘。


设置linux最大运行线程数
下列这行加入 /etc/sysctl.conf 

kernel.pid_max = 4194303

## 各个节点环境准备

### 各個節點时间同步

apt-get install ntp -y
ntpdate ntp2.aliyun.com
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

### 更新ceph源

wget -q -O- 'http://mirrors.163.com/ceph/keys/release.asc' | sudo apt-key add -
echo deb http://mirrors.163.com/ceph/debian-nautilus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
echo deb http://mirrors.163.com/ceph/debian-octopus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
apt-get update
设置hostname
hostnamectl set-hostname node0
hostnamectl set-hostname node1
安装openssh-server
apt-get install -y openssh-server
安装ceph相关包
apt-get install -y ceph ceph-osd ceph-mds ceph-mon radosgw
查看集羣詳細健康狀態
ceph health detail
查看PG状态

ceph pg stat

## ceph deploy节点环境准备

#### 卸载

从集群主机卸载 Ceph 软件包

```
ceph-deploy uninstall {hostname [hostname] ...}
```

在 Debian 或 Ubuntu 系统上你也可以

```
ceph-deploy purge {hostname [hostname] ...}
```

此工具会从指定主机上卸载 `ceph` 软件包，另外 `purge` 会删除配置文件。

#### 安装ceph-deploy

apt-get install python3 python3-pip -y
mkdir /home/cephadmin
git clone https://github.com/ceph/ceph-deploy.git
cd ceph-deploy
pip3 install setuptools
python3 setup.py install


设置deploy节点和其他节点免密
sed -i '/PermitRootLogin/d' /etc/ssh/sshd_config
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
service sshd reload
ssh-keygen
ssh-copy-id -o StrictHostKeyChecking=no root@host-192-168-1-117
ssh-copy-id -o StrictHostKeyChecking=no root@host-192-168-1-119
vi /etc/hosts
192.168.1.117 host-192-168-1-117
192.168.1.119 host-192-168-1-119

部署集羣（admin節點）
首先创建文件夹，以后生成的配置文件默认保存在此
mkdir /etc/ceph 
cd /etc/ceph
创建一个新的集群
ceph-deploy new ceph1
修改配置文件
public_network = 192.168.51.0/24
给所有的节点安装 ceph
ceph-deploy install ceph1 ceph2 ceph3
各個節點安裝相關組件
apt-get install ceph ceph-osd ceph-mds ceph-mon radosgw
部署 MON 监控节点，在当前部署节点初始化
ceph-deploy mon create-initial
或直接部署到指定節點
ceph-deploy mon create ceph1
安裝ceph-mgr
apt-get install ceph-mgr
配置 mgr 服务
ceph-deploy mgr create ceph1

service ceph-mgr@ceph1 start

LVM分区锁定解决办法
lvscan
lvremove

创建osd节点前格式化磁盘
格式化osd节点对应磁盘设备
ceph-deploy disk zap node /dev/sdc
创建一个OSD节点
ceph-deploy osd create --data /dev/sdc node

重启ceph mon
systemctl restart ceph-mon.target
同步ceph节点配置
ceph-deploy --overwrite-conf config push node
删除ceph osd pool
ceph osd pool rm poolname poolname --yes-i-really-really-mean-it
指定存储池创建块设备
rbd create foo-3 --size=1024 --pool rbd2

查看存儲池 IO
ceph osd pool stats
总体及各存储池使用量
ceph df detail
開啓某個osd
systemctl start ceph-osd@x
停止某個osd

systemctl stop ceph-osd@x

## PG 操作

查看PG状态

ceph pg stat

查看pg组的映射信息

ceph pg dump

查看pg中stuck的状态 

ceph pg dump_stuck unclean
ceph pg dump_stuck inactive
ceph pg dump_stuck stale

获取 pg_num / pgp_num

ceph osd pool get mytestpool pg_num
ceph osd pool get mytestpool pgp_num

设置 pg_num

ceph osd pool set mytestpool pg_num 512
ceph osd pool set mytestpool pgp_num 512

恢复一个丢失的pg

ceph pg {pg-id} mark_unfound_lost revert

修复 pg 数据 

ceph pg crush repair {pg_id}
ceph pg repair {pg_id}

显示非正常状态的pg 

ceph pg dump_stuck inactive|unclean|stale

## 配置緩存池

列出当前集群中所有启用的 osd crush class
ceph osd crush class ls
将所有的 ssd 的 osd 从 hdd class 中删除
for i in 1 2; 
do 
	ceph osd crush rm-device-class osd.$i;
done
查看osd布局
ceph osd tree 
将刚刚删除的 osd 添加到 ssd class
for i in 1 2; 
do 
	ceph osd crush set-device-class ssd osd.$i;
done 
创建基于 ssd 的 class rule
创建一个 class rule，取名为 ssd_rule，使用 ssd 的 osd：
ceph osd crush rule create-replicated ssd_rule default host ssd
查看集群rule
ceph osd crush rule list
创建一个常规存储池 rbd
ceph osd pool create rbd 64 64
创建一个缓存池
ceph osd pool create cache 64 64 ssd_rule
設置儲存池rule
ceph osd pool set cache crush_rule ssd_rule
查看儲存池rule
ceph osd pool get cache crush_rule
存储池迁移到 ssd osd
ceph osd pool get cache crush_rule

## 设置缓存层

WRITEBACK 缓存池配置：

将 cache pool 放置到 data pool 前端

ceph osd tier add data cache

设置缓存模式为 writeback

ceph osd tier cache-mode cache writeback

将所有客户端请求从标准池引导至缓存池

ceph osd tier set-overlay data cache

READ-ONLY 缓存池配置：

将 cache pool 放置到 data pool 前端

ceph osd tier add data cache

设置缓存模式为 readonly

ceph osd tier cache-mode cache readonly --yes-i-really-mean-it
查到 rbd pool 和 cache pool 的详细信息
ceph osd dump |egrep 'data|cache'

对缓存池做一些基本的配置：
ceph osd pool set cache hit_set_type bloom
ceph osd pool set cache hit_set_count 1
ceph osd pool set cache hit_set_fpp 0.15
ceph osd pool set cache hit_set_period 3600  
ceph osd pool set cache target_max_bytes 1073741824 
ceph osd pool set cache target_max_objects 1000000
ceph osd pool set cache cache_min_flush_age 600
ceph osd pool set cache cache_min_evict_age 600
ceph osd pool set cache cache_target_dirty_ratio 0.4 
ceph osd pool set cache cache_target_full_ratio 0.8
ceph osd pool set cache min_read_recency_for_promote 1
ceph osd pool set cache min_write_recency_for_promote 1

删除writeback缓存池：
由于回写缓存可能具有修改的数据，所以必须采取措施以确保在禁用和删除缓存前，不丢失缓存中对象的最近的任何更改。

(1). 将缓存模式更改为转发，以便新的和修改的对象刷新至后端存储池：

ceph osd tier cache-mode cache forward --yes-i-really-mean-it
(2). 查看缓存池以确保所有的对象都被刷新（这可能需要点时间）：

rados -p cache ls 
(3). 如果缓存池中仍然有对象，也可以手动刷新：

rados -p cache cache-flush-evict-all
(4). 删除覆盖层，以使客户端不再将流量引导至缓存：

ceph osd tier remove-overlay data
(5). 解除存储池与缓存池的绑定：

ceph osd tier remove data cache

 缓存池的相关参数配置
(1). 命中集合过滤器，默认为 Bloom 过滤器，这种一种非常高效的过滤器（看官方文档的意思，好像目前只支持这一种filter）：

ceph osd pool set cache hit_set_type bloom
ceph osd pool set cache hit_set_count 1

设置 Bloom 过滤器的误报率

ceph osd pool set cache hit_set_fpp 0.15

设置缓存有效期,单位：秒

ceph osd pool set cache hit_set_period 3600   # 1 hour
(2). 设置当缓存池中的数据达到多少个字节或者多少个对象时，缓存分层代理就开始从缓存池刷新对象至后端存储池并驱逐：

当缓存池中的数据量达到1TB时开始刷盘并驱逐

ceph osd pool set cache target_max_bytes 1099511627776

当缓存池中的对象个数达到100万时开始刷盘并驱逐

ceph osd pool set cache target_max_objects 10000000
(3). 定义缓存层将对象刷至存储层或者驱逐的时间：

ceph osd pool set cache cache_min_flush_age 600
ceph osd pool set cache cache_min_evict_age 600 
(4). 定义当缓存池中的脏对象（被修改过的对象）占比达到多少(百分比)时，缓存分层代理开始将object从缓存层刷至存储层：

ceph osd pool set cache cache_target_dirty_ratio 0.4
(5). 当缓存池的饱和度达到指定的值，缓存分层代理将驱逐对象以维护可用容量，此时会将未修改的（干净的）对象刷盘：

ceph osd pool set cache cache_target_full_ratio 0.8
(6). 设置在处理读写操作时候，检查多少个 HitSet，检查结果将用于决定是否异步地提升对象（即把对象从冷数据升级为热数据，放入快取池）。它的取值应该在 0 和 hit_set_count 之间， 如果设置为 0 ，则所有的对象在读取或者写入后，将会立即提升对象；如果设置为 1 ，就只检查当前 HitSet ，如果此对象在当前 HitSet 里就提升它，否则就不提升。 设置为其它值时，就要挨个检查此数量的历史 HitSet ，如果此对象出现在 min_read_recency_for_promote 个 HitSet 里的任意一个，那就提升它。

ceph osd pool set cache min_read_recency_for_promote 1

ceph osd pool set cache min_write_recency_for_promote 1

## 开启存储池 pg_num 自动调整

// 启用自动调整模块
ceph mgr module enable pg_autoscaler
// 为已经存在的存储池开启自动调整
ceph osd pool ls | xargs -I {} ceph osd pool set {} pg_autoscale_mode on
// 为后续新创建的存储池默认开启
ceph config set global osd_pool_default_pg_autoscale_mode on
// 查看自动增加的 pg 数量

ceph osd pool autoscale-status

## 删除OSD

```bash
# 1. down 掉 OSD
ceph osd down osd.0
# 2. 踢出集群
ceph osd out osd.0
# 3. 移除 OSD 
ceph osd rm osd.0
# 4. 删除授权
ceph auth rm osd.0
# 5. 删除 crush map 
ceph osd crush rm osd.0
```

## 删除 OSD 节点

参考先删后增节点时如何减少数据迁移：https://www.cnblogs.com/schangech/p/8036191.html
// 停止指定 OSD 进程
systemctl stop ceph-osd@15
// out 指定 OSD
ceph osd out 15
// crush remove 指定 OSD
ceph osd crush remove osd.15
// 删除 osd 对应的 auth
ceph auth del osd.15
// 删除 osd
ceph osd rm 15
// 按照上述步骤删除节点上所有 osd 后，crush remove 指定节点

ceph osd crush rm osd-host

## rbd image 使用

// 创建大小为 1G 的 image
rbd create rbd/myimage --size 1024
rbd map rbd/myimage
mkfs.xfs /dev/rbd0
mkdir /data
mount /dev/rbd0 /data
// 扩容
rbd resize --image=rbd/myimage --size 10G
xfs_growfs /data
// 卸载
umount /data
// 检查占用设备的进程
fuser -m -v /dev/rbd0
rbd unmap /dev/rbd0
rbd rm rbd/myimage
// rbd image 转换 format，也可用于 image 复制
rbd export rbd/myrbd - | rbd import --image-format 2 - rbd/myrbd_v2
// rbd bench
rados bench -p rbd 20 -b 4K write -t 1 --no-cleanup
rbd create --size 4G test

rbd bench-write test

## 删除存储池

$ ceph tell mon.\* injectargs '--mon-allow-pool-delete=true'

The following will delete the pool

$ ceph osd pool delete <pool-name> <pool-name> --yes-i-really-really-mean-it

$ ceph tell mon.\* injectargs '--mon-allow-pool-delete=false'

## 挂载 cephfs 到本地

用户态挂载
yum install ceph-fuse -y
mkdir -p /mnt/cephfs
ceph-fuse -n client.admin --key AQBvN8lbCuTBFhAAJPMWYwu+Jho8B1QGt80jAA== --host 10.23.229.102,10.23.109.25 /mnt/cephfs
内核态挂载
mount -t ceph 192.168.0.1:6789,192.168.0.2:6789:/ /mnt/cephfs -o name=admin,secret=AQATSKdNGBnwLhAAnNDKnH65FmVKpXZJVasUeQ==
写入到 fstab 中，开机自动挂载

192.168.180.125:6789,192.168.180.115:6789:/ /mnt/cephfs ceph name=admin,secret=AQAoDAZdss8dEhAA1IQSOpkYbJrUN8vTceYKMw==,_netdev,noatime     0 0

## CentOS 安装 ceph-common

rpm -Uvh https://download.ceph.com/rpm-nautilus/el7/noarch/ceph-release-1-1.el7.noarch.rpm
// 或使用镜像源
rpm -Uvh https://mirrors.tuna.tsinghua.edu.cn/ceph/rpm-nautilus/el7/noarch/ceph-release-1-1.el7.noarch.rpm
sed -i 's+download.ceph.com+mirrors.tuna.tsinghua.edu.cn/ceph+' /etc/yum.repos.d/ceph.repo
yum -y install epel-release

yum -y install ceph-common

# 查看使用 ceph-volume 创建的 osd 信息

ceph-volume 使用逻辑卷创建 osd，ceph-disk 使用物理盘创建 osd，物理盘创建的 osd 与 盘符对应关系往往一目了然，逻辑卷创建的 osd 与盘符的对应关系需要执行以下命令查询：

ceph-volume inventory /dev/sda

## /var/lib/ceph/osd/ceph-x 使用内存盘

使用 bluestore 的 OSD，所有需要持久化的数据均存储在 LVM metadata 中，所以 /var/lib/ceph/osd/ceph-x 使用 tmpfs 是预期行为， OSD 启动时会从 metadata 中取出相关数据填充到 tmpfs 文件中。参见：http://lists.ceph.com/pipermail/ceph-users-ceph.com/2019-February/032797.html

## OSD 过度使用内存

在使用 Bluestore 时，bluestore_cache_autotune 默认已经启用，Bluestore 会将 OSD 堆内存使用量保持在指定的大小之下，通过配置选项 osd_memory_target 来控制，默认为 4G。对于内存较少但 OSD 节点较多的情况，仍然会可能造成内存几乎全部被 OSD 所用，最终致使宿主机死机。可以通过两种方式来缓解这种情况，一种是在启用自动配置时调小 osd_memory_target 值，例如：
[osd]
osd memory target = 2147483648
另一种是禁用自动配置并手动指定缓存大小：
[osd]
bluestore_cache_autotune = False
bluestore_min_alloc_size_ssd = 32768
bluestore_min_alloc_size_hdd = 32768
bluestore_min_alloc_size = 32768
bluestore_cache_kv_max = 6442450944
bluestore_cache_kv_ratio = 0.990000
bluestore_cache_meta_ratio = 0.010000
bluestore_cache_size = 12884901888
bluestore_cache_size_hdd = 12884901888

bluestore_cache_size_ssd = 12884901888

## ceph dashboard 303 状态码

需要代理网关的后端服务设置为处于 active 状态的 mgr 节点，参考：https://docs.ceph.com/docs/master/mgr/dashboard/#proxy-configuration

## pools have many more objects per pg than average

反应的问题是各个存储池 pg 数据量不均衡，可参考：https://www.dazhuanlan.com/2019/08/23/5d5f27fe6de04/，https://blog.csdn.net/ygtlovezf/article/details/60778091
临时解决，关闭不均衡告警，参考：https://github.com/rook/rook/issues/4739

ceph config set mgr mon_pg_warn_max_object_skew 0

## rgw 多个存储池的数据分布情况

参考：https://docs.ceph.com/docs/master/radosgw/layout/
如果需要快速清除所有 rgw 数据，可手动删除并重建 default.rgw.meta , default.rgw.buckets.index, default.rgw.buckets.data 存储池，需要执行 application enable 并重建用户和存储桶。
ceph osd pool application enable default.rgw.buckets.data rgw
ceph osd pool ls detail
radosgw-admin -n client.admin user create --uid=test --access-key=test --secret-key=test --display-name=test
设置日志等级
参考：https://access.redhat.com/documentation/en-us/red_hat_ceph_storage/3/html/troubleshooting_guide/configuring-logging
设置 osd 日志等级时，除了 debug_osd 选项，还有一些其它选项也要跟随调整：
debug_ms = 5
debug_osd = 20
debug_filestore = 20
debug_journal = 20
导出 Cephfs 为 NFS

参考：https://documentation.suse.com/ses/6/html/ses-all/cha-ceph-nfsganesha.html