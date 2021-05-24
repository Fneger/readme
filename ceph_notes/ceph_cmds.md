# Ceph常用命令

## ceph的pg,osd和pool之间的关系查找

使用ceph时，经常碰到某个pg有问题，但是这个pg属于哪个存储池呢，到处翻命令，在此记录下常用的几个命令，用于查找pg os和pool之间的映射关系。

1. 通过pg查找所属的pool

ceph pg dump |grep "^{poolid}\."  #poolid通过ceph osd pool ls detail 可查看到
2. 通过pg查找pg

ceph pg ls-by-pool {poolname} 
或者
ceph pg ls {poolid}
3. 通过pg查看其所在的osd

ceph pg map {pgid}

[root@node1 ~]# ceph pg map 1.0
osdmap e61 pg 1.0 (1.0) -> up [8,0] acting [8,0]
4. 通过osd查看pg

ceph pg ls-by-osd {osd.id}    #osd.id可以通过ceph osd tree查看

## 集群操作

### 启动集群

```bash
# 启动 mon 服务
sudo service ceph-mon@ceph1 start
# 启动 mgr 服务 
sudo service ceph-mgr@ceph1 start
# 启动指定的 OSD 服务
sudo service ceph-osd@0 start 
# 启动所有的 OSD 服务
sudo service ceph-osd@* start
# 启动 MDS 服务
sudo service ceph-mds@ceph1 start
```

### 查看 ceph 的实时运行状态

```bash
ceph -w
  cluster:
    id:     0862c251-2970-4329-b171-53a77d52b2d4
    health: HEALTH_OK
 
  services:
    mon: 1 daemons, quorum ceph1
    mgr: ceph1(active)
    osd: 6 osds: 6 up, 6 in
 
  data:
    pools:   2 pools, 128 pgs
    objects: 5 objects, 198B
    usage:   6.11GiB used, 53.3GiB / 59.4GiB avail
    pgs:     128 active+clean
```

### 查看ceph存储空间

```bash
ceph df
GLOBAL:
    SIZE        AVAIL       RAW USED     %RAW USED 
    59.4GiB     53.3GiB      6.11GiB         10.29 
POOLS:
    NAME       ID     USED     %USED     MAX AVAIL     OBJECTS 
    rbd        1      198B         0       25.2GiB           5 
    ecpool     2        0B         0       33.6GiB           0 
```

### 卸载某个节点所有的 ceph 数据包

```bash
ceph-deploy purge node1 # 删除所有软件和数据
ceph-deploy purgedata node1 # 只删除数据
```

### 为ceph创建一个 admin 用户并为 admin 用户创建一个密钥，把密钥保存到 /etc/ceph 目录下

```bash
ceph auth get-or-create client.admin mds 'allow *' osd 'allow *' mon 'allow *' mgr 'allow *' \
-o /etc/ceph/ceph.client.admin.keyring
```

### 为 osd.0 创建一个用户并创建一个key

```bash
ceph auth get-or-create osd.0 mon 'allow profile osd' osd 'allow *' mgr 'allow profile osd' \
		-o /var/lib/ceph/osd/ceph-0/keyring
```

### 为 mds.node1 创建一个用户并创建一个key

```bash
ceph auth get-or-create mds.ceph1 mon 'allow profile mds' osd 'allow rwx' mds 'allow *' \
		 -o /var/lib/ceph/mds/ceph-node1/keyring
```

### 查看 ceph 集群中的认证用户及相关的 key

```bash
ceph auth list
```

### 查看集群的详细配置

```bash
ceph daemon mon.ceph1 config show | more
```

### 查看集群健康状态细节

```bash
ceph health detail
HEALTH_OK # 如果有故障或者警告的话，这里会输出很多。
```

## MON 操作

### 查看 MON 的状态信息

```bash
ceph mon stat
e1: 1 mons at {ceph1=172.31.5.182:6789/0}, election epoch 57, leader 0 ceph1, quorum 0 ceph1
```

### 查看 MON 的选举状态

```bash
ceph quorum_status

{"election_epoch":57,"quorum":[0],"quorum_names":["ceph1"],"quorum_leader_name":"ceph1","monmap":{"epoch":1,"fsid":"0862c251-2970-4329-b171-53a77d52b2d4","modified":"2020-05-07 02:16:50.749480","created":"2020-05-07 02:16:50.749480","features":{"persistent":["kraken","luminous"],"optional":[]},"mons":[{"rank":0,"name":"ceph1","addr":"172.31.5.182:6789/0","public_addr":"172.31.5.182:6789/0"}]}}
```

### 查看 MON 的映射信息

```bash
ceph mon dump

dumped monmap epoch 1
epoch 1
fsid 0862c251-2970-4329-b171-53a77d52b2d4
last_changed 2020-05-07 02:16:50.749480
created 2020-05-07 02:16:50.749480
0: 172.31.5.182:6789/0 mon.ceph1
```

### 删除一个 MON 节点

```bash
ceph mon remove ceph1
# 如果是部署节点，也可以使用 ceph-deploy 删除 
ceph-deploy mon remove ceph1
```

