# Ceph相关配置

## 官网命令参考

[Command Reference](https://www.bookstack.cn/read/ceph-en/78cb7aec7d1a820d.md)

## CLI命令用于配置集群

将转储群集的整个配置数据库
ceph config dump
将转储特定的守护程序或客户端（例如mds.a）的配置，该配置存储在监视器的配置数据库中
ceph config get <who>
将在监视器的配置数据库中设置配置选项
ceph config set <who> <option> <value>
将显示报告的正在运行的守护程序的运行配置。如果还使用了本地配置文件，或者在命令行或运行时覆盖了选项，则这些设置可能与监视器存储的设置不同。选项值的来源报告为输出的一部分
ceph config show <who>
将从输入文件中提取配置文件，并将所有有效选项移至监视器的配置数据库中。监视器无法识别，无效或无法控制的任何设置都将在输出文件中存储的简短配置文件中返回。此命令对于从旧版配置文件过渡到基于集中式监视器的配置很有用
ceph config assimilate-conf -i <input file> -o <output file>

### 获取帮助

获取特定选项的帮助
ceph config help <option>
示例：
ceph config help log_file
ceph config help log_file -f json-pretty

### 运行时修改

ceph config set
示例：
例如，在特定的OSD上启用调试日志级别
ceph config set osd.123 debug_ms 20
请注意，如果在本地配置文件中还自定义了同一选项，则将忽略监视器设置（其优先级低于本地配置文件）

### 覆盖值

tell or daemon_interfaces只能影响当前正在运行的进程，进程重启后使用配置文件中的值，临时覆盖的值不再生效
在任何主机上，我们都可以通过网络发送消息
ceph tell <name> config set <option> <value>
例如：
ceph tell osd.123 config set debug_osd 20
tell命令同时也支持通配符
eph tell osd.* config set debug_osd 20

在运行该进程的主机上，我们可以通过/ var / run / ceph中的套接字直接连接到该进程，其中：
ceph daemon <name> config set <option> <value>
示例：
ceph daemon osd.4 config set debug_osd 20
请注意，在ceph config show命令输出中，将显示这些临时值以及替代源

### 查看运行时设置

使用ceph config show命令
示例：
ceph config show osd.0
查看守护进程的特定选项
ceph config show osd.0 debug_osd
看所有选项（甚至是具有默认值的选项）
ceph config show-with-defaults osd.0
通过管理套接字从本地主机连接到正在运行的守护程序来观察其设置
ceph daemon osd.0 config show
转储所有当前设置
ceph daemon osd.0 config diff
仅显示非默认设置
ceph daemon osd.0 config get debug_osd

### 通用配置

[global]
mon_initial_members = ceph1
mon_host = 10.0.0.1
一般不做修改，mon_initial_members为主机名



## 网络配置参考

一个公共（前端）网络（外部访问）和一个群集（后端）网络（集群各进程间通信）
iptables中除ssh意以外，其他端口均关闭
REJECT all -- anywhere anywhere reject-with icmp-host-prohibited
其中
{iface}：网卡名称(e.g., eth0,eth1, etc.),
{ip-address}：集群公共网络IP地址
{netmask}：集群公共网络掩码

### MON

端口3300和6789为默认端口
sudo iptables -A INPUT -i {iface} -p tcp -s {ip-address}/{netmask} --dport 6789 -j ACCEPT
示例：
sudo iptables -A INPUT -i wlp4s0 -p tcp -s 192.168.1.12/255.255.255.0 --dport 6789 -j ACCEPT

### MDS和Mgr

默认端口6800-7300
sudo iptables -A INPUT -i {iface} -m multiport -p tcp -s {ip-address}/{netmask} --dports 6800:7300 -j ACCEPT
示例：
sudo iptables -A INPUT -i wlp4s0 -m multiport -p tcp -s 192.168.1.12/255.255.255.0 --dports 6800:7300 -j ACCEPT

### OSD

默认端口6800-7300
一种用于与客户和监视器对话
一种用于将数据发送到其他OSD
两个用于每个接口上的心跳

sudo iptables -A INPUT -i {iface}  -m multiport -p tcp -s {ip-address}/{netmask} --dports 6800:7300 -j ACCEPT
示例：
sudo iptables -A INPUT -i wlp4s0 -m multiport -p tcp -s 192.168.1.12/255.255.255.0 --dports 6800:7300 -j ACCEPT

### Ceph

Ceph对子网（例如）使用CIDR表示法10.0.0.0/24。

配置网络后，可以重新启动集群或重新启动每个守护程序。Ceph守护程序是动态绑定的，因此，如果您更改网络配置，则不必立即重新启动整个群集
集群内部公共网络
[global]
        \# ..elided configuration
        public network = {public-network/netmask}
集群供外部访问网络
[global]
        \#..elided configuration
        cluster network = {cluster-network/netmask}
集群内部公共网络无法访问外部网络以增加访问的安全性

### Ceph Daemons

通过部署工具自动配置
[global]
    mon host = 10.0.0.2, 10.0.0.3, 10.0.0.4
MGR, OSD, and MDS daemons设定特定IP地址，使用类似设置
[osd.0]
        public addr = {host-public-ip-address}
        cluster addr = {host-cluster-ip-address}

### 网络配置设置

不需要网络配置设置。除非您专门配置群集网络，否则Ceph假定所有主机都在其上运行的公共网络。



## MON配置

### 简单配置

mon_host通过部署工具自动配置
[global]
        mon_host = 10.0.0.2,10.0.0.3,10.0.0.4
[mon.a]
        host = hostname1
        mon_addr = 10.0.0.10:6789

一旦部署了Ceph集群，就不应更改监视器的IP地址。但是，如果您决定更改显示器的IP地址，则必须遵循特定的步骤



## CRUSH Map配置

### 官方参考

[CRUSH Maps](https://www.bookstack.cn/read/ceph-en/18e903f31a47a50b.md)

[Manually editing a CRUSH Map](https://www.bookstack.cn/read/ceph-en/0730a7216541bcdd.md)

通过CLI命令可在线修改CRUSH Map各项配置，也可以通过直接编辑CRUSH map实现

### 1.获取CRUSH map

输出集群的CRUSH map至指定文件

ceph osd getcrushmap -o {compiled-crushmap-filename}

手动创建CRUSH map 

crushtool -o {compiled-crushmap-filename} --build --num_osd2 Nlayer1 ...

其中 --num_osds Nlayer1 ...将N个OSD从0开始编号，然后在指定的层级之间平均分布，每个层级（layer）需要采用形如<name,algorithm, size>(其中size指每种类型的buchet下包含条目的个数)的三元组进行描述，并按照从低（靠近叶子节点）到高（靠近根节点）的顺序进行排序，示例（osd->host->rack->root）：

crushtool -o mycrushshmap --build --num_osds 27 host straw2 3 rack straw2 3 root uniform 0

需要注意的是，上述方式输出的CRUSH mao都是经过编译的，需要经过反编译才能被正常编辑

### 2.反编译CRUSH map

将编译文件转化为可编辑版本

crushtool -d {compiled-crushmap-filename} -o {decompiled-crushmap-filename}

示例：

crushtool -d mycrushmap -o mycrushmap.txt

### 3.编辑CRUSH map

```
rule replicated_rule {
        id 0
        type replicated
        min_size 1
        max_size 10
        step take default
        step chooseleaf firstn 0 type host
        step emit
}
```

可编辑CRUSH map文件中ruleset相关选项及其具体含义如下所示：

```
rule <rulename> {
id <id > [整数，规则id]
type [replicated|erasure] [规则类型，用于复制池还是纠删码池]
min_size <min-size> [如果池的最小副本数小于该值，则不会为当前池应用这条规则]
max_size <max-size>[如果创建的池的最大副本大于该值，则不会为当前池应用这条规则]
step take <bucket type> [这条规则作用的bucket，默认为default]
step [chooseleaf|choose] [firstn] <num> type <bucket-type> 
# num == 0 选择N（池的副本数）个bucket
# num > 0且num < N 选择num个bucket
# num < 0 选择N-num(绝对值)个bucket
step emit
```

#### step:take,chooseleaf,emit

chooseleaf,容灾域模式，可以替换为choose，后者对应非容灾域模式

firstn,两种选择算法之一，可以替换为indep

0，表示由具体的调用者指定输出的副本数，例如不同的pool可以使用同一套ruleset（拥有相同的备份策略），但是可以拥有不同的副本数

type，对应chooseleaf操作，指示输出必须是分布在由本选项指定类型的、不同的bucket之下的叶子节点；对应choose操作，指示输出类型

### 4.编译CRUSH map

crushtool -c {decompiled-crushmap-filename} - o {compiled-crushmap-filename}

示例：

crushtool -c crushmap_test.txt -o crushmap_test1

### 5.模拟测试

在新的CRUSH map生效之前，可以进行模拟测试

crushtool -i crushmap_test1 --test --max-x 9 --num_rep 3 --ruleset 0 --show_mappings

### 6.注入集群

新的CRUSH map验证充分后，可以重新注入集群，使之生效

ceph osd setcrushmap -i {compiled_crushmap-filename}



## 定制 CRUSH 规则

默认的容灾域一般为host级别，可以提升为rack，修改对应的ruleset（也可以新建一条ruleset）如下：

rule replicated_rule {
	id 0
	type replicated
	min_size 1
	max_size 10
	step take default
	step chooseleaf firstn 0 type rack
	step emit
}

使所有副本都位于不同rack的OSD之上



也可以限制只选择特定的rack（例如rack2）下的OSD，例如：

rule replicated_rule {
	id 0
	type replicated
	min_size 1
	max_size 10
	step take rack2
	step chooseleaf firstn 0 type host
	step emit
}

另外需要注意的是，在CRUSH map中，除了OSD（叶子节点）之外，其他层级关系都是虚拟的（不管其有无实际物理实体对应），这位灵活定制CRUSH提供了更大的遍历

#### 从命令行更新CRUSH map的 层次结构

创建bucket

```
ceph osd crush add-bucket DC1 datacenter
```

#### 规划新的bucket

定义新的rack

```
ceph osd crush add-bucket  rack1 rack
```

将rack加入dc1

```
ceph osd crush  move rack1 root=dc1
```

把主机移动到相应rack中

```
ceph osd crush link ceph2 rack=rack1
```

## 数据重平衡

通过手动调整每个OSDreweight可以触发PG在OSD之间进行迁移，以恢复数据平衡。上述数据重平衡操作可逐个OSD或者批量进行

### 逐个调整

首先查看整个整个集群的空间利用率统计

ceph osd df tree

找到空间利用率较高的OSD，然后逐个执行

ceph osd reweight {osd_numeric_id} {reweight}

osd_numeric_id:必选，整型，OSD对应的数字ID

reweight:必选，浮点类型，[0, 1]，带设置的OSD 的reweight。reweight取值越小，将使更多的数据从对应的OSD迁出

### 批量调整

目前有两种模式：一种按照OSD当前空间利用率（reweight-by-utilization）；另一种按照PG在OSD之间的分布（reweight-by-pg）。为了防止影响前端业务，可以先测试执行上述命令后，将会触发PG迁移数量的相关统计（以下都以reweight-by-utilization相关命令为例进行说明），以方便规划进行调整的时机：

#### 测试执行

ceph osd test-reweight-by-utilization {overload} {max_change} {max_osds} {--no-increasing}

overload:可选，整型，≥ 100；默认值120，当且仅当某个OSD的空间利用率大于等于集群平均空间利用率的overload/100时，调整其reweight

max_change:可选，浮点类型，[0, 1]；默认值受mon_reweight_max_change控制，目前为0.05.每次调整reweight的最大幅度，即调整上限。实际每个OSD调整幅度取决于自身空间利用率与集群平均空间利用率的偏离程度，偏离越多，则调整幅度越大，反之则调整幅度越小

max_osds：可选，整型；默认值受mon_reweight_max_osds控制，目前4.每次至多调整的OSD数目

--no-increasing：可选字符类型。如果携带，则从不将reweight进行上调（上调指将当前underload的OSD权重调大，让其分担更多PG）；如果不携带，至多将OSD的reweight调整至1.0

#### 确认调整

ceph osd reweight-by-utilization 105 .2 4 --no-increasing



## 部署BlueStore

### 官方参考

[BlueStore Migration](https://www.bookstack.cn/read/ceph-en/20131086c577af9e.md)

判断给定的OSD是FileStore还是BlueStore

ceph osd metadata $ID | grep osd_objectstore

获取文件存储与bluestore的当前计数

ceph osd count-metadata osd_objectstore

将FileStore替换为BlueStore参考

[部署和操作BlueStore](https://durantthorvalds.top/2020/12/27/%E4%B8%8B%E4%B8%80%E4%BB%A3%E5%AF%B9%E8%B1%A1%E5%AD%98%E5%82%A8%E5%BC%95%E6%93%8EBlueStore/)



## 纠删码配置

### 官网参考

[Erasure code](https://www.bookstack.cn/read/ceph-en/e84aa3dad45ac7b4.md)

纠删码池功能性能暂未达到商用水平

### 纠删码模板

查看纠删码默认配置文件

$ ceph osd erasure-code-profile getdefault

k=2

m=2

plugin=jerasure

crush-failure-domain=host

technique=reed_sol_van



创建一个纠删码模板

ceph osd erasure-code-profile set my-ec-profile plugin=jerasure k=3 m=2 technique=liber8tion ruleset-failure-domain=rack

k：数据盘个数

m：校验盘个数

technique：编码方式，默认为reed_sol_van；编码方式支持以下几种：

​	reed_sol_van：基于范德蒙德矩阵的RS-RAID

​	reed_sol_r6_op：基于范德蒙德矩阵的RAID6（优化）

​	cauchy_orig：基于原生柯西矩阵的RS-RAID

​	cauchy_good：基于最佳柯西矩阵的RS-RAID

​	liberation,blaum_roth,liber8tion：最小密度RAID6

packetsize：包大小，默认2048

plugin：字符类型，用于指定所采用的纠删码插件，jerasure（默认）,lrc,shec,isa

key=value：键值对，用于指定每种类型纠删码的具体配置参数，典型如数据盘和校验盘个数、选用的编码技术等。不同类型的纠删码可以有不同类型的键值对

uleset-failure-domain：字符类型，对应CRUSH模板的容灾域，例如为“host”，则要求纠删码的数据盘和校验盘分别位于不同主机之下

--force：字符类型，如果携带，覆盖任何已经存在的同名模板

上述命令创建了一个liber8tion算法（注意：此时m必须为2）、容灾域为主机级别（注意：因为k + m = 6，此时必须有6台主机才能使得容灾域配置正常生效）的纠删码模板，可以使用如下命令查看和确认：

ceph osd erasure-code-profile get my-ec-profile

最后，可以基于上述纠删码模板创建一个纠删码类型的储存池

ceph osd pool create my-ec-pool 128 erasure my-ec-profill

其中，命令中的128为关联储存池中的PG数目

纠删码储存池创建完成后，上层应用（例如RBD）可以通过librados接口正常读写池中的对象



## Ceph集群定时scrub

​	Ceph集群会定期进行Scrub操作，Scrub操作会对数据进行加锁，后端此时访问该数据会出现卡顿现象

​	Scrub是Ceph集群副本进行数据扫描的操作，用以检测副本间数据的一致性，包括Scrub和Deep-Scrub，其中Scrub只对元数据信息进行扫描，相对比较快，而Deep-Scrub不仅对元数据进行扫描，还会对数据进行扫描，相对比较慢。

​	OSD的Scrub的默认策略是每天到每周（如果集群负荷大周期就是一周，如果集群负荷小周期就是一天）进行一次，时间区域默认为全天（0时 - 24时），Deep-Scrub默认策略是每周一次。



基于业务运行时间进行调整

场景：晚22点到第二天7点进行Scrub

先通过tell方式，让Scrub时间区间配置立即生效，具体操作如下：

配置Scrub起始时间为22点整：

ceph tell osd.* injectargs "--osd-scrub-begin-hour 22"

配置Scrub结束时间为第二天早上7点整：

ceph tell osd.* injectargs "--osd-scrub-end-hour 7"

这样之后，可以使配置立即生效，即使集群服务重启或者节点重启，配置也会从配置文件中加载，永久生效。



## Ceph数据重建配置策略

​		在Ceph对接OpenStack的场景中，如果Ceph集群出现OSD的out或者in（增加、删除、上线、下线OSD等情况），最终会导致Ceph集群中的数据迁移及数据重建，数据迁移及重建会占用一部分网络带宽及磁盘带宽，此时可能导致OpenStack中使用Ceph作为后端储存的虚拟机出现卡顿现象。

### 场景一：优先保证Recovery带宽

​		在对数据安全性要求比较高的场景下，为了保证数据副本的完整性以及快速回复储存集群的健康，会优先保证数据恢复带宽，此时需要提升Recovery的I/O优先级，降低Client的I/O优先级，具体操作如下（在Ceph任意节点或客户端运行即可）：

提升Recovery的I/O优先级(12.0.0版本默认Recovery的I/O优先级为3)：

ceph tell osd.* injectargs "--osd-recovery-op-priority 63"

降低Client的I/O优先级（12.0.0版本默认Recovery的I/O优先级为63）：

ceph tell osd.* injectargs "--osd-client-op-priority 3"

待Recovery完成，需要还原配置

ceph tell osd.* injectargs "--osd-recovery-op-priority 3"

ceph tell osd.* injectargs "--osd-client-op-priority 63"

### 场景二：优先保证Client带宽

​		在对数据安全性要求不是很高的场景下，为了降低对用户体验的影响，会优先对Client的 I/O优先级及带宽进行保证，此时需要降低Recovery的I/O的优先级及带宽，具体操作如下（在Ceph任意节点或客户端运行即可）：

降低Recovery的I/O优先级(12.0.0版本默认Recovery的I/O优先级为3)：

ceph tell osd.* injectargs "--osd-recovery-op-priority 1"

降低Recovery的I/O带宽及Backfill带宽（12.0.0版本默认osd-recovery-max-active为3，osd-recovery-sleep为0）：

ceph tell osd.* injectargs "--osd-recovery-max-active 1"

ceph tell osd.* injectargs "--osd-recovery-sleep 0.4"

待Recovery完成，需要还原配置

ceph tell osd.* injectargs "--osd-recovery-op-priority 3"

ceph tell osd.* injectargs "--osd-recovery-max-active 3"

ceph tell osd.* injectargs "--osd-recovery-sleep 0"

### 场景三：完全保证Client带宽

​		在极端情况下，如果网络带宽及磁盘性能都有限，这个时候为了不影响用户体验，不得不在业务繁重时段关闭数据重建及迁移的I/O，来完全保证Client的带宽，在业务空闲时段再打开数据重建及迁移，具体操作如下：

在业务繁忙时，完全关闭数据重建及迁移：

ceph osd set norebalance

ceph osd set norecover

ceph osd set nobackfill

在业务繁忙时，完全关闭数据重建及迁移：

ceph osd unset norebalance

ceph osd unset norecover

ceph osd unset nobackfill

提示：如果在关闭数据重建及迁移期间，数据的其他副本损坏，则会导致副本数据无法完整找回的风险

### 备注

以上三种方案操作配置均为立即生效，且重启服务或者重启节点后失效，如果想长期生效，可以在进行以上操作配置立即生效后，修改所有ceph集群节点的配置文件。



## Ceph集群Full紧急处理

### 处理方法

​		当Ceph集群空间使用率大于等于near_full告警水位时，会触发集群进行告警，提示管理员此时集群空间使用率已经到达告警水位，如果管理员没有及时进行扩容或者相应的处理，随着数据 的增多，当集群空间使用率大于等于告警水位时，集群将停止接收来自客户端的写入请求（包括数据的删除操作）。

在MON节点查询MON配置：

ceph --admin-daemon /run/ceph/ceph-mon.{your-mon-ip}.asok config show | grep full_ratio

遇到near_full的告警该怎么办？

​		如果集群已经有near_full的告警了，而且也有扩容的设备，那么就可以考虑进行集群的扩容，，包括增加磁盘或者增加储存节点。

遇到full告警怎么办？

​		如果集群已经是full的告警了，此时业务已经无法向集群继续写入数据，而此时如果暂时无磁盘或储存节点可供扩容，应该先通知业务及时做好数据保存工作，并对集群进行紧急配置删除一些无用的数据，恢复集群正产工作状态，待扩容设备到了再进行扩容操作。

### 案例实战

#### 紧急配置步骤

设置OSD禁止读写

ceph osd pause

备注：该操作会禁止接收一切读写请求

通知MON和OSD修改full阀值

ceph tell mon.* injectargs "--mon-osd-full-ratio 0.96"

ceph tell osd.* injectargs "--mon-osd-full-ratio 0.96"

通知PG修改full阀值

ceph pg set_full_ratio 0.96

解除OSD禁止读写

ceph osd unpause

删除相关数据

将配置还原

ceph tell mon.* injectargs "--mon-osd-full-ratio 0.95"

ceph tell osd.* injectargs "--mon-osd-full-ratio 0.95"

ceph pg set_full_ratio 0.95

经过以上步骤，就可以紧急将无用数据删除，让集群恢复正常水位，并给扩容预留了时间



## Ceph快照在增量备份的应用

首先，我们创建一个image

rbd create rbd/test_image --size 5000 --image-format 2

然后，我们写入一部分数据到test_img这个image中（假设这部分数据为Time1_Data）:

为了能写入数据到image，我们先map该image到本地设备

rbd map test_image 

格式化该映射的本地设备

mkfs.ext4 /dev/rbd0

挂在该设备到本地目录

mount /dev/rbd0 /mnt/rbd_test/
写入相关内容

echo "Time1_Data" > /mnt/rbd_test/Time1_Data

umount该设备将写入内容刷新到image

umount /mnt/rbd_test/

之后对test_image创建一个快照：

rbd snap create rbd/test_image@snap1

然后在对test_image写入一部分数据（假设这部分数据为Time2_Data）:

mount /dev/rbd0 /mnt/rbd_test/

echo "Time2_Data" > /mnt/rbd_test/Time2_Data

umount /mnt/rbd_test/

接着在对test_image创建一个快照：

rbd snap create rbd/test_image@snap2

然后以同样的方法对tets_image写入Time3_Data内容然后创建快照test_image@snap3

### 全量备份

使用rbd export命令导出test_image进行全量备份：

rbd export rbd/test_image Time1_Data_img

### 增量备份

#### 备份

新创建test_image时，可以导出一个test_img_backup并备份

rbd export rbd/test_image test_img_backup

写入Time1_Data后，我们基于之前创建的快照test_image@snap1

导出从创建到写入Time1_Data之间的增量数据

rbd export-diff rbd/test_image@snap1 test_img_to_snap1

写入Time2_Data和Time3_Data按同样操作导出相应的增量数据

#### 恢复

首先导入test_img_backup:

rbd import test_img_backup rbd/test_img_recover

然后导入所有增量文件

rbd import_diff test_img_to_snap1 rbd/test_img_recover