# Ceph故障修复

## 常用命令

启动osd
systemctl start ceph-osd@1
停止osd
systemctl stop ceph-osd@1
查看osd进程状态
systemctl status ceph-osd@0.service



## 找出问题PG

当放置组陷入困境时，Ceph的自我修复功能可能会失效。 卡住的状态包括：

**Unclean**:展示位置组包含未复制所需次数的对象。 他们应该正在恢复。

**Inactive**:放置组无法处理读取或写入，因为它们正在等待OSD包含最新数据。

**Stale**: 放置组处于未知状态，因为承载它们的OSD已有一段时间未报告到监视器集群（由mon osd报告超时配置）。

要确定卡住的放置组，请执行以下操作：

ceph pg dump_stuck [unclean|inactive|stale|undersized|degraded]



## 故障描述及解决方案

### Reduced data availability: 1 pg inactive

调整min_size=1可以解决IO夯住问题 
获取pool min_size 信息
ceph osd pool get test_pool min_size
设置pool min_size 信息
ceph osd pool set test_pool min_size 1

### full_ratio导致小于backfillfull_ratio

full ratio(s) out of order
full_ratio (0.85) < backfillfull_ratio (0.9), increased
ceph osd set-full-ratio 0.95
ceph osd set-nearfull-ratio 0.9

### mon node0 is low on available space（/var/lib/ceph/mon/目录所剩空间所占比例，超过报警阀值）

查看当期mon_data_avail_warn值
ceph config get mon mon_data_avail_warn
设置mon_data_avail_warn值
ceph config set mon mon_data_avail_warn 10

!!!!!!!!!!一个磁盘只能对应一个OSD节点
Undersized PG当前Acting Set小于储存池副本数
Degraded 被降级

## osd (near) full 的解决方法

根本解决之道是添加 osd，临时解决方法是删除无用数据，osd full 时所有的读写操作都无法进行，可通过两种方法恢复读写后再执行删除数据的命令：
• 一是调整 full osd 的权重：ceph osd crush reweight osd.33 0.7 或者 ceph osd reweight-by-utilization

• 二是调高 full 的上限：ceph osd set-full-ratio 0.98，参见：no-free-drive-space



## osd Crash解決辦法

新的崩溃可以通过以下方式列出
ceph crash ls-new
有关特定崩溃的信息，可以使用以下方法检查
ceph crash info <crash-id>
通过“存档”崩溃（可能是在管理员检查之后）来消除此警告，从而不会生成此警告
ceph crash archive <crash-id>
新的崩溃都可以通过以下方式存档
ceph crash archive-all