### 获得一个正在运行的 mon map，并保存在指定的文件中

```bash
ceph mon getmap -o mon.txt

got monmap epoch 1
```

### 查看上面获得的 map

```bash
monmaptool --print mon.txt

monmaptool: monmap file mon.txt
epoch 1
fsid 0862c251-2970-4329-b171-53a77d52b2d4
last_changed 2020-05-07 02:16:50.749480
created 2020-05-07 02:16:50.749480
0: 172.31.5.182:6789/0 mon.ceph1
```

这其实跟 `ceph mon dump` 输出的结果是一样的

### 把上面的mon map注入新加入的节点

```bash
ceph-mon -i ceph1 --inject-monmap mon.txt
```

### 查看 MON 的 `amin socket`

```bash
ceph-conf --name mon.ceph1 --show-config-value admin_socket

/var/run/ceph/ceph-mon.ceph1.asok
```

### 查看 MON 的详细状态

```bash
ceph daemon mon.ceph1 mon_status
```



## OSD 操作

### 查看 ceph osd 运行状态

```bash
ceph osd stat
6 osds: 6 up, 6 in
```

### 查看 osd 映射信息

```bash
ceph osd dump
```

### 查看 osd 的目录树

```bash
ceph osd tree
```

### 删除 OSD

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

###  设置 OSD 最大个数

```bash
# 获取 OSD 最大个数
ceph osd getmaxosd
# 设置 OSD 最大个数
ceph osd setmaxosd 10 
```

### 设置OSD crush 的权重

```bash
ceph osd crush set 3 3.0 host=ceph2

set item id 3 name 'osd.3' weight 3 at location {host=ceph2} to crush map
```

### 查看集群中某个 osd 的配置参数

```bash
ceph --admin-daemon /var/run/ceph/ceph-osd.0.asok config show | less
# 另一种方式
ceph -n osd.0 --show-config |grep objectstore
```

### 动态设置集群中 osd 的参数配置

```bash
# 设置单个 osd
ceph tell osd.0 injectargs "--osd_recovery_op_priority 63"
# 设置所有的 osd
ceph tell osd.* injectargs "--osd_recovery_op_priority 63"
```



## MDS 操作

### 查看 MDS 状态

```bash
ceph mds stat
```

### 查看 MDS 的映射信息

```bash
ceph mds dump
```

### 删除 MDS 节点

```bash
# 删除第一个 MDS 节点
ceph mds rm 0

mds gid 0 dne
```



## 存储池操作

