# Ceph相关配置

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

可编辑CRUSH map文件中ruleset相关选项及其具体含义如下所示：

| 选项名称 |      |                           含义                            |
| :------: | ---- | :-------------------------------------------------------: |
| ruleset  |      | 对应规则（集）的唯一编号。不同的pool可以使用不同的ruleset |
|   type   |      |        副本策略，包含如下选项：replicated,erasure         |
| min_size |      |              用于对选择副本数的范围进行约束               |
| max_size |      |              用于对选择副本数的范围进行约束               |

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