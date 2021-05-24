# Ceph故障修复

[参考链接](https://durantthorvalds.top/2020/12/15/%E8%BF%81%E7%A7%BB%E4%B9%8B%E7%BE%8EPG%E8%AF%BB%E5%86%99%E6%B5%81%E7%A8%8B%E4%B8%8E%E7%8A%B6%E6%80%81%E8%BF%81%E7%A7%BB%E8%AF%A6%E8%A7%A3/)

[社区参考](https://www.bookstack.cn/read/ceph-en/4599aa129fa3fab2.md)

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

### LVM分区锁定解决办法

lvscan
lvremove

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

### osd (near) full 的解决方法

根本解决之道是添加 osd，临时解决方法是删除无用数据，osd full 时所有的读写操作都无法进行，可通过两种方法恢复读写后再执行删除数据的命令：
• 一是调整 full osd 的权重：ceph osd crush reweight osd.33 0.7 或者 ceph osd reweight-by-utilization

• 二是调高 full 的上限：ceph osd set-full-ratio 0.98，参见：no-free-drive-space



### osd Crash解決辦法

新的崩溃可以通过以下方式列出
ceph crash ls-new
有关特定崩溃的信息，可以使用以下方法检查
ceph crash info <crash-id>
通过“存档”崩溃（可能是在管理员检查之后）来消除此警告，从而不会生成此警告
ceph crash archive <crash-id>
新的崩溃都可以通过以下方式存档
ceph crash archive-all



### mon is allowing insecure global_id reclaim

[官方参考](https://docs.ceph.com/en/octopus/rados/operations/health-checks/)

### [errno 2] RADOS object not found (error connecting to the cluster)

[参考博文](https://segmentfault.com/a/1190000012348586)

### Reduced data availability: 10 pgs incomplete

[参考博文](https://medium.com/opsops/recovering-ceph-from-reduced-data-availability-3-pgs-inactive-3-pgs-incomplete-b97cbcb4b5a1)

[方法2](https://www.jianshu.com/p/36c2d5682d87)

### Reduced data availability: 1 pg inactive

[参考博文](https://zhuanlan.zhihu.com/p/74323736)

## 故障排查

### 记录和调试

[官方参考](https://www.bookstack.cn/read/ceph-en/7b7e247b0ffd58dd.md)

调试日志默认位置/var/log/ceph

调试输出会影响系统性能，占用大量资源，非一般情况不打开调试日志；如果在群集的特定区域遇到问题，请启用该群集区域的日志记录。例如，如果您的OSD运行良好，但元数据服务器运行不正常，则应首先为特定的元数据服务器实例启用调试日志记录，这会给您带来麻烦。根据需要启用每个子系统的日志记录。

注意：

详细的日志记录每小时可以生成超过1GB的数据。如果您的OS磁盘达到其容量，则该节点将停止工作。

当系统运行良好时，请删除不必要的调试设置，以确保集群以最佳状态运行。记录调试输出消息相对较慢，并且在操作集群时浪费资源。

#### 运行

如果要在运行时查看配置设置，则必须使用正在运行的守护程序登录到主机并执行以下操作：

```
ceph daemon {daemon-name} config show | less
```

例如：

```
ceph daemon osd.0 config show | less
```

要激活Ceph的的调试输出（*即*，`dout()`在运行时），可以使用`ceph tell`命令注入参数到运行时配置：

```
ceph tell {daemon-type}.{daemon id or *} config set {name} {value}
```

更换`{daemon-type}`用的一个`osd`，`mon`或`mds`。您可以使用来将运行时设置应用于特定类型的所有守护程序`*`，或指定特定守护程序的ID。例如，要增加对`ceph-osd`名为的守护程序的调试记录`osd.0`，请执行以下操作：

```
ceph tell osd.0 config set debug_osd 0/5
```

该`ceph tell`命令通过监视器。如果您无法绑定到监视器，则仍然可以通过使用来登录要更改的守护程序配置的主机，以进行更改`ceph daemon`。例如：

```
sudo ceph daemon osd.0 config set debug_osd 0/5
```

#### 启动时生效

要激活ceph的调试输出（*即*，`dout()`在启动的时候），你mustadd设置你的Ceph的配置文件。每个守护程序通用的子系统可以`[global]`在您的配置文件中设置。子系统forparticular守护程序在配置文件下的守护程序段设置（*例如*，`[mon]`，`[osd]`，`[mds]`）。例如：

```
[global]
        debug ms = 1/5
 
[mon]
        debug mon = 20
        debug paxos = 1/5
        debug auth = 2
 
[osd]
        debug osd = 1/5
        debug filestore = 1/5
        debug journal = 1
        debug monc = 5/20
 
[mds]
        debug mds = 1
        debug mds balancer = 1
```

#### 加速日志轮换

如果您的OS磁盘相对较满，则可以通过在处修改Ceph日志轮换文件来加速日志轮换`/etc/logrotate.d/ceph`。如果您的日志超过了大小设置，请在旋转频率之后添加一个大小设置以加速日志旋转（通过cronjob）。例如，默认设置如下所示：

```
rotate 7
weekly
compress
sharedscripts
```

通过添加`size`设置对其进行修改。

```
rotate 7
weekly
size 500M
compress
sharedscripts
```

### MON节点故障

[官方参考](https://www.bookstack.cn/read/ceph-en/fb1a8e4f7df47d5e.md)

#### 最常见的监视器问题

##### 拥有法定人数，但至少有一台监视器已关闭

发生这种情况时，根据您所运行的Ceph的版本，您应该会看到类似以下内容的内容：

```
$ ceph health detail
[snip]
mon.a (rank 0) addr 127.0.0.1:6789/0 is down (out of quorum)
```

如何解决这个问题？

> ```
> 首先，确保mon.a正在运行。
> 
> 其次，请确保您能够mon.a从其他显示器的服务器连接到“服务器”。还要检查端口。检查iptables所有监视器节点，并确保您没有断开/拒绝连接。
> 
> 如果最初的疑难解答无法解决您的问题，那么该更深入了。
> 
> 首先，mon_status按照使用监视器的管理套接字和了解mon_status中的说明，通过adminsocket检查有问题的监视器。
> 
> 考虑到监控器是仲裁的进行，它的状态应该是一个probing，electing或synchronizing。如果碰巧是leader或peon，则监视器认为是仲裁，而其余群集确定不是。也许是在我们对显示器进行故障排除时进入了法定人数，所以请ceph -s再次检查以确保。如果监视器尚未达到法定人数，请继续。
> ```

如果状态是`probing`什么呢？

```
这意味着该监视器仍在寻找其他监视器。每次启动监视器时，该监视器将在此状态下停留一段时间，同时尝试查找在中指定的其余监视器monmap。监视器在此状态下花费的时间可能会有所不同。例如，在一个单监视器群集上时，由于周围没有其他监视器，因此该监视器将几乎立即通过探测。在多监视器群集上，监视器将一直保持该状态，直到找到足够的监视器以形成仲裁为止–这意味着，如果您有3个监视器中有2个处于关闭状态，则剩下的一个监视器将无限期保持此状态，直到您将另一个监视器带入监视起来。

但是，如果达到法定人数，则只要可以访问监视器，监视器就应该能够很快找到其余的监视器。如果您的显示器一直处于探测状态，并且您已完成所有通信故障排除，则该显示器很可能会尝试通过错误的地址联系其他显示器。mon_status将monmap已知的信息输出到监视器：检查另一台监视器的位置是否与实际匹配。如果没有，请跳至“恢复监视器的损坏的monmap”；如果确实如此，则可能与监视器节点之间的严重时钟偏斜有关，您应该首先参考“时钟偏斜”，但是，如果这不能解决您的问题，那么现在是时候准备一些日志并联系社区了（请请参阅准备日志 如何最好地准备您的日志）。
```

如果状态是`electing`什么呢？

```
这意味着监控器正在选举中。这些应该很快完成，但有时监视器可能会卡住选择。这通常是监视节点之间时钟偏斜的迹象。跳转至Clock Skews以获得更多有关该信息。如果所有时钟都正确同步，则最好准备一些日志并联系社区。这不是一个可能会持续的状态，除了（确实）旧错误之外，除了时钟偏斜之外，没有明显的原因为什么会发生这种情况。
```

如果状态是`synchronizing`什么呢？

```
这意味着监视器正在与集群的其余部分进行同步，以加入仲裁。同步过程的速度与监视器存储区的较小速度一样快，因此，如果存储区较大，则可能需要一段时间。不用担心，它应该尽快完成。

但是，如果你注意到监视器从跳跃synchronizing到electing，然后回synchronizing，那么你必须aproblem：集群状态前进（即生成新地图）waytoo快速同步过程跟上。这在早期的墨鱼中曾经很流行，但是从那时起，同步过程就被大量重构和增强，从而避免了这种行为。如果这在以后的版本中发生，请告诉我们。并带上一些日志（请参阅准备日志）。
```

如果状态为`leader`或`peon`怎么办？

> ```
> 这不应该发生。但是，有可能会发生这种情况，这与时钟偏斜有很大关系-请参阅“时钟偏斜”。如果您不喜欢时钟偏斜，请准备您的日志（请参阅准备您的日志）并与我们联系。
> ```

##### 恢复监视器的损坏的monmap

这是`monmap`通常的样子，具体取决于监视器的数量：

```
epoch 3
fsid 5c4e9d53-e2e1-478a-8061-f543f8be4cf8
last_changed 2013-10-30 04:12:01.945629
created 2013-10-29 14:14:41.914786
0: 127.0.0.1:6789/0 mon.a
1: 127.0.0.1:6790/0 mon.b
2: 127.0.0.1:6795/0 mon.c
```

但是，这可能不是您所拥有的。例如，在早期的墨鱼的某些版本中，存在一个可能导致您`monmap`无效的错误。完全填充零。这意味着甚至`monmaptool`无法读取它，因为它将很难理解只有零的含义。在另一些时候，您可能会得到一个带有严重过时的monmap的监视器，从而无法找到剩余的`mon.c`监视器（例如，已关闭；添加一个新的监视器`mon.d`，然后删除`mon.a`，然后添加一个新的监视器`mon.e`并删除`mon.b`；您将结束与一个完全不同的monmap进行比较`mon.c`）。

在这种情况下，您有两种可能的解决方案

```
仅当您确定不会删除该监视器保留的信息时，才应采用此路线；您有其他监视器，并且它们运行良好，因此您的新监视器能够与其余监视器同步。请记住，销毁监视器（如果没有其内容的其他副本）可能会导致数据丢失。
```

将monmap注入监视器

```
通常是最安全的路径。您应该从其余的监视器中获取monmap，并将其与损坏/丢失的monmap一起注入到监视器中。

这些是基本步骤：

1.是否有法定人数？如果是这样，请从仲裁中获取monmap：

$ ceph mon getmap -o /tmp/monmap
2.没有法定人数？直接从另一台监视器获取monmap（假设您正在从中获取monmap的监视器具有ID ID-FOO并且已停止）：

$ ceph-mon -i ID-FOO —extract-monmap /tmp/monmap
3.停止将monmap注入到的监视器。

4.注入monmap：

$ ceph-mon -i ID —inject-monmap /tmp/monmap
5.启动显示器

请记住，注入monmap的功能是一项强大的功能，如果使用不当，可能会对显示器造成破坏，因为它将覆盖显示器保存的最新的现有monmap。
```





#### 时钟偏差

监视器可能会受到跨监视器节点的严重时钟偏差的严重影响。这通常转化为没有明显原因的奇怪行为。为避免此类问题，应在监视器节点上运行时钟同步工具。

容许的最大时钟偏差是多少？

```
默认情况下，监视器将允许时钟偏移到最大`0.05 seconds`。
```

我怎么知道有时钟偏斜？

```
监视器将以警告形式警告您HEALTH_WARN。ceph health detail应该以以下形式显示：
mon.c addr 10.10.0.1:6789/0 clock skew 0.08235s > max 0.05s (latency 0.0045s)
这意味着mon.c已将其标记为存在时钟偏斜。
```

如果出现时钟偏斜怎么办？

```
同步您的时钟。运行NTP客户端可能会有所帮助。如果您已经在使用一个NTP服务器，并且遇到了此类问题，请检查您是否正在使用某些NTP服务器远程访问网络，并考虑在您的网络上托管自己的NTP服务器。最后一个选项倾向于减少显示器时钟偏斜的问题。

apt-get install ntp -y
ntpdate ntp2.aliyun.com
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

#### 客户端无法连接或挂载

检查您的IP表。某些OS安装实用程序向中添加了一条`REJECT`规则`iptables`。该规则拒绝所有尝试连接到主机的客户端（除外）`ssh`。如果监视主机的IP表具有这样的`REJECT`规则，则从单独节点进行连接的客户端将无法挂载，并出现timeouterror。您需要解决`iptables`拒绝客户端尝试连接到Ceph守护程序的规则。例如，您需要适当地解决看起来像这样的规则：

```
REJECT all -- anywhere anywhere reject-with icmp-host-prohibited
```

您可能还需要向Ceph主机上的IP表添加规则，以确保客户端可以访问与Ceph监视器关联的端口（即默认情况下为端口6789）和Ceph OSD（即默认情况下为6800至7300）。例如：

```
iptables -A INPUT -m multiport -p tcp -s {ip-address}/{netmask} --dports 6789,6800:7300 -j ACCEPT
```

#### 监视器存储故障

##### 存储故障的征兆

Ceph监视器将[群集映射](https://www.bookstack.cn/read/ceph-en/78fd72266ec11255.md#term-cluster-map)存储在键/值存储（例如LevelDB）中。如果监视器由于键/值存储损坏而发生故障，则可能在监视器日志中找到以下错误消息：

```
Corruption: error in middle of record
```

或者：

```
Corruption: 1 missing files; e.g.: /var/lib/ceph/mon/mon.foo/store.db/1234567.ldb
```

##### 使用健康监视器进行恢复

如果有幸存者，我们总是可以用新的幸存者来[代替](https://www.bookstack.cn/read/ceph-en/91114f8e7d1be438.md#adding-and-removing-monitors)。启动后，新加入者将与健康对等者同步，一旦完全同步，便可以为客户提供服务。

##### 使用OSD恢复

但是，如果所有监视器都同时出现故障怎么办？由于鼓励用户在Ceph群集中部署至少三台（最好是五台）监视器，因此同时发生故障的机会很少。但是，如果磁盘/ fs设置配置不正确，数据中心的计划外关机可能会使基础文件系统失效，从而杀死所有监视器。在这种情况下，我们可以使用存储在OSD中的信息来恢复监视器存储。

```
ms=/root/mon-store
mkdir $ms
 
# collect the cluster map from stopped OSDs
for host in $hosts; do
  rsync -avz $ms/. user@$host:$ms.remote
  rm -rf $ms
  ssh user@$host <<EOF
    for osd in /var/lib/ceph/osd/ceph-*; do
      ceph-objectstore-tool --data-path \$osd --no-mon-config --op update-mon-db --mon-store-path $ms.remote
    done
EOF
  rsync -avz user@$host:$ms.remote/. $ms
done
 
# rebuild the monitor store from the collected map, if the cluster does not
# use cephx authentication, we can skip the following steps to update the
# keyring with the caps, and there is no need to pass the "--keyring" option.
# i.e. just use "ceph-monstore-tool $ms rebuild" instead
ceph-authtool /path/to/admin.keyring -n mon. \
  --cap mon 'allow *'
ceph-authtool /path/to/admin.keyring -n client.admin \
  --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *'
ceph-monstore-tool $ms rebuild -- --keyring /path/to/admin.keyring
 
# make a backup of the corrupted store.db just in case!  repeat for
# all monitors.
mv /var/lib/ceph/mon/mon.foo/store.db /var/lib/ceph/mon/mon.foo/store.db.corrupted
 
# move rebuild store.db into place.  repeat for all monitors.
mv $ms/store.db /var/lib/ceph/mon/mon.foo/store.db
chown -R ceph:ceph /var/lib/ceph/mon/mon.foo/store.db
```

以上步骤

- 从所有OSD主机收集map，
- 然后重建储存
- 用适当的上限填充密钥环文件中的实体
- 用`mon.foo`恢复的副本替换损坏的存储。

##### 已知限制

使用上述步骤无法恢复以下信息：

- **一些添加的密钥环**：使用命令添加的所有OSD密钥环均已`ceph auth add`从OSD的副本中恢复。并使用`client.admin`导入密钥环`ceph-monstore-tool`。但是，MDS密钥环和其他密钥环在恢复的监视器存储中丢失。您可能需要手动重新添加它们。
- **创建池**：如果正在创建任何RADOS池，则该状态将丢失。恢复工具假定已创建所有池。如果部分创建的池恢复后有PG卡在“未知”中，则可以使用命令强制创建*空*PG `ceph osd force-create-pg`。请注意，这将创建一个*空的*PG，因此仅当您知道该池为空时，才执行此操作。
- **MDS映射**：MDS映射丢失。

#### 一切都失败了！怎么办？

##### 伸出援助之手

您可以在#ceph和＃ceph-devel的在OFTC（服务器irc.oftc.net）和上找到我们在IRC`ceph-devel@vger.kernel.org`和`ceph-users@lists.ceph.com`。确保您已抓取日志并在有人询问时准备好日志：交互速度越快，响应延迟越短，每个人的时间被优化的机会就越大。

##### 准备日志

默认情况下，监视器日志保存在中`/var/log/ceph/ceph-mon.FOO.log*`。我们可能想要他们。但是，您的日志可能没有必要的信息。如果找不到监视日志的默认位置，则可以通过运行以下命令检查监视日志的位置：

```
ceph-conf --name mon.FOO --show-config-value log_file
```

日志中的信息量取决于配置文件强制执行的调试级别。如果您没有强制执行特定的调试级别，则Ceph使用默认级别，并且您的日志可能不包含跟踪您的问题的重要信息。将相关信息纳入日志的第一步是提高调试级别。在这种情况下，我们会对来自监视器的信息感兴趣。与其他组件发生的情况类似，监视器的不同部分将在不同的子系统上输出其调试信息。

您将不得不提高与您的问题密切相关的那些子系统的调试级别。对于不熟悉Ceph故障排除的人来说，这可能不是一件容易的事。在大多数情况下，在监视器上设置以下选项就足以找出问题的潜在根源：

```
debug mon = 10
debug ms = 1
```

如果我们发现这些调试级别还不够，那么我们可能会要求您提高调试级别，甚至可能定义其他调试子系统来从中获取信息-但至少我们从一些有用的信息开始，而不是大量的空日志而无所事事继续。

##### 我是否需要重新启动监视器以调整调试级别？

不可以。您可以通过以下两种方式之一进行操作：

你有法定人数

```
将debug选项注入到要调试的监视器中：

ceph tell mon.FOO config set debug_mon 10/10
或一次进入所有监视器：

ceph tell mon.* config set debug_mon 10/10
```

没有法定人数

```
使用监视器的管理套接字并直接调整配置选项：

ceph daemon mon.FOO config set debug_mon 10/10
```

返回默认值就像使用调试级别重新运行上述命令一样容易`1/10`。您可以使用管理套接字和以下命令来检查当前值：

```
ceph daemon mon.FOO config show
```

or:

```
ceph daemon mon.FOO config get 'OPTION_NAME'
```

##### 重现了具有适当调试级别的问题。怎么办？

理想情况下，您只将日志的相关部分发送给我们。我们意识到弄清相应部分可能不是最简单的任务。因此，如果您提供完整的日志，我们不会保留给您，但应使用常识。如果您的日志有成千上万的行，那么遍历整个过程可能会比较棘手，特别是如果我们不知道在哪一点发生了什么问题。例如，在复制时，请记住写下当前的时间和日期，并据此提取日志的相关部分。

最后，您应该在邮件列表，IRC上找到我们，或者在[Tracker](http://tracker.ceph.com/projects/ceph/issues/new)上提出新问题。



### 对OSD进行故障排除

在对OSD进行故障排除之前，请先检查显示器和网络。如果您执行`ceph health`或`ceph -s`在命令行上执行并且Ceph返回健康状态，则表示监视器具有法定人数。如果您没有监视器法定人数或MonitorStatus出现错误，请首先[解决监视器问题](https://www.bookstack.cn/read/ceph-en/fb1a8e4f7df47d5e.md)。确保网络正常运行，因为网络可能会对OSD的运行和性能产生重大影响。

#### 获取有关OSD的数据

对OSD进行故障排除的一个很好的第一步是在[监视OSD时](https://www.bookstack.cn/read/ceph-en/a04e9208413f2a01.md)（例如`ceph osd tree`）获得除您收集的信息之外的信息。

#### Ceph日志

如果您尚未更改默认路径，则可以在`/var/log/ceph`以下位置找到Ceph日志文件：

```
ls /var/log/ceph
```

如果没有足够的日志详细信息，则可以更改日志记录级别。有关详细信息，请参阅[日志记录和调试](https://www.bookstack.cn/read/ceph-en/7b7e247b0ffd58dd.md)，以确保Ceph在高日志记录量下能够充分发挥性能。

#### 管理员套接字

使用管理套接字工具检索运行时信息。有关详细信息，请列出您的Ceph进程的套接字：

```
ls /var/run/ceph
```

然后，执行以下命令，替换`{daemon-name}`为实际的守护程序（例如`osd.0`）：

```
ceph daemon osd.0 help
```

另外，您可以指定一个`{socket-file}`（例如`/var/run/ceph`）。

```
ceph daemon {socket-file} help
```

管理员套接字，除其他外，使您可以：

- List your configuration at runtime
- Dump historic operations
- Dump the operation priority queue state
- Dump operations in flight
- Dump perfcounters

#### 显示剩余空间

可能会出现文件系统问题。要显示文件系统的可用空间，请执行`df`。

```
df -h
```

执行`df —help`其他用途。

#### I / O统计

使用[iostat](https://en.wikipedia.org/wiki/Iostat)可以识别与I / O相关的问题。

```
iostat - x
```

#### 诊断信息

要获取诊断信息，使用`dmesg`与`less`，`more`，`grep`或`tail`。例如：

```
dmesg | grep scsi
```

#### 停止w/out重平衡

您可能需要定期对群集的子集执行维护，或解决影响故障域（例如机架）的问题。如果您不希望CRUSH在停止OSD维护时自动重新平衡群集，请将群集设置为`noout`first：

```
ceph osd set noout
```

一旦将群集设置为`noout`，您就可以开始在需要维护工作的故障域内停止OSD。

```
stop ceph-osd id={num}
```

注意：

解决故障域内的问题时，您停止的OSD内的放置组将变为degraded。

完成维护后，请重新启动OSD。

```
start ceph-osd id={num}
```

最后，您必须从取消设置集群`noout`。

```
ceph osd unset noout
```

#### OSD未运行

在正常情况下，只需重新启动`ceph-osd`守护程序，它将允许它重新加入集群并进行恢复。

#### OSD无法启动

如果启动群集，但OSD无法启动，请检查以下内容：

- **配置文件：**如果无法从新安装中运行OSD，请检查您的配置文件以确保其符合要求（例如，`host`不兼容`hostname`，等等）。
- **检查路径：**检查配置中的路径，以及数据和日志的实际路径本身。如果将OSD数据与日志数据分开，并且配置文件或实际安装中有错误，则可能无法启动OSD。如果要将期刊存储在块设备上，则应对日志磁盘进行分区，并为每个OSD分配一个分区。
- **检查最大线程数：**如果您的节点上有很多OSD，则可能会打出默认的最大线程数（例如通常为32k），特别是在恢复过程中。您可以使用来增加线程`sysctl`数，以查看将最大线程数增加到允许的最大可能线程数（即4194303）是否有帮助。例如：

```
sysctl -w kernel.pid_max=4194303
```

如果增加最大线程数可以解决该问题，则可以通过`kernel.pid_max`在`/etc/sysctl.conf`文件中包含一个设置来使其永久存在。例如：

```
kernel.pid_max = 4194303
```

- **内核版本：**确定您使用的内核版本和发行版。默认情况下，Ceph使用某些第三方工具，这些工具可能有些混乱，或与某些发行版和/或内核版本冲突（例如Google perftools）。检查[操作系统建议，](https://www.bookstack.cn/read/ceph-en/5cacb5a75c6206d7.md)以确保您已解决与内核有关的所有问题。
- **网段故障：**如果存在网段故障，请打开日志记录（如果尚未记录），然后重试。如果再次细分故障，请与ceph-devel电子邮件列表联系，并提供您的Ceph配置文件，监视器输出和日志文件的内容。

#### OSD失败

当`ceph-osd`进程终止时，监视器将从存活的`ceph-osd`守护程序中了解故障，并通过以下`ceph health`命令进行报告：

```
ceph health
HEALTH_WARN 1/3 in osds are down
```

具体来说，只要有`ceph-osd`标记为`in`和的进程，您都会收到警告`down`。您可以识别哪些`ceph-osds`是`down`有：

```
ceph health detail
HEALTH_WARN 1/3 in osds are down
osd.0 is down since epoch 23, last address 192.168.106.220:6800/11080
```

如果存在磁盘故障或其他`ceph-osd`无法正常运行或无法重新启动的故障，则其日志文件中的错误消息应该出现在中`/var/log/ceph`。

如果守护程序由于心跳失败而停止，则底层内核文件系统可能无响应。检查`dmesg`输出是否存在磁盘或其他内核错误。

如果问题是软件错误（断言失败或其他意外错误），则应将其报告给ceph [-devel](https://docs.ceph.com/docs/master/rados/troubleshooting/troubleshooting-osd/mailto:ceph-devel%40vger.kernel.org)电子邮件列表。

#### 没有可用的驱动器空间

Ceph会阻止您写入完整的OSD，以免丢失数据。在可操作的群集中，当群集接近其完整容量时，您应该收到警告。的`mon osd full ratio`默认为`0.95`，或容量的95％之前，停止从写入data.The客户`mon osd backfillfull ratio`默认为`0.90`，或90％时阻止启动它的块回填。OSD接近健康比率`0.85`生成健康警告时，默认为或容量的85％。

更改它可以使用：

```
ceph osd set-nearfull-ratio <float[0.0-1.0]>
```

当测试Ceph如何在小型群集上处理OSDfailure时，通常会出现群集满的问题。当一个节点占集群数据的百分比很高时，集群可以轻易地使其接近全满和全满的比例黯然失色。如果你在一个小集群测试如何Ceph的起反应对OSD失败，您应保留足够的可用磁盘空间，并考虑暂时降低的OSD `full ratio`，OSD `backfillfull ratio`和OSD`nearfull ratio`使用以下命令：

```
ceph osd set-nearfull-ratio <float[0.0-1.0]>
ceph osd set-full-ratio <float[0.0-1.0]>
ceph osd set-backfillfull-ratio <float[0.0-1.0]>
```

满的`ceph-osds`将由以下人员报告`ceph health`：

```
ceph health
HEALTH_WARN 1 nearfull osd(s)
```

或者：

```
ceph health detail
HEALTH_ERR 1 full osd(s); 1 backfillfull osd(s); 1 nearfull osd(s)
osd.3 is full at 97%
osd.4 is backfill full at 91%
osd.2 is near full at 87%
```

处理整个集群的最佳方法是添加new `ceph-osds`，从而使集群可以将数据重新分配到新的可用存储中。

如果由于OSD已满而无法启动OSD，则可以通过删除完整OSD中的某些放置组目录来删除某些数据。

重要的

如果您选择删除完整OSD上的放置组目录，请**不要**删除另一个完整OSD上的相同放置组目录，否则，**您可能会丢失DATA**。您**必须**在至少一个OSD上维护至少一个数据副本。

有关其他详细信息，请参见《[Monitor Config Reference](https://www.bookstack.cn/read/ceph-en/d67c50086882a284.md)》。

#### OSD缓慢/无响应

经常发生的问题涉及OSD缓慢或无响应。在研究OSD性能问题之前，请确保您已经消除了其他疑难解答的可能性。例如，确保您的网络正常运行并且OSD正在运行。检查OSD是否限制了恢复流量。

提示

较新版本的Ceph通过防止恢复OSD消耗系统资源来提供更好的恢复处理，从而使OSD`up`和`in`OSD不可用或变慢。

#### 网络问题

Ceph是一个分布式存储系统，因此它依赖于网络与OSD对等，复制对象，从故障中恢复并检查心跳。网络问题可能会导致OSD延迟和OSD波动。有关详细信息，请参见[拍打OSD](https://www.bookstack.cn/read/ceph-en/7bd7346c8207ec58.md#flapping-osds)。

确保Ceph进程和依赖于Ceph的进程已连接和/或侦听。

```
netstat -a | grep ceph
netstat -l | grep ceph
sudo netstat -p | grep ceph
```

检查网络统计信息。

```
netstat -s
```

#### 驱动器配置

一个存储驱动器应仅支持一个OSD。如果其他进程共享驱动器，则顺序读取和顺序写入吞吐量可能会成为瓶颈，包括日志，操作系统，监视器，其他OSD和非Ceph进程。

Ceph会*在*记录日志*后*确认写入，因此快速的SSD是缩短响应时间（特别是在使用`XFS`or或`ext4`文件系统时）的吸引人的选择。相比之下，`btrfs`文件系统可以同时写入和记录日志。（但是请注意，我们建议您不要将其`btrfs`用于生产部署。）

注意：

对驱动器进行分区不会更改其总吞吐量或顺序的读/写限制。在单独的分区中运行日志可能会有所帮助，但是您应该首选单独的物理驱动器。

#### 坏扇区/磁盘碎片

检查磁盘是否有坏扇区和碎片。这可能会导致总吞吐量大幅下降。

#### 同一个主机运行监视器/ OSD

监视器通常是轻量级进程，但是它们会做很多事情`fsync()`，这可能会干扰其他工作负载，尤其是如果监视器在与OSD相同的驱动器上运行。此外，如果在与OSD相同的主机上运行监视器，则可能会引起与以下问题有关的性能问题：

- 运行较旧的内核（3.0之前的版本）
- 运行没有syncfs（2）syscall的内核。

在这些情况下，在同一主机上运行的多个OSD可能会因进行大量提交而相互拖累。这通常会导致突发写入。

#### 共同驻留流程

加速共存流程，例如基于云的解决方案，虚拟机和其他在与OSD相同的硬件上运行时将数据写入Ceph的应用程序，可能会导致显着的OSD延迟。通常，建议优化主机以与Ceph一起使用，并为其他进程使用其他主机。将Ceph操作与其他应用程序分离的做法可能有助于提高性能，并简化故障排除和维护。

#### 记录级别

如果您将日志记录级别调高以跟踪问题，然后又忘记调低日志记录级别，则OSD可能会将大量日志放到磁盘上。如果您打算保持较高的日志记录级别，则可以考虑将驱动器安装到默认的日志记录路径（即`/var/log/ceph/$cluster-$name.log`）。

#### 恢复节流

根据您的配置，Ceph可能会降低恢复率以保持性能，或者可能将恢复率提高到影响OSD性能的程度。检查OSD是否正在恢复。

#### 内核版本

检查您正在运行的内核版本。较旧的内核可能不会收到Ceph依赖于更高性能的新反向端口。

#### SyncFS的内核问题

尝试每台主机运行一个OSD，以查看性能是否有所提高。旧的内核可能没有足够的最新版本`glibc`来支持`syncfs(2)`。

#### 文件系统问题

当前，我们建议使用XFS部署群集。

我们建议不要使用btrfs或ext4。btrfs文件系统具有许多吸引人的功能，但是文件系统中的错误可能会导致性能问题和虚假的ENOSPC错误。我们不建议使用ext4，因为xattr大小限制会破坏我们对长对象名的支持（RGW需要）。

有关更多信息，请参见[文件系统建议](https://docs.ceph.com/docs/master/rados/troubleshooting/configuration/filesystem-recommendations)。

#### RAM不足

我们建议每个OSD守护程序1GB的RAM。您可能会注意到，在正常操作期间，OSD仅使用该数量的一小部分（例如100-200MB）。未使用的RAM倾向于将多余的RAM用于共同驻留的应用程序，VM等。但是，当OSD进入恢复模式时，其内存利用率会飙升。如果没有可用的RAM，则OSD性能将大大降低。

#### 旧请求或慢请求

如果`ceph-osd`守护程序对请求的响应速度很慢，它将生成日志消息，抱怨耗时太长的请求。警告阈值默认为30秒，可以通过该`osd op complaint time`选项进行配置。发生这种情况时，群集日志将接收消息。

旧版Ceph抱怨`old requests`：

```
osd.0 192.168.106.220:6800/18813 312 : [WRN] old request osd_op(client.5099.0:790 fatty_26485_object789 [write 0~4096] 2.5e54f643) v4 received at 2012-03-06 15:42:56.054801 currently waiting for sub ops
```

新版本的Ceph抱怨`slow requests`：

```
{date} {osd.num} [WRN] 1 slow requests, 1 included below; oldest blocked for > 30.005692 secs
{date} {osd.num}  [WRN] slow request 30.005692 seconds old, received at {date-time}: osd_op(client.4240.0:8 benchmark_data_ceph-1_39426_object7 [write 0~4194304] 0.69848840) v4 currently waiting for subops from [610]
```

可能的原因包括：

- 驱动器损坏（检查`dmesg`输出）
- 内核文件系统中的错误（检查`dmesg`输出）
- 集群过载（检查系统负载，iostat等）
- `ceph-osd`守护程序中的错误。

可能的解决方案：

- 从Ceph主机中删除VM
- 升级内核
- 升级Ceph
- 重新启动OSD

#### 调试慢请求

如果您运行`ceph daemon osd.<id> dump_historic_ops`或`ceph daemon osd.<id> dump_ops_in_flight`，您将看到一组操作以及每个操作经历的事件列表。这些将在下面简要描述。

Messenger层中的事件：

- `header_read`：当Messenger第一次开始从网络上读取消息时。
- `throttled`：当Messenger尝试获取内存节流空间以将消息读入内存时。
- `all_read`：当Messenger完成从有线方式读取消息时。
- `dispatched`：当Messenger将消息发送给OSD时。
- `initiated`：等同于`header_read`。两者的存在是历史的古怪。

OSD准备操作时的事件：

- `queued_for_pg`：操作已由其PG放入队列进行处理。
- `reached_pg`：PG已开始执行操作。
- `waiting for *`：操作在继续进行之前正在等待其他工作完成（例如，新的OSDMap；要擦洗其对象目标；要求PG完成对等；所有消息中均已指定）。
- `started`：该操作已被OSD接受并正在执行。
- `waiting for subops from`：操作已发送到副本OSD。

FileStore中的事件：

- `commit_queued_for_journal_write`：操作已分配给FileStore。
- `write_thread_in_journal_buffer`：操作位于日志的缓冲区中并等待被保留（作为下一个磁盘写入操作）。
- `journaled_completion_queued`：将操作记录在磁盘上，并将其回调排队以进行调用。

将东西分配给本地磁盘后，来自OSD的事件：

- `op_commit`：操作已由主OSD提交（即写入日志）。
- `op_applied`：op已被[写（）'en](https://www.freebsd.org/cgi/man.cgi?write(2)）到主服务器上的后备FS（即应用于内存，但未刷新到磁盘）。
- `sub_op_applied`：`op_applied`，但适用于副本的“子操作”。
- `sub_op_committed`：`op_commit`，但适用于副本的子操作（仅适用于EC池）。
- `sub_op_commit_rec/sub_op_apply_rec from <X>`：当想到以上内容时，主服务器对此进行了标记，但针对特定的副本（即`<X>`）。
- `commit_sent`：我们已将回复发送回客户端（或主OSD，用于子操作）。

这些事件中的许多事件似乎都是多余的，但是它们跨越了内部代码中的重要边界（例如，将数据跨锁传递到新线程中）。

#### 拍打OSD

我们建议同时使用公共（前端）网络和群集（后端）网络，以便更好地满足对象复制的容量要求。另一个优点是，您可以运行一个群集网络，使其不连接到Internet，从而防止某些服务攻击。当OSD对等并检查心跳时，他们会使用群集（后端）网络（如果可用）。有关详细信息，请参见[Monitor / OSD交互](https://www.bookstack.cn/read/ceph-en/feca5541349ecc5a.md)。

但是，如果群集（后端）网络发生故障或显着延迟，而公共（前端）网络运行最佳，则OSD当前无法很好地处理这种情况。发生的事情是OSD`down`在监视器上互相标记，同时对其进行标记`up`。我们称这种情况为“拍打”。

如果某种原因导致OSD发生“拍打”（反复被标记`down`然后`up`再次出现），则可以通过以下方法强制显示器停止拍打：

```
ceph osd set noup      # prevent OSDs from getting marked up
ceph osd set nodown    # prevent OSDs from getting marked down 复制代码
```

这些标志记录在osdmap结构中：

```
ceph osd dump | grep flags
flags no-up,no-down
```

您可以使用以下方法清除标志：

```
ceph osd unset noup
ceph osd unset nodown
```

还支持另外两个标记`noin`和`noout`，这两个标记防止引导OSD被标记`in`（分配的数据）或保护OSD最终不被标记`out`（无论当前值`mon osd down out interval`是什么）。

注意：

`noup`，，`noout`和`nodown`是临时的，因为一旦清除了这些标志，它们阻塞的操作应在不久之后发生。`noin`另一方面，该标志可防止OSD`in`在启动时被标记，并且在设置该标志时启动的所有守护程序都将保持这种状态。



### PG故障排除

#### 归置组永远无法Clean

当你创建一个集群，集群任然`active`，`active+remapped`或`active+degraded`状态，从来没有达到的`active+clean`状态，你可能有你的配置有问题。

您可能需要查看[Pool，PG和CRUSH Config Reference中的设置](https://www.bookstack.cn/read/ceph-en/cc293c0895c9dc02.md)并进行适当的调整。

通常，您应使用一个以上的OSD和大于1个对象副本的缓冲池大小来运行群集。

#### 一个节点集群

Ceph不再提供有关在单个节点上运行的文档，因为您永远不会在单个节点上部署专为分布式计算而设计的系统。此外，由于Linux内核本身存在问题（除非您将VM用于客户端），在包含ceph守护程序的单个节点上安装客户端内核模块可能会导致死锁。尽管有此处描述的限制，您仍可以在1节点配置中使用Ceph进行实验。

如果您尝试在单个节点上创建集群，则必须在创建监视器和OSD之前将Ceph配置文件中`osd crush chooseleaf type`设置的默认值从`1`（含义`host`或`node`）更改为`0`（含义`osd`）。这告诉Ceph，一个OSD可以与同一主机上的另一个OSD对等。如果您尝试设置一个`osd crush chooseleaf type`大于1的节点群集，则`0`Ceph将尝试根据设置将一个OSD的PG与另一个OSD的PG对等连接到另一个节点，机架，机架，行甚至数据中心上。

提示：

不要将内核客户端直接安装在与你的Ceph Storage Cluster相同的节点上，因为会引起内核冲突。但是，您可以在单个节点上的虚拟机（VM）中挂载内核客户端。

如果要使用单个磁盘创建OSD，则必须首先手动为数据创建目录。例如：

```
ceph-deploy osd create --data {disk} {host}
```

#### OSD比副本少

如果您将两个OSD调到`up`和`in`状态，但仍看不到`active + clean`展示位置组，则可以将其`osd pool default size`设置为大于`2`。

有几种方法可以解决这种情况。如果要在`active + degraded`具有两个副本的状态下操作集群，可以将设置为`osd pool default min size`，`2`以便可以在`active + degraded`状态下写入对象。您也可以将`osd pool default size`设置设置为，`2`以便只有两个存储的副本（原始副本和一个副本），在这种情况下，群集应达到某种`active + clean`状态。

注意：

您可以在运行时进行更改。如果您在Ceph配置文件中进行更改，则可能需要重新启动集群。

#### 池大小= 1

如果将`osd pool default size`设置为`1`，则将只有该对象的一个副本。OSD依靠其他OSD来告诉他们它们应该拥有哪些对象。如果第一个OSD具有对象的副本，并且没有第二个副本，则没有第二个OSD可以告诉第一个OSD它应该具有该副本。对于映射到第一个OSD的每个放置组（请参阅`ceph pg dump`参考资料），您可以通过运行以下命令来强制第一个OSD注意到其所需的放置组：

```
ceph osd force-create-pg <pgid>
```

#### CRUSH Map错误

另一个放置组unclean的候选对象涉及您的CRUSH map中的错误。

#### 卡住的放置组

放置组在失败后进入“降级”或“对等”状态是正常的。通常，这些状态指示故障恢复过程中的正常进程。但是，如果放置组长时间处于这些状态之一，则可能表示存在较大问题。因此，当放置组“卡在”非最佳状态时，监视器将发出警告。具体来说，我们检查以下内容：

- `inactive`-归置组`active`的时间过长（即，它无法处理读/写请求）。
- `unclean`-归置组`clean`的时间过长（即，它无法从以前的故障中完全恢复过来）。
- `stale`-归置组状态尚未`ceph-osd`用来更新，表示存储此放置组的所有节点都可能是`down`。

您可以使用以下其中一项明确列出卡住的展示位置组：

```
ceph pg dump_stuck stale
ceph pg dump_stuck inactive
ceph pg dump_stuck unclean
```

对于卡住的`stale`放置组，通常需要`ceph-osd`重新运行正确的守护程序。对于卡住的`inactive`展示位置组，通常是一个对等的问题（请参见“[关闭展示位置组-对等失败”](https://www.bookstack.cn/read/ceph-en/76a941150c027aa5.md#failures-osd-peering)）。对于Forstuck`unclean`放置组，通常会有一些阻碍恢复完成的事情，例如未找到的对象（请参阅[Unfound Objects](https://www.bookstack.cn/read/ceph-en/76a941150c027aa5.md#failures-osd-unfound)）；

#### 归置置组向下-对等失败

在某些情况下，对`ceph-osd` *等*进程可能会遇到问题，从而阻止PG变得活跃和可用。例如，`ceph health`可能报告：

```
ceph health detail
HEALTH_ERR 7 pgs degraded; 12 pgs down; 12 pgs peering; 1 pgs recovering; 6 pgs stuck unclean; 114/3300 degraded (3.455%); 1/3 in osds are down
...
pg 0.5 is down+peering
pg 1.4 is down+peering
...
osd.1 is down since epoch 69, last address 192.168.106.220:6801/8651
```

我们可以查询集群以确定PG为何正确标记`down`为：

```
ceph pg 0.5 query
```

```
{ "state": "down+peering",
  ...
  "recovery_state": [
       { "name": "Started\/Primary\/Peering\/GetInfo",
         "enter_time": "2012-03-06 14:40:16.169679",
         "requested_info_from": []},
       { "name": "Started\/Primary\/Peering",
         "enter_time": "2012-03-06 14:40:16.169659",
         "probing_osds": [
               0,
               1],
         "blocked": "peering is blocked due to down osds",
         "down_osds_we_would_probe": [
               1],
         "peering_blocked_by": [
               { "osd": 1,
                 "current_lost_at": 0,
                 "comment": "starting or marking this osd lost may let us proceed"}]},
       { "name": "Started",
         "enter_time": "2012-03-06 14:40:16.169513"}
   ]
}
```

`recovery_state`段告诉我们，由于down`ceph-osd`守护程序（特别是），对等已被阻止`osd.1`。在这种情况下，我们可以重新开始，`ceph-osd`一切都会恢复。

或者，如果发生灾难性故障`osd.1`（例如，磁盘故障），我们可以告诉集群它是，`lost`并尽可能地应对。

重要的

这很危险，因为群集无法保证数据的其他副本是一致的和最新的。

要指示Ceph继续进行操作，请执行以下操作：

```
ceph osd lost 1
```

恢复将继续。

在某些失败组合下，Ceph可能会抱怨以下问题`unfound`：

```
ceph health detail
HEALTH_WARN 1 pgs degraded; 78/3778 unfound (2.065%)
pg 2.4 is active+degraded, 78 unfound
```

这意味着存储集群知道某些对象（或现有对象的较新副本）存在，但尚未找到它们的副本。对于数据位于ceph-osds1和2上的PG来说，这可能如何实现的一个示例：

- 1 goes down
- 2 handles some writes, alone
- 1 comes up
- 1 and 2 repeer, and the objects missing on 1 are queued for recovery.
- Before the new objects are copied, 2 goes down.

现在1知道这些对象存在，但是没有活着的`ceph-osd`人拥有副本。在这种情况下，这些对象的IO将被阻塞，集群将希望发生故障的节点很快回来；假定这比将IO错误返回给用户更好。

首先，您可以使用以下方法确定找不到哪些对象：

```
ceph pg 2.4 list_unfound [starting offset, in json]
```

```
{ "offset": { "oid": "",
     "key": "",
     "snapid": 0,
     "hash": 0,
     "max": 0},
 "num_missing": 0,
 "num_unfound": 0,
 "objects": [
    { "oid": "object 1",
      "key": "",
      "hash": 0,
      "max": 0 },
    ...
 ],
 "more": 0}
```

如果有太多对象无法在单个结果中列出，则该`more`字段为true，您可以查询更多。（最终，命令行工具会将其隐藏起来，但还没有。）

其次，您可以确定哪些OSD已被探测或可能包含数据：

```
ceph pg 2.4 query
```

```
"recovery_state": [
     { "name": "Started\/Primary\/Active",
       "enter_time": "2012-03-06 15:15:46.713212",
       "might_have_unfound": [
             { "osd": 1,
               "status": "osd is down"}]},
```

例如，在这种情况下，集群知道`osd.1`可能有数据，但它是`down`。可能的状态的完整范围包括：

- already probed
- querying
- OSD is down
- not queried (yet)

有时，集群查询可能的位置只需要花费一些时间。

有可能存在对象未列出的其他位置。例如，如果停止了ceph-osd并将其从群集中取出，群集将完全恢复，并且由于某些将来的故障集会导致找不到对象，因此它不会考虑将已久的ceph-osd视为潜在位置考虑。（但是，这种情况不太可能。）

如果查询了所有可能的位置并且仍然丢失了对象，则可能必须放弃丢失的对象。同样，如果出现异常的异常组合，则这是可能的，该异常组合使群集可以了解恢复写本身之前执行的写操作。要将“未找到”的对象标记为“丢失”：

```
ceph pg 2.5 mark_unfound_lost revert|delete
```

这最后一个参数指定群集应如何处理丢失的对象。

“删除”选项将完全忘记它们。

“还原”选项（不适用于擦除编码池）将回滚到该对象的先前版本，或者（如果它是新对象）将完全忘记它。请谨慎使用此选项，因为它可能会使期望该对象存在的应用程序感到困惑。

#### 无家可归的归置组

具有给定放置组副本的所有OSD都有可能失败，如果是这种情况，则对象存储的该子集不可用，并且监视器将不会收到那些放置组的状态更新。为了检测到这种情况，监视器将其主OSD失败的所有放置组标记为`stale`。例如：

```
ceph health
HEALTH_WARN 24 pgs stale; 3/300 in osds are down
```

您可以通过以下方式确定哪些展示位置组是`stale`，以及存储它们的最后一个OSD：

```
ceph health detail
HEALTH_WARN 24 pgs stale; 3/300 in osds are down
...
pg 2.5 is stuck stale+active+remapped, last acting [2,0]
...
osd.10 is down since epoch 23, last address 192.168.106.220:6800/11080
osd.11 is down since epoch 13, last address 192.168.106.220:6803/11539
osd.12 is down since epoch 24, last address 192.168.106.220:6806/11861
```

例如，如果我们要使pg2.5重新在线，则可以告诉我们该归置组是由`osd.0`和最终管理的`osd.2`。重新启动这些`ceph-osd`守护程序将使集群可以恢复该放置组（可能还有许多其他）。

#### 只有少数OSD接收数据

如果群集中有许多节点，而只有少数几个节点接收数据，[请检查](https://www.bookstack.cn/read/ceph-en/4bc7afaecb4c1c71.md#get-the-number-of-placement-groups)池中的放置组数。由于放置组已映射到OSD，因此少数放置组将不会在整个群集中分布。尝试创建一个放置组计数为OSD数量倍数的池。有关详情，请参见[展示位置组](https://www.bookstack.cn/read/ceph-en/4bc7afaecb4c1c71.md)。池的默认放置组计数没有用，但是您可以[在此处](https://www.bookstack.cn/read/ceph-en/cc293c0895c9dc02.md)更改它。

#### 不能写数据

如果您的群集已启动，但某些OSD已关闭并且您无法写入数据，请检查以确保为该放置组运行的OSD数量最少。如果您没有运行最小数量的OSD，Ceph将不允许您写入数据，因为不能保证Ceph可以复制您的数据。有关详细信息[，](https://www.bookstack.cn/read/ceph-en/cc293c0895c9dc02.md)请参见`osd pool default min size`“[池，PG和CRUSH配置参考](https://www.bookstack.cn/read/ceph-en/cc293c0895c9dc02.md)”。

#### PG不一致

如果收到`active + clean + inconsistent`状态，则可能是由于擦洗过程中发生错误而导致的。与往常一样，我们可以通过以下方式识别不一致的组：

```
$ ceph health detail
HEALTH_ERR 1 pgs inconsistent; 2 scrub errors
pg 0.6 is active+clean+inconsistent, acting [0,1,2]
2 scrub errors
```

或者，如果您更喜欢以编程方式检查输出，请执行以下操作：

```
$ rados list-inconsistent-pg rbd
["0.6"]
```

只有一个一致的状态，但是在最坏的情况下，我们可能会在多个对象中发现的多个视角存在不同的不一致。如果`foo`PG中命名的对象`0.6`被截断，我们将有：

```
$ rados list-inconsistent-obj 0.6 --format=json-pretty
```

```
{
    "epoch": 14,
    "inconsistents": [
        {
            "object": {
                "name": "foo",
                "nspace": "",
                "locator": "",
                "snap": "head",
                "version": 1
            },
            "errors": [
                "data_digest_mismatch",
                "size_mismatch"
            ],
            "union_shard_errors": [
                "data_digest_mismatch_info",
                "size_mismatch_info"
            ],
            "selected_object_info": "0:602f83fe:::foo:head(16'1 client.4110.0:1 dirty|data_digest|omap_digest s 968 uv 1 dd e978e67f od ffffffff alloc_hint [0 0 0])",
            "shards": [
                {
                    "osd": 0,
                    "errors": [],
                    "size": 968,
                    "omap_digest": "0xffffffff",
                    "data_digest": "0xe978e67f"
                },
                {
                    "osd": 1,
                    "errors": [],
                    "size": 968,
                    "omap_digest": "0xffffffff",
                    "data_digest": "0xe978e67f"
                },
                {
                    "osd": 2,
                    "errors": [
                        "data_digest_mismatch_info",
                        "size_mismatch_info"
                    ],
                    "size": 0,
                    "omap_digest": "0xffffffff",
                    "data_digest": "0xffffffff"
                }
            ]
        }
    ]
}
```

在这种情况下，我们可以从输出中学习：

- 唯一不一致的对象称为`foo`，并且它的头部存在不一致。
- 不一致分为两类：
  - `errors`：这些错误表示分片之间的不一致，而没有确定哪个分片不好。检查`errors`分*片*数组中的（如果有），以查明问题所在。
    - `data_digest_mismatch`：从OSD.2读取的副本的摘要与OSD.0和OSD.1的摘要不同
    - `size_mismatch`：从OSD.2读取的副本的大小为0，而OSD.0和OSD.1报告的大小为968。
  - `union_shard_errors`：数组中所有特定分片的`errors`并集`shards`。在`errors`对于给定碎片有theproblem设置。它们包括类似的错误`read_error`。在`errors`结束的`oi`指示与比较`selected_object_info`。查看`shards`阵列以确定哪个分片具有哪个错误。
    - `data_digest_mismatch_info`：存储在对象信息中的摘要不是`0xffffffff`，这是根据从OSD.2读取的分片计算得出的
    - `size_mismatch_info`：存储在对象信息中的大小与从OSD.2读取的大小不同。后者为0。

您可以通过执行以下操作来修复不一致的展示位置组：

```
ceph pg repair {placement-group-ID}
```

从而用*权威*的副本覆盖*不良*副本。在大多数情况下，Ceph可以使用一些预定义的标准从所有可用副本中选择权威副本。但这并不总是有效。例如，存储的数据摘要可能会丢失，并且在选择权威副本时将忽略所计算的摘要。因此，请谨慎使用以上命令。

如果shard`read_error`的`errors`属性中列出了，则可能由于磁盘错误而导致不一致。您可能要检查该OSD使用的磁盘。

如果`active + clean + inconsistent`由于时钟偏斜而定期收到状态，则可以考虑将Monitor主机上的[NTP](https://en.wikipedia.org/wiki/Network_Time_Protocol)守护程序配置为对等主机。有关更多详细信息，请参见[网络时间协议](http://www.ntp.org/)和Ceph[时钟设置](https://www.bookstack.cn/read/ceph-en/d67c50086882a284.md#clock)。

#### 纠删码 PGs 不是t active+clean

当CRUSH无法找到足够的OSD映射到PG时，它将显示为`2147483647`ITEM_NONE或`no OSD found`。例如：

```
[2,1,6,0,5,8,2147483647,7,4]
```

#### OSD不足

如果Ceph集群只有8个OSD，而擦除编码池需要9，它将显示该内容。您可以创建另一个需要较少OSD的纠删码池：

```
ceph osd erasure-code-profile set myprofile k=5 m=3
ceph osd pool create erasurepool erasure myprofile
```

或添加新的OSD，PG将自动使用它们。

#### 不能满足CRUSH约束

如果群集具有足够的OSD，则CRUSH规则可能会施加无法满足的约束。如果两个主机上有10个OSD，并且CRUSH规则要求在同一PG中不使用同一主机上的两个OSD，则映射可能会失败，因为将只能找到两个OSD。您可以通过显示（“转储”）规则来检查约束：

```
$ ceph osd crush rule ls
[
    "replicated_rule",
    "erasurepool"]
$ ceph osd crush rule dump erasurepool
{ "rule_id": 1,
  "rule_name": "erasurepool",
  "ruleset": 1,
  "type": 3,
  "min_size": 3,
  "max_size": 20,
  "steps": [
        { "op": "take",
          "item": -1,
          "item_name": "default"},
        { "op": "chooseleaf_indep",
          "num": 0,
          "type": "host"},
        { "op": "emit"}]}
```

您可以通过创建一个新的池来解决问题，在该池中，允许PG将OSD驻留在同一主机上，并具有以下条件：

```
ceph osd erasure-code-profile set myprofile crush-failure-domain=osd
ceph osd pool create erasurepool erasure myprofile
```

#### CRUSH放弃太早

如果Ceph集群只有足够的OSD来映射PG（例如，总共有9个OSD的集群和每个PG需要9个OSD的擦除编码池），则CRUSH可能会在找到映射之前放弃。可以通过以下方式解决：

- 降低擦除编码池的要求，以使每个PG使用更少的OSD（这需要创建另一个池，因为不能动态修改擦除码配置文件）。
- 向群集中添加更多OSD（不需要修改擦除码池，它将自动变得干净）
- 使用手工尝试的CRUSH规则尝试更多次才能找到良好的映射。这可以通过将值设置`set_choose_tries`为大于默认值来完成。

您应该首先`crushtool`从群集中提取crushmap来验证问题，以便您的实验不会修改Ceph群集，而只能在本地文件上工作：

```
$ ceph osd crush rule dump erasurepool
{ "rule_name": "erasurepool",
  "ruleset": 1,
  "type": 3,
  "min_size": 3,
  "max_size": 20,
  "steps": [
        { "op": "take",
          "item": -1,
          "item_name": "default"},
        { "op": "chooseleaf_indep",
          "num": 0,
          "type": "host"},
        { "op": "emit"}]}
$ ceph osd getcrushmap > crush.map
got crush map from osdmap epoch 13
$ crushtool -i crush.map --test --show-bad-mappings \
   --rule 1 \
   --num-rep 9 \
   --min-x 1 --max-x $((1024 * 1024))
bad mapping rule 8 x 43 num_rep 9 result [3,2,7,1,2147483647,8,5,6,0]
bad mapping rule 8 x 79 num_rep 9 result [6,0,2,1,4,7,2147483647,5,8]
bad mapping rule 8 x 173 num_rep 9 result [0,4,6,8,2,1,3,7,2147483647]
```

凡`—num-rep`在屏上显示的纠删码CRUSHrule需要的数量，`—rule`是价值`ruleset`的fielddisplayed `ceph osd crush rule dump`。该测试将尝试映射一百万个值（即由定义的范围`[—min-x,—max-x]`），并且必须显示至少一个错误的映射。如果没有输出，则表示所有映射都已成功，您可以就此停止：问题在别处。

可以通过反编译crushmap来编辑CRUSH规则：

```
$ crushtool --decompile crush.map > crush.txt
```

并将以下行添加到规则中：

```
step set_choose_tries 100
```

文件的相关部分`crush.txt`应类似于：

```
rule erasurepool {
        ruleset 1
        type erasure
        min_size 3
        max_size 20
        step set_chooseleaf_tries 5
        step set_choose_tries 100
        step take default
        step chooseleaf indep 0 type host
        step emit
}
```

然后可以对其进行编译和再次测试：

```
$ crushtool --compile crush.txt -o better-crush.map
```

当所有映射都成功时，可以使用以下`—show-choose-tries`选项显示找到所有映射所需的尝试次数的直方图`crushtool`：

```
$ crushtool -i better-crush.map --test --show-bad-mappings \
   --show-choose-tries \
   --rule 1 \
   --num-rep 9 \
   --min-x 1 --max-x $((1024 * 1024))
...
11:        42
12:        44
13:        54
14:        45
15:        35
16:        34
17:        30
18:        25
19:        19
20:        22
21:        20
22:        17
23:        13
24:        16
25:        13
26:        11
27:        11
28:        13
29:        11
30:        10
31:         6
32:         5
33:        10
34:         3
35:         7
36:         5
37:         2
38:         5
39:         5
40:         2
41:         5
42:         4
43:         1
44:         2
45:         2
46:         3
47:         1
48:         0
...
102:         0
103:         1
104:         0
...
```

尝试了11次尝试映射了42个PG，尝试了12次尝试映射了44个PG，等等。尝试次数最多的是`set_choose_tries`防止错误映射的最小值（即，在上面的输出中为103次，因为对于任何PG来说，尝试次数都不超过103次）进行映射）。



### 内存分析

Ceph MON，OSD和MDS可以使用生成堆配置文件`tcmalloc`。要生成堆概要文件，请确保已`google-perftools`安装：

```
sudo apt-get install google-perftools
```

探查器将输出转储到您的`log file`目录（即`/var/log/ceph`）。有关详细信息，请参见[日志记录和调试。](https://www.bookstack.cn/read/ceph-en/7b7e247b0ffd58dd.md)要使用Google的性能工具查看探查器日志，请执行以下操作：

```
google-pprof --text {path-to-daemon}  {log-path/filename}
```

例如：

```
$ ceph tell osd.0 heap start_profiler
$ ceph tell osd.0 heap dump
osd.0 tcmalloc heap stats:------------------------------------------------
MALLOC:        2632288 (    2.5 MiB) Bytes in use by application
MALLOC: +       499712 (    0.5 MiB) Bytes in page heap freelist
MALLOC: +       543800 (    0.5 MiB) Bytes in central cache freelist
MALLOC: +       327680 (    0.3 MiB) Bytes in transfer cache freelist
MALLOC: +      1239400 (    1.2 MiB) Bytes in thread cache freelists
MALLOC: +      1142936 (    1.1 MiB) Bytes in malloc metadata
MALLOC:   ------------
MALLOC: =      6385816 (    6.1 MiB) Actual memory used (physical + swap)
MALLOC: +            0 (    0.0 MiB) Bytes released to OS (aka unmapped)
MALLOC:   ------------
MALLOC: =      6385816 (    6.1 MiB) Virtual address space used
MALLOC:
MALLOC:            231              Spans in use
MALLOC:             56              Thread heaps in use
MALLOC:           8192              Tcmalloc page size
------------------------------------------------
Call ReleaseFreeMemory() to release freelist memory to the OS (via madvise()).
Bytes released to the OS take up virtual address space but no physical memory.
$ google-pprof --text \
               /usr/bin/ceph-osd  \
               /var/log/ceph/ceph-osd.0.profile.0001.heap
 Total: 3.7 MB
 1.9  51.1%  51.1%      1.9  51.1% ceph::log::Log::create_entry
 1.8  47.3%  98.4%      1.8  47.3% std::string::_Rep::_S_create
 0.0   0.4%  98.9%      0.0   0.6% SimpleMessenger::add_accept_pipe
 0.0   0.4%  99.2%      0.0   0.6% decode_message
 ...
```

同一守护程序上的另一个堆转储将添加另一个文件。将其与以前的堆转储进行比较以显示此间隔内增长的内容是很方便的。例如：

```
$ google-pprof --text --base out/osd.0.profile.0001.heap \
      ceph-osd out/osd.0.profile.0003.heap
 Total: 0.2 MB
 0.1  50.3%  50.3%      0.1  50.3% ceph::log::Log::create_entry
 0.1  46.6%  96.8%      0.1  46.6% std::string::_Rep::_S_create
 0.0   0.9%  97.7%      0.0  26.1% ReplicatedPG::do_op
 0.0   0.8%  98.5%      0.0   0.8% __gnu_cxx::new_allocator::allocate
```

有关其他详细信息，请参阅[Google Heap Profiler](http://goog-perftools.sourceforge.net/doc/heap_profiler.html)。

一旦安装了堆概要分析器，就启动您的集群并开始使用堆概要分析器。您可以在运行时启用或禁用heapprofiler，或确保其连续运行。对于以下命令行用法，请替换`{daemon-type}`为`mon`，`osd`或`mds`，然后替换`{daemon-id}`为OSD编号或MON或MDS id。

#### 启动探查器

要启动堆分析器，请执行以下操作：

```
ceph tell {daemon-type}.{daemon-id} heap start_profiler
```

示例：

```
ceph tell osd.1 heap start_profiler
```

另外，如果`CEPH_HEAP_PROFILER_INIT=true`在环境中找到该变量，则可以在守护程序开始运行时启动配置文件。

#### 打印统计

要打印统计信息，请执行以下操作：

```
ceph  tell {daemon-type}.{daemon-id} heap stats
```

例如：

```
ceph tell osd.0 heap stats
```

笔记

打印统计信息不需要运行分析器，也不会将堆分配信息转储到文件中。

#### 转储堆信息

要转储堆信息，请执行以下操作：

```
ceph tell {daemon-type}.{daemon-id} heap dump
```

例如：

```
ceph tell mds.a heap dump
```

注意

转储堆信息仅在分析器运行时有效。

#### 释放内存

要释放`tcmalloc`已分配但Ceph守护进程本身未使用的内存，请执行以下操作：

```
ceph tell {daemon-type}{daemon-id} heap release
```

例如：

```
ceph tell osd.2 heap release
```

#### 停止探查器

要停止堆分析器，请执行以下操作：

```
ceph tell {daemon-type}.{daemon-id} heap stop_profiler
```

例如：

```
ceph tell osd.0 heap stop_profiler
```



### CPU分析

如果您从源代码构建Ceph并编译了Ceph以与[oprofile](http://oprofile.sourceforge.net/about/)一起使用，则可以分析Ceph的CPU使用率。有关详细信息，请参见[安装Oprofile](https://www.bookstack.cn/read/ceph-en/f74275b68a9db2a4.md)。

#### 初始化oprofile

第一次使用时`oprofile`，需要对其进行初始化。找到与`vmlinux`您现在正在运行的内核相对应的映像。

```
ls /boot
sudo opcontrol --init
sudo opcontrol --setup --vmlinux={path-to-image} --separate=library --callgraph=6
```

#### 启动oprofile

要开始`oprofile`执行以下命令：

```
opcontrol --start
```

一旦开始`oprofile`，您可以使用Ceph运行一些测试。

#### 停止oprofile

要停止`oprofile`执行以下命令：

```
opcontrol --stop
```

#### 检索未完成的结果

要检索最高`cmon`结果，请执行以下命令：

```
opreport -gal ./cmon | less
```

要检索`cmon`附加了调用图的最高结果，请执行以下命令：

```
opreport -cal ./cmon | less
```

重要的

查看结果后，应重新`oprofile`设置，然后再运行。重置`oprofile`将从会话目录中删除数据。

#### 重置oprofile

要重置`oprofile`，请执行以下命令：

```
sudo opcontrol --reset
```

重要的

您应该`oprofile`在分析数据之后进行重置，以免混淆来自不同测试的结果。



## 监控OSD和PG

[官方参考](https://www.bookstack.cn/read/ceph-en/a04e9208413f2a01.md)

高可用性和高可靠性要求使用容错方法来管理硬件和软件问题。Ceph没有单点故障，并且可以以“降级”模式处理对数据的请求。Ceph的[数据放置](https://www.bookstack.cn/read/ceph-en/8974b638d017b8d9.md)引入了一个间接层，以确保数据不直接绑定到特定的OSD地址。这意味着要跟踪系统故障，需要找到问题根源的[放置组](https://www.bookstack.cn/read/ceph-en/4bc7afaecb4c1c71.md)和底层OSD。

提示

群集某一部分中的故障可能会阻止您访问特定的对象，但这并不意味着您无法访问其他对象。当您遇到故障时，请不要惊慌。只需按照监视OSD和放置组的步骤进行即可。然后，开始故障排除。

Ceph通常是自我修复。但是，如果问题仍然存在，则监视OSD和放置组将帮助您确定问题。

### 监控OSD

OSD的状态位于群集（`in`）或群集之外（`out`）。并且，它已启动并正在运行（`up`），或者已关闭并未运行（`down`）。如果OSD是`up`，则它可以是`in`群集（可以读取和写入数据），也可以是`out`群集的。如果它是`in`集群，并且是集群的最近移动`out`，则Ceph将把放置组迁移到其他OSD。如果OSD属于`out`群集，则CRUSH不会将放置组分配给OSD。如果OSD是`down`，也应该是OSD `out`。

提示

如果OSD是`down`和`in`，则存在问题，并且群集将无法处于正常状态。

> ![](/home/bsd/readme/ceph_notes/osd_status.png)

如果执行的命令，例如`ceph health`，`ceph -s`或者`ceph -w`，你可能会注意到集群总是不回显`HEALTH OK`。不要惊慌 关于OSD，您应该期望群集在某些预期情况下**不会**回显`HEALTH OK`：

- 您尚未启动集群（它不会响应）。
- 您刚刚启动或重新启动了集群，但尚未准备好，因为正在创建放置组并且OSD正在对等。
- 您刚刚添加或删除了OSD。
- 您刚刚修改了集群图。

监视OSD的一个重要方面是确保在群集启动并运行时，作为群集的所有OSD`in`也在`up`运行。要查看所有OSD是否正在运行，请执行：

```
ceph osd stat
```

结果应告诉您OSD总数（x），多少`up`（y），多少`in`（z）和map时期（eNNNN）。

```
x osds: y up, z in; epoch: eNNNN
```

如果作为`in`群集的OSD数量大于的OSD数量`up`，请执行以下命令以标识`ceph-osd`未运行的守护程序：

```
ceph osd tree
```

```
#ID CLASS WEIGHT  TYPE NAME             STATUS REWEIGHT PRI-AFF
 -1       2.00000 pool openstack
 -3       2.00000 rack dell-2950-rack-A
 -2       2.00000 host dell-2950-A1
  0   ssd 1.00000      osd.0                up  1.00000 1.00000
  1   ssd 1.00000      osd.1              down  1.00000 1.00000
```

提示

通过精心设计的CRUSH层次结构进行搜索的能力可以通过更快地识别物理位置来帮助您对群集进行故障排除。

如果OSD是`down`，请启动它：

```
sudo systemctl start ceph-osd@1
```

请参阅[OSD未运行](https://www.bookstack.cn/read/ceph-en/7bd7346c8207ec58.md#osd-not-running)以获取与已停止或无法重启的OSD相关的问题



### PG设置

当CRUSH将放置组分配给OSD时，它将查看池的副本数，并将该放置组分配给OSD，以便将该放置组的每个副本分配给一个不同的OSD。例如，如果一个poolrequires贴装组的三个副本，CRUSH可以为它们分配`osd.1`，`osd.2`并`osd.3`分别。CRUSH实际上是在寻求伪随机放置，该放置将考虑您在[CRUSH映射中](https://www.bookstack.cn/read/ceph-en/18e903f31a47a50b.md)设置的故障域，因此您很少会看到大型集群中分配给最近邻居OSD的放置组。我们将应包含特定放置组副本的OSD集合称为“**代理集”**。在某些情况下，代理集中的OSD为`down`否则无法为展示位置组中的对象提供服务。当这些情况出现时，不要惊慌。常见的示例包括：

- 您添加或删除了OSD。然后，CRUSH将布局组重新分配给其他OSD，从而更改了“代理集”的组成并通过“回填”过程产生了数据迁移。
- OSD是`down`，已经重新启动，现在是`recovering`。
- 代理集中的一个OSD正在`down`或无法为请求提供服务，并且另一个OSD暂时承担了其职责。

Ceph使用**Up Set**处理客户端请求，**Up Set**是实际上将处理请求的OSD集合。在大多数情况下，Up Set和ActingSet实际上是相同的。如果不是，则可能表明Ceph正在迁移数据，正在恢复OSD或存在问题（例如，在这种情况下Cephusually用“ stread stale”消息回显“ HEALTH WARN”状态）。

要检索展示位置组列表，请执行以下操作：

```
ceph pg dump
```

要查看给定放置组的“动作集”或“上集”中的哪些OSD，请执行以下操作：

```
ceph pg map {pg-num}
```

结果应该告诉您osdmap时期（eNNN），布局组编号（{pg-num}），上一组（up []）中的OSD和操作集中（acting []）中的OSD。

```
osdmap eNNN pg {raw-pg-num} ({pg-num}) -> up [0,1,2] acting [0,1,2]
```

注意

如果Up Set和Acting Set不匹配，则可能表明群集正在重新平衡自身或群集存在潜在问题。