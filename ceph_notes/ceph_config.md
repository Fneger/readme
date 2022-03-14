# Ceph相关配置

## 官网命令参考

[Command Reference](https://www.bookstack.cn/read/ceph-en/78cb7aec7d1a820d.md)

[参考博文](https://durantthorvalds.top/2020/12/15/Ceph%20%E9%85%8D%E7%BD%AE%E5%8F%82%E6%95%B0/)

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



查看网卡信息

```
sudo lshw -C network
```



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



## OSD配置

[官方参考](https://www.bookstack.cn/read/ceph-en/c6d22bf663728a07.md)

### 日志设置

默认情况下，Ceph希望您使用以下路径存储Ceph OSD Daemons日志：

```
/var/lib/ceph/osd/$cluster-$id/journal
```

当使用单一设备类型（例如，旋转驱动器）时，日志应位于*同一位置*：逻辑卷（或分区）应与`data`逻辑卷位于同一设备中。

将快速（SSD，NVMe）设备与速度较慢的设备（如旋转驱动器）混合使用时，将日志放置在速度较快的设备上，而`data`完全占用速度较慢的设备是有意义的。

默认`osd journal size`值为5120（5 GB），但可以更大，在这种情况下，需要在`ceph.conf`文件中进行设置：

```
osd journal size = 10240
```

```
osd journal
```

- 描述
- OSD日志的路径。这可能是文件或阻止设备（例如SSD的分区）的路径。如果是文件，则必须创建目录来包含它。我们建议使用与`osd data`驱动器分开的驱动器。
- 类型
- 细绳
- 默认
- `/var/lib/ceph/osd/$cluster-$id/journal`

```
osd journal size
```

- 描述
- 日志的大小（以兆字节为单位）。
- 类型
- 32位整数
- 默认
- `5120`

有关其他详细信息，请参见[日志配置参考](https://www.bookstack.cn/read/ceph-en/d594b128bab87fac.md)。

#### Scrubbing

除了制作对象的多个副本外，Ceph还通过scrub放置组来确保数据完整性。Ceph Scrub类似于`fsck`对象存储层上的scrub。对于每个放置组，Ceph都会生成所有对象的目录，并比较每个主要对象及其副本，以确保没有对象丢失或不匹配。轻scrub（每天）检查对象的大小和属性。深度scrub（每周一次）读取数据并使用校验和以确保数据完整性。

Scrub对于保持数据完整性很重要，但是会降低性能。您可以调整以下设置以增加或减少Scrub操作。

```
sd max scrubs
```

- 描述
- Ceph OSD守护程序的最大同时清理操作数。
- 类型
- 32位整数
- 默认
- `1`

```
osd scrub begin hour
```

- 描述
- 可以执行计划的擦洗的下限的一天中的时间。
- 类型
- 整数，范围为0到24
- 默认
- `0`

```
osd scrub end hour
```

- 描述
- 可以执行计划的擦洗的上限时间。与`osd scrub begin hour`一起定义了一个时间窗口，可以在其中进行清理。但是只要展示位置组的清理间隔超过，无论时间窗口允许与否，都将执行清理`osd scrub max interval`。
- 类型
- 整数，范围为0到24
- 默认
- `24`

```
osd scrub begin week day
```

- 描述
- 这将清理时间限制在一周中的这一天或以后的一天。0或7 =星期日，1 =星期一，依此类推。
- 类型
- 整数，范围为0到7
- 默认
- `0`

```
osd scrub end week day
```

- 描述
- 这将清理时间限制在早于此时间的一周中的几天.0或7 =星期日，1 =星期一，依此类推。
- 类型
- 整数，范围为0到7
- 默认
- `7`

```
osd scrub during recovery
```

- 描述
- 恢复期间允许擦洗。将其设置为`false`会在活动恢复时禁用计划新的清理（和深度清理）。已经运行的清理将继续进行。这对于减少繁忙群集上的负载可能很有用。
- 类型
- 布尔型
- 默认
- `true`

```
osd scrub thread timeout
```

- 描述
- 超时超时前（以秒为单位）。
- 类型
- 32位整数
- 默认
- `60`

```
osd scrub finalize thread timeout
```

- 描述
- 超时清理终止finalize线程之前的最长时间（以秒为单位）。
- 类型
- 32位整数
- 默认
- `60*10`

```
osd scrub load threshold
```

- 描述
- 归一化的最大负载。当系统负载（由定义`getloadavg() / number of online cpus`）高于此数字时，Ceph不会进行清理`0.5`。默认值为。
- 类型
- 漂浮
- 默认
- `0.5`

```
osd scrub min interval
```

- 描述
- 当Ceph存储群集负载较低时，清理Ceph OSD守护程序的最小时间间隔（以秒为单位）。
- 类型
- 漂浮
- 默认
- 每天一次。 `60*60*24`

```
osd scrub max interval
```

- 描述
- 清理Ceph OSD守护程序的最大时间间隔（以秒为单位），与群集负载无关。
- 类型
- 漂浮
- 默认
- 每周一次。 `7*60*60*24`

```
osd scrub chunk min
```

- 描述
- 在单个操作期间要清理的对象存储块的最小数量.Ceph块在清理期间写入单个块。
- 类型
- 32位整数
- 默认
- 5

```
osd scrub chunk max
```

- 描述
- 单个操作期间要清理的对象存储块的最大数量。
- 类型
- 32位整数
- 默认
- 25

```
osd scrub sleep
```

- 描述
- 在擦洗下一组食物之前需要睡眠。增大此值将减慢整个清理操作，而对客户端操作的影响较小。
- 类型
- 漂浮
- 默认
- 0

```
osd deep scrub interval
```

- 描述
- “深度”清理的间隔（完全读取所有数据）。在`osd scrub load threshold`不影响此设置。
- 类型
- 漂浮
- 默认
- 每周一次。 `60*60*24*7`

```
osd scrub interval randomize ratio
```

- 描述
- `osd scrub min interval`在为展示位置组安排下一个清理作业时，添加一个随机延迟。延迟是小于的随机值`osd scrub min interval` *`osd scrub interval randomized ratio`。因此，默认设置实际上是在允许的时间范围内随机分配灌木丛`[1, 1.5]`* `osd scrub min interval`。
- 类型
- 漂浮
- 默认
- `0.5`

```
osd deep scrub stride
```

- 描述
- 进行深层清洁时，请阅读尺码。
- 类型
- 32位整数
- 默认
- 512 KB。 `524288`

```
osd scrub auto repair
```

- 描述
- `true`当在scrub或deep-scrub中发现错误时，将此选项设置为将启用自动pg修复。但是，如果`osd scrub auto repair num errors`发现的错误多于错误，则不会进行维修。
- 类型
- 布尔型
- 默认
- `false`

```
osd scrub auto repair num errors
```

- 描述
- 如果发现的错误不止这些，将不会进行自动修复。
- 类型
- 32位整数
- 默认
- `5`

#### Operations

```
osd op queue
```

- 描述
- 这设置了用于对OSD的操作进行优先级排序的队列类型。这两个队列均具有严格的子队列，该子队列在普通队列之前已出队。普通队列在实现之间是不同的。原始的PrioritizedQueue（`prio`）使用令牌桶系统，当有足够的令牌时，它将首先使高优先级队列出队。如果没有足够的令牌，队列将从低优先级到高优先级出队`wpq`.WeightedPriorityQueue （）将与优先级相关的所有优先级出队，以防止任何队列饿死。新的基于mClock的OpClassQueue（`mclock_opclass`）会根据其所属的类（恢复，清理，snaptrim，客户端操作，osd子操作）对操作进行优先级排序。`mclock_client`）还加入了客户标识符，以促进客户之间的公平。请参阅[基于mClock的QoS](https://www.bookstack.cn/read/ceph-en/c6d22bf663728a07.md#qos-based-on-mclock)。需要重启。
- 类型
- 细绳
- 有效选择
- prio，wpq，mclock_opclass，mclock_client
- 默认
- `wpq`

```
osd op queue cut off
```

- 描述
- 这将选择将哪个优先级ops发送到严格队列而不是普通队列。该`low`设置将所有复制操作和更高版本发送到严格队列，而该`high`选项仅将复制确认操作和更高版本发送到严格队列。如果`high`群集中的一些OSD非常繁忙，尤其是与`wpq`该`osd op queue`设置结合使用时，将其设置为应该会有所帮助。在没有这些设置的情况下，非常忙于处理复制流量的OSD可能会使主要客户端流量在这些OSD上饿死。需要重启。
- 类型
- 细绳
- 有效选择
- 低高
- 默认
- `high`

```
osd client op priority
```

- 描述
- 为客户端操作设置的优先级。
- 类型
- 32位整数
- 默认
- `63`
- 有效范围
- 1-63

```
osd recovery op priority
```

- 描述
- 为恢复操作设置的优先级，如果未由池的指定`recovery_op_priority`。
- 类型
- 32位整数
- 默认
- `3`
- 有效范围
- 1-63

```
osd scrub priority
```

- 描述
- 当池未指定值时，为计划的清理工作队列设置的默认优先级`scrub_priority`。这可以提升为`osd client op priority`scrub阻止客户端操作时的值。
- 类型
- 32位整数
- 默认
- `5`
- 有效范围
- 1-63

```
osd requested scrub priority
```

- 描述
- 在工作队列上为用户请求的清理设置的优先级。如果该值小于此值，则`osd client op priority`可以将其`osd client op priority`增大为when scrub阻止客户端操作的值。
- 类型
- 32位整数
- 默认
- `120`

```
osd snap trim priority
```

- 描述
- 为对齐修剪工作队列设置的优先级。
- 类型
- 32位整数
- 默认
- `5`
- 有效范围
- 1-63

```
osd snap trim sleep
```

- 描述
- 下一次快照修剪操作之前的睡眠时间（秒）。增加此值将减慢快照修剪。此选项将覆盖特定于后端的变量。
- 类型
- 漂浮
- 默认
- `0`

```
osd snap trim sleep hdd
```

- 描述
- 下一次快速修整HDD之前，以秒为单位的睡眠时间。
- 类型
- 漂浮
- 默认
- `5`

```
osd snap trim sleep ssd
```

- 描述
- 下一次快速修整opfor SSD之前，以秒为单位的睡眠时间。
- 类型
- 漂浮
- 默认
- `0`

```
osd snap trim sleep hybrid
```

- 描述
- 当osd数据位于HDD上并且osd日志位于SSD上时，下一次快照修整之前的睡眠时间（以秒为单位）。
- 类型
- 漂浮
- 默认
- `2`

```
osd op thread timeout
```

- 描述
- Ceph OSD守护程序操作线程超时（以秒为单位）。
- 类型
- 32位整数
- 默认
- `15`

```
osd op complaint time
```

- 描述
- 在指定的秒数过去之后，一项操作值得投诉。
- 类型
- 漂浮
- 默认
- `30`

```
osd op history size
```

- 描述
- 跟踪的已完成操作的最大数量。
- 类型
- 32位无符号整数
- 默认
- `20`

```
osd op history duration
```

- 描述
- 要跟踪的最旧的已完成操作。
- 类型
- 32位无符号整数
- 默认
- `600`

```
osd op log threshold
```

- 描述
- 一次显示多少个操作日志。
- 类型
- 32位整数
- 默认
- `5`

## Pool，PG和CRUSH配置参考

当您创建池并设置池的放置组数时，当您没有专门覆盖默认值时，Cephuses将使用默认值。**建议**覆盖一些默认值。具体来说，我们建议设置池的副本大小，并覆盖默认的放置组数。您可以在运行[池](https://www.bookstack.cn/read/ceph-en/1d9994450843e4a5.md)命令时专门设置这些值。您还可以通过在您`[global]`的Ceph配置文件的部分中添加新的默认值来覆盖默认值。

```
[global]
 
# By default, Ceph makes 3 replicas of objects. If you want to make four
# copies of an object the default value--a primary copy and three replica
# copies--reset the default values as shown in 'osd pool default size'.
# If you want to allow Ceph to write a lesser number of copies in a degraded
# state, set 'osd pool default min size' to a number less than the
# 'osd pool default size' value.
 
    osd pool default size =3# Write an object 3 times.
    osd pool default min size =2# Allow writing two copies in a degraded state.
 
# Ensure you have a realistic number of placement groups. We recommend
# approximately 100 per OSD. E.g., total number of OSDs multiplied by 100
# divided by the number of replicas (i.e., osd pool default size). So for
# 10 OSDs and osd pool default size = 4, we'd recommend approximately
# (100 * 10) / 4 = 250.
# always use the nearest power of 2
 
    osd pool default pg num =256
    osd pool default pgp num =256
```

```
mon max pool pg num
```

- 描述
- 每个池的最大放置组数。
- 类型
- 整数
- 默认
- `65536`

```
mon pg create interval
```

- 描述
- 在同一个Ceph OSD守护进程中创建PG之间的秒数。
- 类型
- 漂浮
- 默认
- `30.0`

```
mon pg stuck threshold
```

- 描述
- PG被认为卡住的秒数。
- 类型
- 32位整数
- 默认
- `300`

```
mon pg min inactive
```

- 描述
- `HEALTH_ERR`如果PG保持不活动的时间`mon_pg_stuck_threshold`超过此设置的时间，请在群集日志中发出a 。非正数表示已禁用，请勿输入ERR。
- 类型
- 整数
- 默认
- `1`

```
mon pg warn min per osd
```

- 描述
- `HEALTH_WARN`如果每个（在）OSD中的PG的平均数量低于此数量，请在群集日志中发出一个。（一个非正数会禁用此）
- 类型
- 整数
- 默认
- `30`

```
mon pg warn min objects
```

- 描述
- 如果群集中的对象总数低于此数目，则不发出警告
- 类型
- 整数
- 默认
- `1000`

```
mon pg warn min pool objects
```

- 描述
- 不要警告对象号低于此数字的池
- 类型
- 整数
- 默认
- `1000`

```
mon pg check down all threshold
```

- 描述
- 降低OSD百分比的阈值之后，我们将检查所有PG中是否有过时的PG。
- 类型
- 漂浮
- 默认
- `0.5`

```
mon pg warn max object skew
```

- 描述
- `HEALTH_WARN`如果某个池的`mon pg warn max object skew`平均对象数大于整个池的平均对象数，则在群集日志中发出a 。（零或非正数将禁用此功能）。请注意，此选项适用于管理者。
- 类型
- 漂浮
- 默认
- `10`

```
mon delta reset interval
```

- 描述
- 在将pg delta重置为0之前不活动的秒数。我们跟踪每个池的已用空间的delta，因此，例如，对于我们来说，更容易理解恢复的进度或缓存层的性能。但是，如果没有报告某个特定池的活动，我们只需重置该池的增量历史记录即可。
- 类型
- 整数
- 默认
- `10`

```
mon osd max op age
```

- 描述
- 我们担心之前的最大操作年龄（`HEALTH_WARN`设为2的幂）。如果请求被阻止的时间超过此限制，则将发出A。
- 类型
- 漂浮
- 默认
- `32.0`

```
osd pg bits
```

- 描述
- 每个Ceph OSD守护程序的放置组位。
- 类型
- 32位整数
- 默认
- `6`

```
osd pgp bits
```

- 描述
- PGP的每个Ceph OSD守护程序的位数。
- 类型
- 32位整数
- 默认
- `6`

```
osd crush chooseleaf type
```

- 描述
- `chooseleaf`在CRUSH规则中使用的存储桶类型。使用顺序等级而不是名称。
- 类型
- 32位整数
- 默认
- `1`。通常，一台主机包含一个或多个Ceph OSD守护程序。

```
osd crush initial weight
```

- 描述
- 将新添加的osds的初始压缩重量添加到rushmap中。
- 类型
- 双倍的
- 默认
- `the size of newly added osd in TB`。默认情况下，新添加的osd的初始压缩重量设置为以TB为单位的卷大小。有关详细信息，请参阅[加权存储桶项目](https://www.bookstack.cn/read/ceph-en/18e903f31a47a50b.md#weightingbucketitems)。

```
osd pool default crush rule
```

- 描述
- 创建复制池时要使用的默认CRUSH规则。
- 类型
- 8位整数
- 默认
- `-1`，表示“选择数字ID最低的规则并使用该规则”。这是为了在没有规则0的情况下创建池。

```
osd pool erasure code stripe unit
```

- 描述
- 设置擦除条纹池的对象条纹的默认大小（以字节为单位）。每个大小为S的对象将存储为N条，每个数据块接收`stripe unit`字节。每个`N *stripe unit`字节的条带将分别进行编码/解码。`stripe_unit`擦除代码配置文件中的设置可以覆盖此选项。
- 类型
- 无符号32位整数
- 默认
- `4096`

```
osd pool default size
```

- 描述
- 设置池中对象的副本数。默认值与相同`ceph osd pool set {pool-name} size {size}`。
- 类型
- 32位整数
- 默认
- `3`

```
osd pool default min size
```

- 描述
- 设置池中对象的最小写入副本数，以确认对客户端的写入操作。如果未达到最小值，则Ceph将不会确认对客户端的写入，**这可能会导致数据丢失**。此设置可确保在`degraded`模式下运行时的最小副本数。
- 类型
- 32位整数
- 默认
- `0`，这意味着没有特别的下限。如果`0`，最小值为`size - (size / 2)`。

```
osd pool default pg num
```

- 描述
- 池的默认放置组数。将默认值是一样的`pg_num`用`mkpool`。
- 类型
- 32位整数
- 默认
- `16`

```
osd pool default pgp num
```

- 描述
- 池放置的默认放置组数。默认值`pgp_num`与`mkpool`.PG相同，并且PGP应该相等（目前）。
- 类型
- 32位整数
- 默认
- `8`

```
osd pool default flags
```

- 描述
- 新池的默认标志。
- 类型
- 32位整数
- 默认
- `0`

```
osd max pgls
```

- 描述
- 要列出的展示位置组的最大数量。大量请求的客户端可以占用Ceph OSD守护程序。
- 类型
- 无符号64位整数
- 默认
- `1024`
- 笔记
- 默认应该没问题。

```
osd min pg log entries
```

- 描述
- 修剪日志文件时要维护的最小放置组日志数。
- 类型
- 32位Int Unsigned
- 默认
- `1000`

```
osd default data pool replay window
```

- 描述
- OSD等待客户端重播请求的时间（以秒为单位）。
- 类型
- 32位整数
- 默认
- `45`

```
osd max pg per osd hard ratio
```

- 描述
- 在OSD拒绝创建新PG之前，集群允许的每个OSD PG数量的比率。如果OSD服务的PG数量超过`osd max pg per osd hard ratio`*，则OSD停止创建新的PG `mon max pg per osd`。
- 类型
- 漂浮
- 默认
- `2`

```
osd recovery priority
```

- 描述
- 工作队列中恢复的优先级。
- 类型
- 整数
- 默认
- `5`

```
osd recovery op priority
```

- 描述
- 如果不覆盖池，则用于恢复操作的默认优先级。
- 类型
- 整数
- 默认
- `3`

## CRUSH Map配置

### 官方参考

[CRUSH Maps](https://www.bookstack.cn/read/ceph-en/18e903f31a47a50b.md)

[Manually editing a CRUSH Map](https://www.bookstack.cn/read/ceph-en/0730a7216541bcdd.md)

[参考博文](https://www.cnblogs.com/zyxnhr/p/10610295.html)

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

[参考博文](https://durantthorvalds.top/2020/11/26/ceph%E7%BA%A0%E5%88%A0%E7%A0%81%E9%83%A8%E7%BD%B2/)

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

rbd import-diff test_img_to_snap1 rbd/test_img_recover



## RBD客户端缓存

## 正确修改Ceph集群IP地址

当我们需要把整个Ceph集群的网络地址修改为另一个子网地址（与ceph.conf的public addr等不相同）时，就需要更改Ceph Monitor，Ceph OSD，Ceph Manager的监听地址。其中，OSD和Manager的地址是根据ceph.conf文件中的配置项public addr与cluster addr等确定的，因此只需修改文件内容即可。而Ceph Monitor的地址则是由monmap维护的，直接修改monmap会产生不可预料的问题。本文将会给出如何在不直接修改monmap的情况下修改Mon的IP地址。

### 样例集群

原Ceph集群部署在10.1.1.0/24子网上，现在需要部署到192.168.1.0/24子网上，且机器已经配置了192.168.1.0/24中的地址。

用户相关设置，ceph的进程将由ceph用户执行，该用户为部署ceph时自动创建的用户。而执行命令的用户为某一拥有sudo权限的普通用户。这个很重要，官方文档没有说明用户权限的重要性，导致根据[Adding/Removing Monitors](https://docs.ceph.com/docs/nautilus/rados/operations/add-or-rm-mons/)一文的Add Monitor操作，将会引起权限的错误。以下所有的命令均使用普通用户执行。

### 配置网卡IP

由于机器的地址已经发生改变，Ceph集群的monitors之间必然无法达成quorum。首先我们需要让其达成quorum，才好进行手动添加和删除monitor的操作。

因此，我们需要把原本的地址配置一下。配置的方法，遵循给网卡添加IP地址的方法。假设旧地址为`10.1.1.1`，新地址为`192.168.1.1`。若使用`ip命令`，则为

```
$ ip addr add 10.1.1.1/24 dev <网卡设备名称>
```

使用nmcli的话，则为

```
# 方括号内容可以省略以缩短命令长度
$ nmcli c[onnection] m[odify] <设备名或网络配置名> ipv4.addr[ess] "10.1.1.1/24, 192.168.1.1/24"
```

所有机器配置好后，应该能够达成quorum，若不行，则使用systemctl重启mon应该能解决。

### 添加新的Monitor

修改IP地址的时候官方推荐添加新的IP的Monitor，而不是改原有的。假设新的monitor称为`amaster`，原有monitor称为`master`。在此提醒，新的monitor名称不能与原有的重复。

首先创建新的monitor默认使用的文件夹。由于`/var/lib/ceph`文件夹为ceph用户所有，我们需要使用sudo。一般sudo仅能使用root用户，若能以ceph用户执行命令，则省去修改拥有者的麻烦。

```
$ sudo mkdir /var/lib/ceph/mon/ceph-amaster
```

此时应有

```
$ ls -l /var/lib/ceph/mon/
drwxr-x--- 15 ceph          ceph          4.0K 11月 17 09:56 ceph-master
drwxr-x--- 15 root          root          4.0K 1月  10 09:56 ceph-amaster
```

如果配置了cephx认证，则需要获取一下新的keyring。

```
ceph auth get mon.amaster -o <keyring文件名>
```

获取monmap

```
ceph mon getmap -o <monmap文件名>
```

准备一下默认文件夹的内容

```
ceph-mon -i amaster --mkfs --monmap <monmap文件> [--keyring <keyring文件>]
```

接下来这几步与官网的不同。先是修改monitor文件夹的拥有者，改回ceph，因为创建时为root，而monitor运行时的用户为ceph，无法访问这个文件夹。

```
chown -R ceph:ceph /var/lib/ceph/mon/ceph-amaster
```

修改配置文件，让新的monitor使用新的地址进行绑定。如果图方便，就修改global的，如下

```
[global]
...
public addr = 192.168.1.0/24
```

或者保险一点，仅修改新的mon的，如下

```
[mon.amaster]
...
public addr = 192.168.1.0/24
```

然后使用systemctl功能启动ceph-monitor

```
systemctl start ceph-mon@amaster.service
```

可以设置一下enable，开机启动cephmon

```
systemctl enable ceph-mopn@amaster.service
```

按照官网的教程会有Permission Denied的问题。

### 删除旧monitor

官网的教程在这里再一次有问题，不能按照其命令的顺序来，否则可能共识出错。

首先remove掉旧的monitor。

```
ceph mon remove master
```

然后，再停止进程，删除symlink

```
systemctl stop ceph-mon@master.service
systemctl disable ceph-mon@master.service
```

至此，单个Monitor的IP就修改完了。

------

- 