[Ceph Pool](https://durantthorvalds.top/2020/12/14/ceph%20pool/)

### 查看ceph集群中的pool数量

```bash
ceph osd lspools
```

### 创建存储池

```bash
ceph osd pool create testpool 128 128 # 128 指 PG 数量
```

### 为一个 ceph pool 配置配额

```bash
ceph osd pool set-quota testpool max_objects 10000
```

### 关连池到应用程序

```
ceph osd pool application enable {pool-name} {application-name}
```

注意：

CephFS使用应用程序名称`cephfs`，RBD使用应用程序名称`rbd`，而RGW使用应用程序名称`rgw`

### 设置储存池配额

您可以将池配额设置为每个池的最大字节数和/或最大对象数。

```
ceph osd pool set-quota {pool-name} [max_objects {obj-count}] [max_bytes {bytes}]
```

例如:

```
ceph osd pool set-quota data max_objects 10000
```

要删除配额，请将其值设置为`0`。

### 重命名池

要重命名池，请执行：

```
ceph osd pool rename {current-pool-name} {new-pool-name}
```

如果您重命名池，并且您具有针对经过身份验证的用户的每个池功能，则必须使用新的池名称来更新用户的功能（即上限）。

## 显示池统计信息

要显示池的利用率统计信息，请执行：

```
rados df
```

此外，要获取特定池或全部池的I / O信息，请执行以下操作：

```
ceph osd pool stats [{pool-name}]
```

### 制作池快照

要制作池的快照，请执行：

```
ceph osd pool mksnap {pool-name} {snap-name}
```

### 删除池的快照

要删除池的快照，请执行：

```
ceph osd pool rmsnap {pool-name} {snap-name}
```

### 设置池的值

要将值设置为池，请执行以下操作：

```
ceph osd pool set {pool-name} {key} {value}
```

您可以为以下键设置值：

```
compression_algorithm
```

- 描述
- 设置用于基础BlueStore的内联压缩算法。此设置将覆盖[全局设置](http://docs.ceph.com/docs/master/rados/configuration/bluestore-config-ref/#inline-compression)的`bluestore compression algorithm`。
- 类型
- 细绳
- 有效设定
- `lz4`, `snappy`, `zlib`, `zstd`

```
compression_mode
```

- 描述
- 设置基础BlueStore的内联压缩算法的策略。此设置将覆盖[全局设置](http://docs.ceph.com/docs/master/rados/configuration/bluestore-config-ref/#inline-compression)的`bluestore compression mode`。
- 类型
- 细绳
- 有效设定
- `none`, `passive`, `aggressive`, `force`

```
compression_min_blob_size
```

- 描述
- 小于此的块永远不会被压缩。此设置将覆盖[全局设置](http://docs.ceph.com/docs/master/rados/configuration/bluestore-config-ref/#inline-compression)的`bluestore compression min blob *`。
- 类型
- 无符号整数

```
compression_max_blob_size
```

- 描述
- 大于此的块`compression_max_blob_size`在压缩之前会分解为较小的斑点大小。
- 类型
- 无符号整数

```
size
```

- 描述
- 设置池中[对象的副本数。](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#set-the-number-of-object-replicas)有关更多详细信息，请参见[设置对象副本数。](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#set-the-number-of-object-replicas)仅[复制](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#set-the-number-of-object-replicas)池。
- 类型
- 整数

```
min_size
```

- 描述
- 设置I / O所需的最小副本[数。](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#set-the-number-of-object-replicas)有关更多详细信息，请参见[设置对象副本数。](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#set-the-number-of-object-replicas)仅[复制](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#set-the-number-of-object-replicas)池。
- 类型
- 整数
- 版本
- `0.54` 以上

```
pg_num
```

- 描述
- 计算数据放置时要使用的放置组的有效数量。
- 类型
- 整数
- 有效范围
- 优于`pg_num`当前值。

```
pgp_num
```

- 描述
- 计算数据放置时要使用的放置组的有效放置数量。
- 类型
- 整数
- 有效范围
- 等于或小于`pg_num`。

```
crush_rule
```

- 描述
- 用于在集群中映射对象放置的规则。
- 类型
- 细绳

```
allow_ec_overwrites
```

- 描述
- 是否写入擦除代码池可以更新对象的一部分，因此cephfs和rbd可以使用它。有关更多详细信息，请参见[带覆盖的擦除编码](https://www.bookstack.cn/read/ceph-en/e84aa3dad45ac7b4.md#erasure-coding-with-overwrites)。
- 类型
- 布尔型
- 版本
- `12.2.0` 以上

```
hashpspool
```

- 描述
- 在给定的池上设置/取消设置HASHPSPOOL标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志

```
nodelete
```

- 描述
- 在给定的池上设置/取消设置NODELETE标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志
- 版本
- 版本 `FIXME`

```
nopgchange
```

- 描述
- 在给定的池上设置/取消设置NOPGCHANGE标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志
- 版本
- 版本 `FIXME`

```
nosizechange
```

- 描述
- 在给定的池上设置/取消设置NOSIZECHANGE标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志
- 版本
- 版本 `FIXME`

```
write_fadvise_dontneed
```

- 描述
- 在给定的池上设置/取消设置WRITE_FADVISE_DONTNEED标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志

```
noscrub
```

- 描述
- 在给定的池上设置/取消设置NOSCRUB标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志

```
nodeep-scrub
```

- 描述
- 在给定的池上设置/取消设置NODEEP_SCRUB标志。
- 类型
- 整数
- 有效范围
- 1个设置标志，0个未设置标志

```
hit_set_type
```

- 描述
- 启用缓存池的命中集跟踪。有关其他信息，请参阅[Bloom Filter](https://en.wikipedia.org/wiki/Bloom_filter)。
- 类型
- 细绳
- 有效设定
- `bloom`, `explicit_hash`, `explicit_object`
- 默认
- `bloom`。其他值用于测试。

```
hit_set_count
```

- 描述
- 要为高速缓存池存储的命中集的数量。数字越大，`ceph-osd`守护程序消耗的RAM越多。
- 类型
- 整数
- 有效范围
- `1`。代理尚未处理> 1。

```
hit_set_period
```

- 描述
- 高速缓存池的命中设置周期的持续时间（以秒为单位）。数字越大，`ceph-osd`守护程序消耗的RAM越多。
- 类型
- 整数
- 例子
- `3600` 1小时

```
hit_set_fpp
```

- 描述
- `bloom`匹配集类型的误报概率。有关其他信息，请参见[Bloom Filter](https://en.wikipedia.org/wiki/Bloom_filter)。
- 类型
- 双倍的
- 有效范围
- 0.0 - 1.0
- 默认
- `0.05`

```
cache_target_dirty_ratio
```

- 描述
- 在缓存分层代理将其刷新到后备存储池之前，包含修改后的（脏）对象的缓存池的百分比。
- 类型
- 双倍的
- 默认
- `.4`

```
cache_target_dirty_high_ratio
```

- 描述
- 缓存分层代理将以更快的速度将它们包含到后备存储池之前，包含修改后的（脏）对象的缓存池所占的百分比。
- 类型
- 双倍的
- 默认
- `.6`

```
cache_target_full_ratio
```

- 描述
- 在高速缓存分层代理将其从高速缓存池中逐出之前，包含未修改（干净）对象的高速缓存池的百分比。
- 类型
- 双倍的
- 默认
- `.8`

```
target_max_bytes
```

- 描述
- 当`max_bytes`触发阈值时，Ceph将开始刷新或逐出对象。
- 类型
- 整数
- 例子
- `1000000000000` ＃1 TB

```
target_max_objects
```

- 描述
- 当`max_objects`触发阈值时，Ceph将开始刷新或逐出对象。
- 类型
- 整数
- 例子
- `1000000` ＃1M个对象

```
hit_set_grade_decay_rate
```

- 描述
- 两个连续命中点之间的温度衰减率
- 类型
- 整数
- 有效范围
- 0 - 100
- 默认
- `20`

```
hit_set_search_last_n
```

- 描述
- 计算hit_sets中最多N个出现以进行温度计算
- 类型
- 整数
- 有效范围
- 0-hit_set_count
- 默认
- `1`

```
cache_min_flush_age
```

- 描述
- 缓存分层代理将对象从缓存池刷新到存储池之前的时间（以秒为单位）。
- 类型
- 整数
- 例子
- `600` 10分钟

```
cache_min_evict_age
```

- 描述
- 缓存分层代理从缓存池中退出对象之前的时间（以秒为单位）。
- 类型
- 整数
- 例子
- `1800` 30分钟

```
fast_read
```

- 描述
- 在擦除编码池上，如果打开此标志，则读取请求将使issue子读取所有分片，并等待直到接收到足够的分片来解码以服务于客户端。对于jerasure和isaerasure插件，一旦返回前K个答复，就会使用从这些答复中解码的数据立即满足客户的请求。这有助于权衡一些资源以获得更好的性能。当前，仅擦除编码池支持此标志。
- 类型
- 布尔型
- 默认值
- `0`

```
scrub_min_interval
```

- 描述
- 负载低时清理池的最小时间间隔（以秒为单位）。如果为0，则使用config中的值osd_scrub_min_interval。
- 类型
- 双倍的
- 默认
- `0`

```
scrub_max_interval
```

- 描述
- 池清理的最大时间间隔（以秒为单位），与群集负载无关。如果为0，则使用config中的值osd_scrub_max_interval。
- 类型
- 双倍的
- 默认
- `0`

```
deep_scrub_interval
```

- 描述
- 池“深度”清理的时间间隔（以秒为单位）。如果为0，则使用config中的osd_deep_scrub_interval值。
- 类型
- 双倍的
- 默认
- `0`

```
recovery_priority
```

- 描述
- 设置值后，它将增加或减少计算的保留优先级。此值必须在-10到10的范围内。对不太重要的池使用负优先级，因此它们的优先级低于任何新池。
- 类型
- 整数
- 默认
- `0`

```
recovery_op_priority
```

- 描述
- 指定该池的恢复操作优先级，而不是`osd_recovery_op_priority`。
- 类型
- 整数
- 默认
- `0`



### 设置对象副本数

要设置复制池上对象副本的数量，请执行以下操作：

```
ceph osd pool set {poolname} size {num-replicas}
```

重要的

在`{num-replicas}`包括itself.如果你想要的对象和对象的总ofthree实例对象的两个副本，指定对象`3`。

例如：

```
ceph osd pool set data size 3
```

您可以为每个池执行此命令。**注意：**一个对象可能在降级模式下接受的I / O数少于`pool size`副本数。要为I / O设置最小数量的必需副本，应使用该设置，`min_size`例如：

```
ceph osd池设置数据min_size 2
```

这样可以确保数据池中的任何对象都不会收到少于`min_size`副本的I / O。

### 获取对象副本数

要获取对象副本的数量，请执行以下操作：

```
ceph osd pool set data min_size 2
```

Ceph将列出池，并`replicated size`突出显示该属性。默认情况下，ceph创建一个对象的两个副本（总共三个副本，或大小为3）。

### 删除存储池1

首先要在 `ceph.conf` 文件中配置允许删除集群:

```bash
mon_allow_pool_delete = true
```

然后重启 `MON` 进程

```bash
sudo service ceph-mon@ceph1 restart
```

在删除存储池

```bash
ceph osd pool delete testpool testpool  --yes-i-really-really-mean-it
```

### 删除存储池2

$ ceph tell mon.\* injectargs '--mon-allow-pool-delete=true'

The following will delete the pool

$ ceph osd pool delete <pool-name> <pool-name> --yes-i-really-really-mean-it

$ ceph tell mon.\* injectargs '--mon-allow-pool-delete=false'

## PG 操作

```bash
# 查看PG状态
ceph pg stat
# 查看pg组的映射信息
ceph pg dump
# 查看pg中stuck的状态 
ceph pg dump_stuck unclean
ceph pg dump_stuck inactive
ceph pg dump_stuck stale

# 获取 pg_num / pgp_num
ceph osd pool get mytestpool pg_num
ceph osd pool get mytestpool pgp_num

# 设置 pg_num
ceph osd pool set mytestpool pg_num 512
ceph osd pool set mytestpool pgp_num 512

# 恢复一个丢失的pg
ceph pg {pg-id} mark_unfound_lost revert

# 修复 pg 数据 
ceph pg crush repair {pg_id}
ceph pg repair {pg_id}
# 显示非正常状态的pg 
ceph pg dump_stuck inactive|unclean|stale
```

## SSD缓存池

### 1.配置 crush class

如果你已经做好 OSD 磁盘分组了，请跳过这一步。

如果没有，那么接下来你可能会问，缓存池是创建在 SSD 磁盘上的，那我如何在指定的 OSD(ssd 磁盘)上去创建存储池呢？

这个问题问得好，首先我们得给磁盘，也就是 OSD 分组。

ceph 从 LUMINOUS 版本开始新增了个功能叫 `crush class`，又被称之为磁盘智能分组。因为这个功能就是根据磁盘类型自动进行属性关联，然后进行分类减少了很多的人为操作。 在这个功能之前，如果我们需要对 ssd 和 hdd 进行分组的时候，需要大量的修改 crushmap，然后绑定不同的存储池到不同的crush树上面，而这个功能让我们简化了这种逻辑。

ceph中的每个设备都可以选择一个class类型与之关联，通常有三种class类型：

- hdd
- ssd
- nvme

#### 1.1 启用 ssd class

默认情况下，我们所有的 `osd crush class` 类型都是 hdd。

你也可以使用下面的命令来列出当前集群中所有启用的 osd crush class

```
root@ceph1:~# ceph osd crush class ls
[
    "hdd"
]
```

现在我们的需求是：把一些 OSD（如 osd.1,osd.2） 移动到 ssd class 中去，很简单，分两步操作就好了。

(1). 将所有的 ssd 的 osd 从 hdd class 中删除

```
for i in 1 2; 
do 
	ceph osd crush rm-device-class osd.$i;
done
```

这个时候，如果我们再次使用 `ceph osd tree` 查看 osd 布局，会看到被我们指定的 osd 前面不再有 hdd 标识，事实上啥也没有了。

(2). 将刚刚删除的 osd 添加到 ssd class:

```
for i in 1 2; 
do 
	ceph osd crush set-device-class ssd osd.$i;
done 
```

此时，我们会发现 osd.1 osd.2 已经加入到 ssd class 了

然后我们再次查看 crush class，也多出了一个名为 ssd 的 class：

```
ceph osd crush class ls
[
    "hdd",
    "ssd"
]
```

#### 1.2 创建基于 ssd 的 class rule

创建一个 class rule，取名为 ssd_rule，使用 ssd 的 osd：

```bash
ceph osd crush rule create-replicated ssd_rule default host ssd
```

查看集群rule：

```bash
ceph osd crush rule list
replicated_rule
ssd_rule
```

### 2.配置缓存池

我们先创建一个常规存储池 `data`

```bash
ceph osd pool create data 64 64
```

#### 2.1 创建一个缓存池

我们在步骤 4 中已经创建了一个基于 ssd 的 crush_rule，我们创建一个存储池，使用该crush rule即可。

```bash
ceph osd pool create cache 64 64 ssd_rule
```

你也可以选择把一个已经创建好的存储池迁移到 ssd osd 上：

```bash
ceph osd pool get cache crush_rule
```

验证迁移是否成功：

```bash
root@ceph1:~# ceph osd pool get cache crush_rule
crush_rule: ssd_rule
```

#### 2.2 设置缓存层

WRITEBACK 缓存池配置：

```bash
# 将 cache pool 放置到 data pool 前端
ceph osd tier add data cache

# 设置缓存模式为 writeback
ceph osd tier cache-mode cache writeback

# 将所有客户端请求从标准池引导至缓存池
ceph osd tier set-overlay data cache
```

READ-ONLY 缓存池配置

```bash
# 将 cache pool 放置到 data pool 前端
ceph osd tier add data cache
# 设置缓存模式为 readonly
ceph osd tier cache-mode cache readonly
```

通过下面的命令可以查到 data pool 和 cache pool 的详细信息

```bash
root@ceph1:~# ceph osd dump |egrep 'data|cache'
pool 1 'data' replicated size 2 min_size 2 crush_rule 0 object_hash rjenkins pg_num 64 pgp_num 64 last_change 40 lfor 39/39 flags hashpspool tiers 2 read_tier 2 write_tier 2 stripe_width 0
pool 2 'cache' replicated size 2 min_size 2 crush_rule 1 object_hash rjenkins pg_num 64 pgp_num 64 last_change 42 lfor 39/39 flags hashpspool,incomplete_clones tier_of 1 cache_mode writeback stripe_width 0
```

对缓存池做一些基本的配置：

```bash
ceph osd pool set cache hit_set_type bloom
ceph osd pool set cache hit_set_count 1
ceph osd pool set cache hit_set_period 3600   # 1 hour
ceph osd pool set cache target_max_bytes 1000000000000  # 1 TB
ceph osd pool set cache target_max_objects 10000000
ceph osd pool set cache min_read_recency_for_promote 1
ceph osd pool set cache min_write_recency_for_promote 1
```

#### 2.3 删除writeback缓存池：

由于回写缓存可能具有修改的数据，所以必须采取措施以确保在禁用和删除缓存前，不丢失缓存中对象的最近的任何更改。

(1). 将缓存模式更改为转发，以便新的和修改的对象刷新至后端存储池：

```bash
ceph osd tier cache-mode cache forward --yes-i-really-mean-it
```

(2). 查看缓存池以确保所有的对象都被刷新（这可能需要点时间）：

```bash
rados -p cache ls 
```

(3). 如果缓存池中仍然有对象，也可以手动刷新：

```bash
rados -p cache cache-flush-evict-all
```

(4). 删除覆盖层，以使客户端不再将流量引导至缓存：

```bash
ceph osd tier remove-overlay data
```

(5). 解除存储池与缓存池的绑定：

```bash
ceph osd tier remove data cache
```

#### 2.4 缓存池的相关参数配置

(1). 命中集合过滤器，默认为 Bloom 过滤器，这种一种非常高效的过滤器（看官方文档的意思，好像目前只支持这一种filter）：

```bash
ceph osd pool set cache hit_set_type bloom
ceph osd pool set cache hit_set_count 1
# 设置 Bloom 过滤器的误报率
ceph osd pool set cache hit_set_fpp 0.15
# 设置缓存有效期,单位：秒
ceph osd pool set cache hit_set_period 3600   # 1 hour
```

(2). 设置当缓存池中的数据达到多少个字节或者多少个对象时，缓存分层代理就开始从缓存池刷新对象至后端存储池并驱逐：

```bash
# 当缓存池中的数据量达到1TB时开始刷盘并驱逐
ceph osd pool set cache target_max_bytes 1099511627776

# 当缓存池中的对象个数达到100万时开始刷盘并驱逐
ceph osd pool set cache target_max_objects 10000000
```

(3). 定义缓存层将对象刷至存储层或者驱逐的时间：

```bash
ceph osd pool set cache cache_min_flush_age 600
ceph osd pool set cache cache_min_evict_age 600 
```

(4). 定义当缓存池中的脏对象（被修改过的对象）占比达到多少(百分比)时，缓存分层代理开始将object从缓存层刷至存储层：

```bash
ceph osd pool set cache cache_target_dirty_ratio 0.4
```

(5). 当缓存池的饱和度达到指定的值，缓存分层代理将驱逐对象以维护可用容量，此时会将未修改的（干净的）对象刷盘：

```bash
ceph osd pool set cache cache_target_full_ratio 0.8
```

(6). 设置在处理读写操作时候，检查多少个 HitSet，检查结果将用于决定是否异步地提升对象（即把对象从冷数据升级为热数据，放入快取池）。它的取值应该在 0 和 hit_set_count 之间， 如果设置为 0 ，则所有的对象在读取或者写入后，将会立即提升对象；如果设置为 1 ，就只检查当前 HitSet ，如果此对象在当前 HitSet 里就提升它，否则就不提升。 设置为其它值时，就要挨个检查此数量的历史 HitSet ，如果此对象出现在 `min_read_recency_for_promote` 个 HitSet 里的任意一个，那就提升它。

```bash
ceph osd pool set cache min_read_recency_for_promote 1
ceph osd pool set cache min_write_recency_for_promote 1
```

## RBD块设备

### 基本块设备命令

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



### 创建一个块设备池

- 在管理节点上，使用该`ceph`工具[创建一个pool](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md#create-a-pool)。
- 在管理节点上，使用该`rbd`工具初始化池以供RBD使用：

```
rbd pool init <pool-name>
```

注意：块设备池为创建时，该`rbd`工具假定默认池名称为“ rbd”

### 创建一个块设备用户

除非指定，否则rbd命令将使用ID admin访问Ceph集群。 此ID允许对群集进行完全管理访问。 建议您尽可能使用限制更大的用户。

要[创建Ceph用户](https://www.bookstack.cn/read/ceph-en/dd0e02d97d027599.md#add-a-user)，请`ceph`指定`auth get-or-create`命令，用户名，监视器大小写和OSD大小写：

```
ceph auth get-or-create client.{ID} mon 'profile rbd' osd 'profile {profile name} [pool={pool-name}][, profile ...]' mgr 'profile rbd [pool={pool-name}]'
```

例如，要创建一个以对池`qemu`的读写访问权`vms`和对池的只读访问权命名的用户标识`images`，请执行以下操作：

```
ceph auth get-or-create client.qemu mon 'profile rbd' osd 'profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=images'
```

ceph auth get-or-create`命令的输出将是指定用户的密钥环，可以将其写入`/etc/ceph/ceph.client.{ID}.keyring

注意：使用`rbd`命令时，可以通过提供`—id {id}`可选参数来指定用户ID 

### 创建块设备镜像

您必须先在[Ceph Storage Cluster中](https://www.bookstack.cn/read/ceph-en/78fd72266ec11255.md#term-ceph-storage-cluster)为其创建映像，然后才能将块设备添加到节点。要创建块设备映像，请执行以下操作：

```
rbd create --size {megabytes} {pool-name}/{image-name}
```

例如，要创建一个名为1GB的映像`bar`，该映像将信息存储在名为的apool中`swimmingpool`，请执行以下操作：

```
rbd create --size 1024 swimmingpool/bar --image-feature layering
```

如果在创建映像时未指定池，则它将存储在默认池中`rbd`。例如，要创建一个`foo`存储在默认池中的名为1GB的映像`rbd`，请执行以下操作：

```
rbd create --size 1024 foo --image-feature layering
```

注意：

您必须先创建一个池，然后才能将其指定为源。有关详细信息，请参见[存储池](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md)。

### 列出块设备映像

要列出`rbd`池中的块设备，请执行以下操作（即，`rbd`是默认的池名称）：

```
rbd ls
```

要列出特定池中的块设备，请执行以下操作，但用`{poolname}`池的名称替换：

```
rbd ls { poolname }
```

例如：

```
rbd ls swimmingpool
```

要列出`rbd`池中的延迟删除块设备，请执行以下操作：

```
rbd trash ls
```

要列出特定池中的延迟删除块设备，请执行以下操作，但用`{poolname}`池名称替换：

```
rbd trash ls {poolname}
```

例如：

```
rbd trash ls swimmingpool
```

### 检索镜像信息

要从特定图像检索信息，请执行以下操作，但用`{image-name}`图像名称替换：

```
rbd info {image-name}
```

例如：

```
rbd info foo
```

要从池中的映像检索信息，请执行以下操作，但用`{image-name}`映像`{pool-name}`的名称替换并用池的名称替换：

```
rbd info {pool-name}/{image-name}
```

例如：

```
rbd info swimmingpool/bar
```

### 调整块设备映像的大小

[Ceph块设备](https://www.bookstack.cn/read/ceph-en/78fd72266ec11255.md#term-ceph-block-device)映像是精简配置的。在您开始将数据保存到它们之前，它们实际上并不使用任何物理存储。但是，它们确实具有您使用该`—size`选项设置的最大容量。如果要增加（或减少）Ceph块设备映像的最大大小，请执行以下操作：

```
rbd resize --size 2048 foo (to increase)
rbd resize --size 2048 foo --allow-shrink (to decrease)

xfs_growfs /mnt/rbd_test/
```

### 删除块设备映像

要删除块设备，请执行以下操作，但将其替换`{image-name}`为要删除的映像的名称：

```
rbd rm {image-name}
```

例如：

```
rbd rm foo
```

要从池中删除块设备，请执行以下操作，但将其替换`{image-name}`为要删除的映像名称，然后将其替换`{pool-name}`为池名称：

```
rbd rm {pool-name}/{image-name}
```

例如：

```
rbd rm swimmingpool/bar
```

要推迟从池中删除块设备，请执行以下操作，但`{image-name}`将其替换为要删除的映像的名称，然后将其替换`{pool-name}`为池的名称：

```
rbd trash mv {pool-name}/{image-name}
```

例如：

```
rbd trash mv swimmingpool/barrbd垃圾电视泳池/酒吧
```

要从池中删除延迟的块设备，请执行以下操作，但是`{image-id}`将其替换为要删除的映像的ID，并替换`{pool-name}`为池的名称：

```
rbd trash rm {pool-name}/{image-id}
```

例如：

```
rbd trash rm swimmingpool/2bf4474b0dc51
```

笔记

- 您可以将图像移动到垃圾箱中，即使它具有快照或克隆正在积极使用中，但也不能将其从垃圾箱中删除。
- 您可以使用*–expires-at*设置延迟时间（默认为`now`），如果延迟时间未到期，则除非使用*–force*，否则无法将其删除。

### 恢复块设备映像

要恢复rbd池中的延迟删除块设备，请执行以下操作，但替换`{image-id}`为映像的ID：

```
rbd trash restore {image-id}
```

例如：

```
rbd trash restore 2bf4474b0dc51
```

要还原特定池中的延迟删除块设备，请执行以下操作，但用`{image-id}`映像的ID替换并`{pool-name}`用池的名称替换：

```
rbd trash restore {pool-name}/{image-id}
```

例如：

```
rbd trash restore swimmingpool/2bf4474b0dc51
```

您还可以`—image`在还原图像时使用它来重命名图像。

例如：

```
rbd trash restore swimmingpool/2bf4474b0dc51 --image new-name
```

### 开机自动挂载

首先我们需要在部署节点上把客户端验证的 key 推送到客户端。

```
ceph-deploy admin ceph-client
# 如果部署节点没有 ceph-client 的验证信息，可以直接用 scp 拷贝
scp /etc/ceph/ceph.client.admin.keyring root@{client.ip}:/etc/ceph/
```

然后我们编辑客户端的 rbdmap 文件 `vim /etc/ceph/rbdmap`，添加一行自动 map 的配置：

```
rbd/{rbd_name}      id=admin,keyring=/etc/ceph/ceph.client.admin.keyring
```

`{rbd_name}` 是你需要自动 map 的 rbd 名称，比如你改成 `foo`，这样 Ceph 就会在开机的时候自动映射 `foo` 块设备。

接下来就简单了，我们可以像普通硬盘一样开机挂载了。编辑 `/etc/fstab`，添加一行自动挂载的配置

```
/dev/rbd/rbd/{rbd_name} /mnt/rbd ext4 defaults,noatime,_netdev 0 2
```

这里的 `{rbd_name}` 同样需要改成对应的 rbd 实际名称，**同时需要注意加上 `_netdev` 选项，表示是网络设备。**



## 用户管理

[官方参考](https://www.bookstack.cn/read/ceph-en/dd0e02d97d027599.md)

### 查看所有用户

```
ceph auth ls
```

您可以使用该`-o {filename}`选项`ceph auth ls`将输出保存到文件中

### 获取用户

要检索特定的用户，键和功能，请执行以下操作：

```
ceph auth get {TYPE.ID}
```

例如：

```
ceph auth get client.admin
```

您也可以将`-o {filename}`选项与一起使用，以`ceph auth get`将输出保存到文件中。开发人员还可以执行以下操作：

```
ceph auth export {TYPE.ID}
```

该`auth export`命令与相同`auth get`。

### 添加用户

添加用户会创建一个用户名（即`TYPE.ID`），一个秘密密钥以及您用来创建用户的命令中包含的所有功能。

用户的密钥使用户能够通过Ceph存储群集进行身份验证。用户的功能授权用户在Cephmonitors（`mon`），Ceph OSDs （`osd`）或Ceph Metadata Servers（`mds`）上进行读取，写入或执行。

有几种添加用户的方法：

- `ceph auth add`：此命令是添加用户的规范方法。它将创建用户，生成密钥并添加任何指定的功能。

- `ceph auth get-or-create`：此命令通常是创建用户的最方便的方法，因为它返回带有用户名（在方括号中）和密钥的密钥文件格式。如果用户已经存在，则此命令仅以密钥文件格式返回用户名和密钥。您可以使用该`-o {filename}`选项将输出保存到文件中。

- `ceph auth get-or-create-key`：此命令是创建用户并返回用户密钥（仅）的便捷方法。这对于仅需要密钥的客户端（例如libvirt）很有用。如果用户已经存在，则此命令仅返回密钥。您可以使用该`-o {filename}`选项将输出保存到文件中。

创建客户端用户时，您可能会创建没有功能的用户。没有能力的用户仅凭身份验证是没有用的，因为客户端无法从监视器检索群集映射。但是，如果您希望以后再推迟使用该`ceph auth caps`命令添加功能，则可以创建一个没有功能的用户。

典型的用户至少在Ceph监视器上具有读取功能，并且在Ceph OSD上具有读写功能。此外，用户的OSD权限通常仅限于访问特定池。

```
ceph auth add client.john mon 'allow r' osd 'allow rw pool=liverpool'

ceph auth get-or-create client.paul mon 'allow r' osd 'allow rw pool=liverpool'

ceph auth get-or-create client.george mon 'allow r' osd 'allow rw pool=liverpool' -o george.keyring

ceph auth get-or-create-key client.ringo mon 'allow r' osd 'allow rw pool=liverpool' -o ringo.key
```

注意：

如果您为用户提供OSD功能，但您不限制对特定池的访问，则该用户将有权访问群集中的所有池！

### 设置用户访问权限

该`ceph auth caps`命令允许您指定用户并更改用户的功能。设置新功能将覆盖当前功能。查看当前功能运行`ceph auth get USERTYPE.USERID`。要添加功能，还应该在使用表单时指定现有功能：

```
ceph auth caps USERTYPE.USERID {daemon} 'allow [r|w|x|*|...] [pool={pool-name}] [namespace={namespace-name}]' [{daemon} 'allow [r|w|x|*|...] [pool={pool-name}] [namespace={namespace-name}]']
```

例如：

```
ceph auth get client.john

ceph auth caps client.john mon 'allow r' osd 'allow rw pool=liverpool'

ceph auth caps client.paul mon 'allow rw' osd 'allow rwx pool=liverpool'

ceph auth caps client.brian-manager mon 'allow *' osd 'allow *'
```

有关[用户权限设置](https://www.bookstack.cn/read/ceph-en/dd0e02d97d027599.md#authorization-capabilities)的更多详细信息，请参见[授权（功能）](https://www.bookstack.cn/read/ceph-en/dd0e02d97d027599.md#authorization-capabilities)。

### 删除用户

要删除用户，请使用`ceph auth del`：

```
ceph auth del {TYPE}.{ID}
```

这里`{TYPE}`是一个`client`，`osd`，`mon`，或`mds`，并且`{ID}`是用户名或守护进程的ID。

### 打印用户密钥

要将用户的认证密钥打印到标准输出，请执行以下操作：

```
ceph auth print-key {TYPE}.{ID}
```

这里`{TYPE}`是一个`client`，`osd`，`mon`，或`mds`，并且`{ID}`是用户名或守护进程的ID。

当您需要使用用户密钥（例如，libvirt）填充客户端软件时，打印用户密钥非常有用。

```
mount -t ceph serverhost:/ mountpoint -o name=client.user,secret=`ceph auth print-key client.user`
```

### 导入用户

要导入一个或多个用户，请使用`ceph auth import`并指定密钥环：

```
ceph auth import -i /path/to/keyring
```

例如：

```
sudo ceph auth import -i /etc/ceph/ceph.keyring
```

注意：ceph存储集群将添加新用户，其密钥和功能，并将更新现有用户，其密钥和功能。



### 密钥相关操作

请参考社区说明