# Ceph常用命令

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
rbd create --size 1024 swimmingpool/bar
```

如果在创建映像时未指定池，则它将存储在默认池中`rbd`。例如，要创建一个`foo`存储在默认池中的名为1GB的映像`rbd`，请执行以下操作：

```
rbd create --size 1024 foo
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