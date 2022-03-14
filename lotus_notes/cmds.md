# lotus部署常用命令

## 学习资料地址

常用链接地址：

>【Filecoin 中国社区论坛】（论坛末尾有旧版资源链接）：
https://github.com/filecoin-project/community-china
【备用网址，不用翻墙】（有时候不稳定）: 
https://hub.fastgit.org/filecoin-project/community-china
【备用网址，不用翻墙】（有时候不稳定）: 
https://github.com.cnpmjs.org/filecoin-project/community-china
>【Filecoin 中国社区论坛讨论模块】（里面有大量学习资料）：
https://github.com/filecoin-project/community-china/discussions
【备用网址，不用翻墙】（有时候不稳定）:
https://hub.fastgit.org/filecoin-project/community-china/discussions
【备用网址，不用翻墙】（有时候不稳定）:
https://github.com.cnpmjs.org/community-china/discussions

>新人必读：
【本地搭建 2K 测试网入门教程】（包括常见问题和环境搭建）：
https://github.com/filecoin-project/community-china/blob/master/documents/tutorial/local_2k_dev_tutorial/local_2k_dev_tutorial.md
【Calibration 测试网使用教程】（半新手专用）：
https://github.com/filecoin-project/community-china/blob/master/documents/tutorial/use_cali-net_tutorial/use_cali-net_tutorial.md
----------------------------------------------------------------------------------------------------------------------------------------


## 设置交换分区

sudo fallocate -l 256G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

show current swap spaces and take note of the current highest priority

swapon --show

append the following line to /etc/fstab (ensure highest priority) and then reboot

/swapfile swap swap pri=50 0 0

sudo reboot

check a 256GB swap file is automatically mounted and has the highest priority

swapon --show



## 常用系统操作

磁盘管理工具 gparted:
安装 sudo apt-get install gparted
注意，在Ubuntu中，gparted在默认情况下并不支持NTFS分区，必须还要使用如下指令安装ntfsprogs:

sudo apt-get install ntfsprogs

启动 sudo gparted

查看GPU型号
lspci | grep -i vga
查看CPU型号
cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c
強制殺死進程
kill -s 9 <pid>
关闭子会话
screen -X -S 4635 quit



切换分支 git switch -c v1.5.0-rc2
nohup lotus daemon >> /data/lotus.log 2>&1 &
查看显卡信息
sudo lshw -numeric -class video

查看文件夹大小

du -s {filename}

## lotus 编译

### 构建lotus

**AMD Zen或Intel Ice Lake CPU（或更高版本）**

nightly-2020-10-05

```sh
export RUSTFLAGS="-C target-cpu=native -g"
export FFI_BUILD_FROM_SOURCE=1
```

make clean && make all # mainnet Or to join a testnet or devnet:

make clean && make calibnet # Calibration with min 32 GiB sectors
make clean && make nerpanet # Nerpa with min 512 MiB sectors

sudo make install

### 升级

支持SHA扩展（前提cpu支持SHA扩展）
export RUSTFLAGS="-C target-cpu=native -g"
export FFI_BUILD_FROM_SOURCE=1
git pull
git checkout <tag_or_branch>
git submodule update
make clean
make all
make install

make clean calibnet

RUST_LOG=Trace





## worker

启动远程worker

lotus-worker run --listen=192.168.51.10:2345 --addpiece=true --precommit1=true --precommit2=true --commit=true --unseal=true



## miner

[推荐配置](https://github.com/shannon-6block/lotus-miner)

nohup lotus-miner run > ~/miner.log 2>&1 &

查看日志

tail -f ~/miner.log

RUST_LOG=Trace lotus-miner run

封装一个扇区
lotus-miner sectors pledge
查看启动的封装任务
lotus-miner sealing jobs
检查启动的workers
lotus-miner sealing workers

查看miner相关信息
lotus-miner auth api-info --perm admin
发布矿工地址，以便与其他矿工节点通信（前提配置Libp2p API信息为公网IP）
lotus-miner actor set-addrs /ip4/<YOUR_PUBLIC_IP_ADDRESS>/tcp/24001

首次启动矿工
lotus-miner init --owner=<address>  --worker=<address> --no-local-storage --sector-size=32GiB
--worker可后续添加
--no-local-storage 指定特定储存位置，建议使用

密封缓存文件储存位置
lotus-miner storage attach --init --seal <PATH_FOR_SEALING_STORAGE>
密封完成后，移动到下列指定储存位置
lotus-miner storage attach --init --store <PATH_FOR_LONG_TERM_STORAGE>
列出储存位置
lotus-miner storage list
移动位置参见  https://docs.filecoin.io/mine/lotus/miner-lifecycle/#changing-storage-locations

```
设置剩余存储空间不足15%情况下不再自动添加新的封装任务（默认 10%）
lotus-miner run --min-storage-available-percent-for-auto-pledge 15
```

限制baseFee低于阈值的时候才提交PreCommit消息

```
# 通过miner的config.toml修改
[Fees]
...
MaxBaseFee = "3000000000 attoFIL"

# 通过命令在miner运行中修改（重启miner仍然会使用config.toml中的值）
lotus-miner sealing set --base-fee-threshold "3000000000 attoFIL"
```

余额不足情况下不再自动添加新的封装任务（已经开始封装的会继续完成）

```
# 设置余额不足10 FIL情况下不再自动添加新的封装任务（默认 10000 FIL）
lotus-miner run --min-worker-balance-for-auto-pledge 10
```



## 备份

step1 创建备份文件夹

mkdir -p ~/lotus-backups/2020-12-15

step2 备份

lotus-miner backup ~/lotus-backups/2020-12-15/backup.cbor # 需要设置LOTUS_BACKUP_BASE_PATH
lotus-miner backup --offline ~/lotus-backups/2020-12-15/backup.cbor

step3 备份config.toml 和 storage.json

cp ~/.lotusminer/config.toml ~/.lotusminer/storage.json ~/lotus-backups/2012-12-15

## 恢复
step1 拷贝backup.cbor, config.toml, storage.json到miner所在的机器

step2 从备份文件恢复

lotus-miner init resotre ~/lotus-backups/2020-12-15/backup.cbor

step3 拷贝覆盖config.toml 和 storage.json

cp ~/lotus-backups/2020-12-15/config.toml ~/lotus-backups/2020-12-15/storage.json $LOTUS_MINER_PATH/

step4 启动miner

lotus-miner run

## 通过ip从众多worker机器中找出没有运行的worker

lotus-miner sealing workers |grep Worker| awk '{ print $4}' | awk -F: '{print $1}' |awk -F. '{print $4}' |sort -n

查找存储下的tmp文件

sudo find  .  -maxdepth 5 -type f -name "*.tmp"

批量删除sealing jobs

lotus-miner sealing jobs |awk '{print $1}' > remove.job
cat remove.job |xagrs -n 1 lotus-miner sealing abort

#磁盘目录下写入挂载点内容
m=$(ls /data |xargs -n 1);for i in $m ; do  touch "/data/$i/data-$i"; echo "/data/$i/" > "/data/$i/data-$i";cat "/data/$i/data-$i"; done

ip=10.0.228.201;m=$(ls /mnt/$ip |xargs -n 1);for i in $m ; do  touch "/mnt/$ip/$i/mountpoint"; echo "/mnt/$i/" > "/mnt/$ip/$i/mountpoint";cat "/mnt/$ip/$i/mountpoint"; done



## 备份和还原

### 备份

此过程备份Lotus Miner的元数据，这是恢复操作所必需的。此备份不包括扇区数据。

1. 创建此备份的目录：
mkdir -p ~/lotus-backups/2020-11-15
2. 致电backup备份您的矿工并提供backup.cbor文件的目的地：
lotus-miner backup /root/lotus-backups/2020-11-15/backup.cbor
> Success
--offline如果您的矿工当前未运行，请添加备份：
lotus-miner backup --offline /root/lotus-backups/2020-11-15/backup.cbor
> Success
3. 备份config.toml和storage.json文件：
cp ~/.lotusminer/config.toml ~/.lotusminer/storage.json /root/lotus-backups/2020-11-15
备份现已完成。存储备份时，请始终遵循3-2-1规则：
保留至少三（3）个数据副本，并将两（2）个备份副本存储在不同的存储介质上，其中一（1）个位于场外
### 恢复

1. 如果您的backup.cbor，config.toml和storage.json文件位于另一台计算机上，则将其复制到该矿机。
2. 致电restore以从备份文件恢复您的矿工：
lotus-miner init restore /root/lotus-backups/2020-11-15/backup.cbor
3. 复制config.toml并storage.json存入~/.lotusminer：
cp lotus-backups/2020-11-15/config.toml lotus-backups/2020-11-15/storage.json .lotusminer
4. 启动您的矿工：
lotus-miner run
------------------------------------------------------------


## 扇区操作

查看扇区信息
lotus-miner sectors list
查看扇区状态
lotus-miner sectors status 0
查看扇区详细日志--查看封装sector时间长度
lotus-miner sectors status --log <sector_id>

删除扇区（谨慎操作,针对PreCommitFailed和SealPreCommit1Failed状态的扇区，因为还没有质押）
如果此扇区已上链，则使用terminate操作以减少处罚
lotus-miner sectors remove --really-do-it <sectorId>
更新扇区状态(针对CommitFailed状态的扇区，可通过以下命令，将扇区状态更改为Committing状态)
lotus-miner sectors update-state --really-do-it <sectorId> <newState>

启动lotus-miner时加 RUST_LOG=Trace,可以查到miner日志
查看扇区状态
lotus-miner sectors status 0
查看扇区详细日志
lotus-miner sectors status --log 0
升级承诺扇区到包含交易的新扇区
lotus-miner sectors mark-for-upgrade <sector number>
查看扇區儲存位置
lotus-miner storage find <sector number>
按索引查看当前验证期截止日期信息
lotus-miner proving deadline <idnex_id>
查看所有扇區驗證期截止日期信息
lotus-miner proving deadlines
查看所有錯誤扇區
lotus-miner proving faults
查看窗口錯誤扇區
lotus-miner proving deadline 5
檢查窗口錯誤扇區

lotus-miner proving check --only-bad 5

对于FatalError状态的sector，可以用下面的脚本解决

```
m=`lotus-miner info | grep 'Miner:' | awk -F ' ' '{print $2}'`
lotus state sectors $m > /tmp/s.txt
for i in `lotus-miner sectors list | grep -P '(Fatal|Fail|Recover)' | grep -v Remove | awk -F ' ' '{print $1}'`
do
  a=`cat /tmp/s.txt | grep -P "^$i:" | wc -l`
  if [ $a -eq 0 ]
  then
    echo $i $a Removing
    lotus-miner sectors update-state --really-do-it $i Removing
  else
    echo $i $a Proving
    lotus-miner sectors update-state --really-do-it $i Proving
  fi
done
```



## 交易相关

### 配置

Lotus矿工接单配置
Deal配置 - Miner有公网IP
假设Miner的公网IP为123.123.73.123，内网IP为10.4.0.100。

(1) MinerIP配置
修改$LOTUS_STORAGE_PATH/config.toml文件中的以下内容：
将ListenAddresses中的IP改为123.123.73.123（即公网IP地址），端口自己指定一个固定端口，例如: 1024；

[Libp2p]
ListenAddresses = ["/ip4/123.123.73.123/tcp/1024", "/ip6/::/tcp/0"]
更改配置以后，需要重启Miner。

(2) 设置multiaddress
这里的multiaddress即为上面第(1)步中配置的ListenAddresses的地址。

lotus-miner actor set-addrs /ip4/123.123.73.123/tcp/1024

设置完等待消息确认后，可以通过以下命令查看结果:

lotus state miner-info [t0xxxx]

-------------------交易状态转换-----------------------------
一笔交易从发起到完成的整个过程，所需要的时间比较久，并且会经历多个不同的状态转换，主要的状态包括如下所示的 5 个：

StorageDealClientFunding
StorageDealCheckForAcceptance
StorageDealAwaitingPreCommit
StorageDealSealing
StorageDealActive

可通过命令 ~/git2/lotus/lotus client list-deals 查看交易的状态信息，当交易达到最后一个 StorageDealActive 状态的时候，表明这笔交易已经完成。在整个交易的过程中，最耗时的是从 StorageDealAwaitingPreCommit 状态到 StorageDealSealing 状态，一般需要等待 5 个小时以上，其它状态耗时相对比较短。

关闭接单功能 ConsiderOnlineStorageDeals = false （lotus-miner confid.toml）或 otus-miner storage-deals selection reject --online --offline
设置存储交易价格等参数
lotus-miner storage-deals set-ask \
  --price 0.0000001 \
  --verified-price 0.0000001  \
  --min-piece-size 56KiB \
  --max-piece-size 32GB
上面的命令将交易价格设置为每个纪元每GiB 0.0000001 FIL（100 nanoFIL）。这意味着，客户将不得不为100 nanoFIL每一个存储的GiB每30秒支付一次。如果客户希望在一周的时间内存储5GiB，则总价格为：5GiB * 100nanoFIL/GiB_Epoch * 20160 Epochs = 10080 microFIL
查看矿工收费情况
lotus-miner storage-deals get-ask
通过交易ID获取交易状态
lotus client get-deal <交易ID>
查询指定矿工价格
lotus client query-ask <minerID>
关闭接收订单功能
lotus-miner storage-deals selection reject --online --offline
查看效果
lotus-miner storage-deals selection list
重启接单功能
lotus-miner storage-deals selection reset
列出当前交易
lotus-miner storage-deals list -v
查看待发布交易
lotus-miner storage-deals pending-publish
随时发布交易
lotus-miner storage-deals pending-publish --publish-now
该矿工的默认配置设置为批处理多个交易，并将消息发布到每小时最多8个交易。您可以在配置文件中更改PublishMsgPeriod和。MaxDealsPerPublishMsg

通过PieceCID阻止存储交易
Lotus Miner提供了用于导入PieceCID阻止列表的内部工具：
lotus-miner storage-deals set-blocklist blocklist-file.txt
本blocklist-file.txt应包含CID列表，每一个单独的行。可以使用以下命令检查当前阻止列表：
lotus-miner storage-deals get-blocklist
要重置和清除阻止列表，请运行：
lotus-miner storage-deals reset-blocklist
将同一部门的交易分组
在收到交易的瞬间与开始密封包含数据的部门之间的延迟允许矿工在空间允许的情况下在每个部门中包括多个交易。每个部门的交易数量越高，操作效率就越高，因为它需要更少的密封和验证操作。

可以使用配置部分中的WaitDealsDelay选项设置延迟。[Sealing]
离线存储交易
当要传输的数据量很大时，将某些硬盘直接运送到矿机并以脱机方式完成交易可能会更有效。

在这种情况下，矿工将必须使用以下命令手动导入存储交易数据：

lotus-miner storage-deals import-data <dealCid> <filePath>



## lotus 存储数据和检索数据

在本地添加文件
lotus client import test-add.txt
列出本地文件
lotus client local
列出能存储数据的矿工
lotus state list-miners
向矿工询价
lotus client query-ask <miner>
eg: lotus client query-ask t017792
存储数据
lotus client deal <Data CID> <miner> <price> <duration>
eg: lotus client deal  bafkreiahpvhvylrriipo42l4ozgoyschcc4qvgrtv2v6ofi3b2dt5fntsq  t017792 0.0000000005 1920
miner 矿工id
price 价格
duration 表示矿工将你的数据保存多久,以块表示，一个块代表45秒 ,一天246060/45=1920
命令成功后返回 Deal CID
检查交易状态
lotus client list-deals
根据数据cid查找
lotus client find <Data CID>
1
根据cid检索数据
lotus client retrieve <Data CID> <outfile>
1
如果outfile不存在，将在lotus仓库目录下创建
此命令会初始化检索交易，并下载数据到你的计算机，这个过程大概要花2到10分钟

通过CID查找数据信息
lotus client find <Data CID>
通过数据 CID 检索数据，并把检索到的数据保存到 ./tmp.log 文件中

lotus client retrieve <Data CID> <outfile>

----------------------------------------------------------------------------------------------



## 节点操作

加速首次启动 proof parameter 下载

export IPFS_GATEWAY=https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/

加快lotus 构建时Go依赖模块下载

export GOPROXY=https://goproxy.cn

lotus安裝好後，配置相關環境變量
直接启动Lotus节点
lotus daemon
nohup lotus daemon > ~/lotus.log 2>&1 &
通过快照启动Lotus节点
通过以下命令，从现有节点上导出Lotus快照。
lotus chain export --skip-old-msgs --recent-stateroots=2000 snapshot.car

通过以下命令，导入到现有节点，需要注意：
导入同步数据（在此之前保证.lotus目录中的内容是空的）；
导入数据之后， daemon 默认自动启动；
如果不想在导入数据之后自动启动 daemon，可以加上参数 --halt-after-import；

通過快照啓動lotus節點
lotus daemon --import-snapshot snapshot.car

更新配置文件
Daemon配置文件默认在~/.lotus/config.toml文件中, 若配置了$LOTUS_PATH环境变量，则在此路径下。
把下面的DAEMON_IP_ADDRESS改成Deamon本机的内网IP地址，并指定一个端口，默认端口是1234。

[API]
ListenAddress = "/ip4/<DAEMON_IP_ADDRESS>/tcp/1234/http"

RemoteListenAddress = ""

Timeout = "30s"

lotus net peers
lotus sync status
lotus sync wait
#查看节点数量
lotus net peers | wc -l
查看节点信息
lotus net listen | grep "192.168.51.10"
查看链上有哪些矿工
lotus state list-miners
手动连接到指定节点
lotus new connect <api:token>
查看lotus node相关信息
lotus auth api-info --perm admin

设置FULLNODE_API_INFO 环境变量

export FULLNODE_API_INFO="TOKEN:/ip4/<ip>/tcp/<port>/http"

FULLNODE_API_INFO 值通过如下命令产生, ip需要修改

lotus auth api-info --perm admin
查看链头
lotus chain head
打印块信息
lotus chain getblock <block_cid>
打印链中消息信息

lotus chain getmessage <message_cid>

### Daemon节点公网IP配置

给Daemon节点配置公网IP以后，可以让节点更稳定、更健康，评分更高，不错过任何一个爆块机会。

#### 1.1 配置公网IP

配置公网IP分如下两种情况：
**(1) Daemon有公网IP**
假设Daemon的公网IP为`123.123.73.123`，内网IP为`10.0.1.100`，Daemon监听的端口为`1234`。

**(2) Daemon无公网IP**
如果Daemon没有公网IP，就需要在路由器、或有公网IP的服务器上，增加公网IP和端口向Daemon内网IP和端口的转发规则，假设公网机器的IP为`123.123.73.123`，Daemon的内网IP为`10.0.1.100`，`123.123.73.123:12340`端口映射到内网的`10.0.1.100:1234`端口。

#### 1.2 更改Daemon配置

修改`$LOTUS_PATH/config.toml`文件中的以下内容：

- 将`ListenAddresses`中的端口改为内网的端口，如`1235`，IP为`0.0.0.0`不用改;
- 将`AnnounceAddresses`中的IP改为公网IP，如`123.123.73.123`，端口改为公网端口`12350`。

```
[Libp2p]
ListenAddresses = ["/ip4/0.0.0.0/tcp/1235", "/ip6/::/tcp/0"]
AnnounceAddresses = ["/ip4/123.123.73.123/tcp/12350"]
```

注意：**要修改的是Libp2p部分，而不是API部分。**

修改好并重启Daemon后，可以通过以下命令，查看Daemon的公网连接地址：

```
lotus net listen
```



## 2k devnet

export LOTUS_SKIP_GENESIS_CHECK=_yes_
下載2048字節證明參數
./lotus fetch-params 2048
預密封扇區
./lotus-seed pre-seal --sector-size 2KiB --num-sectors 2
創建創世節點並啓動第一個節點
./lotus-seed genesis new localnet.json
./lotus-seed genesis add-miner localnet.json ~/.genesis-sectors/pre-seal-t01000.json
./lotus daemon --lotus-make-genesis=devgen.car --genesis-template=localnet.json --bootstrap=false
在另一个控制台中，导入genesis miner密钥：
./lotus wallet import --as-default ~/.genesis-sectors/pre-seal-t01000.key
设置创世矿工：
./lotus-miner init --genesis-miner --actor=t01000 --sector-size=2KiB --pre-sealed-sectors=~/.genesis-sectors --pre-sealed-metadata=~/.genesis-sectors/pre-seal-t01000.json --nosync --no-local-storage --owner= --create-worker-key=true
启动矿机：
./lotus-miner run --nosync



重启创世节点
lotus daemon --genesis=devgen.car --profile=bootstrapper
启动其他节点
lotus daemon --genesis=devgen.car --bootstrap=false
初始化新节点

lotus-miner init --sector-size=2KiB --no-local-storage --owner= --worker=



## 消息池

查詢當前BaseFee信息

Will print the last BaseFee in attoFIL

lotus chain head | xargs lotus chain getblock | jq -r .ParentBaseFee

新的gas溢价低于原始比率的1.25，则该消息将不包含在池中
BaseFee决定gas最终成本
获取BaseFee信息
lotus chain head | xargs lotus chain getblock | jq -r .ParentBaseFee
如果矿工认为消息不够吸引人，无法包含在新块中，则它们可能会卡在消息池中。这通常是由于GasFeeCap太低而导致的，例如，当网络的BaseFee很高时。如果网络拥塞，也可能是GasPremium太低的结果
查看消息池中是否存在堵塞消息
lotus mpool pending --local | wc -l
检查消息池中是否有消息
lotus mpool pending --local
查看GasLimit，GasFeeCap和GasPremium信息
lotus mpool pending --local | grep "Nonce" -A5
替换池中的关联消息，并根据当前的网络状况估算出新的GasPremium和GasFeeCap来自动对其重新定价。您还可以设置--max-fee是否希望限制用于消息的总金额。所有其他标志都将被忽略。
lotus mpool replace --auto <from> <nonce>
或者，可以使用各自的标志手动设置GasPremium，GasFeeCa（新的天然气溢价低于原始比率的1.25，则该消息将不包含在池中）

lotus mpool replace --gas-feecap <feecap> --gas-premium <premium> <from> <nonce>



## 钱包操作

创建钱包

lotus wallet new bls	# BLS wallet
lotus wallet new 	# secp256k1 wallet
lotus msig create singeraddress1 signersaddress2..	# multisig wallet

备份钱包

lotus wallet export <address> > <address>.key

导入钱包

lotus wallet import <address>.key

发送FIL

lotus send <receive address> 3	#从默认钱包发送
lotus send --from <send address> <receive address> 3	#从指定钱包发送
查看钱包列表
lotus wallet list
lotus wallet list -i
查看默认钱包地址
lotus wallet default
设置默认钱包地址
lotus wallet set-default <address>
查看默认钱包余额
lotus wallet balance
查看当前矿工actor控制列表
lotus-miner actor control list
设置钱包所有者
lotus-miner actor set-owner --really-do-it <address>
控制地址用于支付提交WindowPoSts证明所需费用(设置配置地址后，要修改相应配置文件)
lotus-miner actor control set --really-do-it <address>
从矿工actor提款到owner所在账户

lotus-miner actor withdraw <amount>

修改owner、worker、control地址

```
# 查看矿工关联的地址信息
lotus-miner actor control list

# 修改owner地址
# step1:
lotus-miner actor set-owner --really-do-it <newOwner> <oldOwner>
# step2:
lotus-miner actor set-owner --really-do-it <newOwner> <newOwner>

# 修改control地址
lotus-miner actor control set --really-do-it <address1 address2 ...>

# 修改worker地址
# step1.
lotus-miner actor propose-change-worker <address>
# step2.
lotus-miner actor confirm-change-worker <address>
```

[分离ProveCommitSector地址](https://github.com/shannon-6block/lotus-miner/blob/master/COMMIT.md)

## 多重签名钱包

创建3个f3地址
lotus wallet new bls
lotus wallet new bls
lotus wallet new bls
从有钱的账号adress1转账给新地址
lotus send --from $address1 $newadress1
lotus send --from $address1 $newadress2
lotus send --from $address1 $newadress3
创建多签钱包,多签名钱包地址：t23x2vqn5mxkozhendxcvoarwkhypiijt5fjer3ci
lotus msig create --required=2 --from [发起人] [签名人1，签名人2]
lotus msig create --required=2 --from $newadress1 $newadress1 $newadress2
--required=2 每次交易需要同意的人数
检查多签钱包f2adressid为多签钱包ID，f2adress为多签钱包地址
lotus msig inspect $f2adressid
添加新的签名人
lotus msig add-propose --from $newadress1 $f2address $newadress3
修改交易需要同意的人数2->3
lotus msig propose-threshold --from $newadress1 $f2address 3
从有钱的账号address1转账给多签钱包f2address
lotus send --from $address1 $f2address
发起人$newadress1从多签账号转账给其他钱包
lotus msig propose --from $newadress1 $f2address $destaddress 0.1
$newadress2查看pending中的交易id
lotus msig inspect $f2adressid
$newadress2同意该笔交易

lotus msig approve --from $newadress2 $f2adressid $transaction_id



## 安全重启

是否可以重啓礦工，狀態檢查
1.Deadlines不早於Current Epoch，如果存在故障，必须大约45分钟才能使矿工重新联机以声明故障，这称为Deadline FaultCutoff，如果矿工没有故障，那么大约有一个小时的时间。
2.等待所有封裝任務任務完成


强制结束lotus-worker后，需要重启终端再执行（一般情况下不允许强制结束worker）

tips1 尽量缩短miner离线时间

tips2 确保current deadline窗口的证明已经提交

lotus-miner proving deadlines

tips3 检查并暂时停止交易（deals）

lotus-miner storage-deals list
lotus-miner retrieval-deals list
lotus-miner data-transfers list

拒绝交易

lotus-miner storage-deals selection reject --online --offline
lotus-miner retrieval-deals selection reject --online --offline

重启之后

lotus-miner storage-deals selection reset
lotus-miner retrieval-deals selection reset

tips4 检查正在进行中的封装操作

lotus-miner sectors list

tips5 重启miner

lotus-miner stop

lotus-miner start



## 測試封裝速度

RUST_LOG=Trace ./lotus-bench sealing --storage-dir /data/lotus-bench --sector-size 32GiB --num-sectors 1 --skip-unseal --parallel 1

Address                                                                                 ID       Balance                      Nonce  Default  
t3uhbuy6cxjlcfjoaz66u7blhzs72wsmrpaouom7kzqysx73ltsewnvxkt62hnpcg7x6gwgwl6tgmupbgwocga  t013950  4977.999995689685577955 FIL  8      X        
t3untyjoqp4e6bptsyes4lxteefafkyuz7urqwauezb6es3omiiifc62oxunab7bdfpeayo76jsagn56usrdsa  t013987  6 FIL                        0               
t3wlps2l7wm34bnh2msxoxwpke5agcwnpdyuzvlfk5gdf4zsivhdy42sgmcyqtafnpl7lw2dn5a7xjvkxcdnqq  t013988  6 FIL                        0               
t3ww7jsaiqetqqgtcucfzgqjgz3hwxwpjszjenydt3kmivbftphhvm4xm3t26mmvk5wytqqzvkfndx4e4szfta  t013978  10 FIL                       0 

/dns4/bootstrap-0.calibration.fildev.network/tcp/1347/p2p/12D3KooWRLZAseMo9h7fRD6ojn6YYDXHsBSavX5YmjBZ9ngtAEec

environment variable list:
FIL_PROOFS_USE_MULTICORE_SDR=1
BELLMAN_CUSTOM_GPU=GeForce RTX 3080 Ti:2206
FIL_PROOFS_MAXIMIZE_CACHING=1
FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1

FIL_PROOFS_USE_GPU_TREE_BUILDER=1

results (v28) SectorSize:(536870912), SectorNumber:(1)
seal: addPiece: 2.018679638s (253.6 MiB/s)
seal: preCommit phase 1: 32.049514637s (15.98 MiB/s)
seal: preCommit phase 2: 13.349490706s (38.35 MiB/s)
seal: commit phase 1: 54.148268ms (9.234 GiB/s)
seal: commit phase 2: 13.780121662s (37.15 MiB/s)
seal: verify: 4.816759ms

generate candidates: 111.134µs (4.394 TiB/s)
compute winning post proof (cold): 1.665371218s
compute winning post proof (hot): 1.575347854s
verify winning post proof (cold): 69.917096ms
verify winning post proof (hot): 4.430254ms

compute window post proof (cold): 849.624396ms
compute window post proof (hot): 807.811098ms
verify window post proof (cold): 34.598113ms
verify window post proof (hot): 6.171889ms



62f55953-8d02-4b66-9b96-59c60dd3f431

e27852d8-91ff-4146-a5e9-a6934e4f453e

62d7097d-2f2d-4d65-ad4b-ac483e201b01

## CPU开启性能模式

#### 临时开启

安装cpufrequtils

```
sudo apt-get install cpufrequtils
```

查看当前cpu的状态

```
cpufreq-info
```

设置为性能模式

```
sudo cpufreq-set -g performance
```

### 开机默认启动性能模式

使用上述方式，重启系统后又回到默认方式。修改默认模式:

安装sysfsutils

```
sudo apt-get install sysfsutils
```

编辑/etc/sysfs.conf，增加如下语句:(相对应的，每个CPU内核都需要添加)

```
devices/system/cpu/cpu0/cpufreq/scaling_governor = performance
```

查看CPU工作频率

```
watch grep \"cpu MHz\" /proc/cpuinfo
```

# Updating crates.io index 速度慢的解决办法

Rust社区公开的第三方包都集中在crates.io网站上面，他们的文档被自动发布到doc.rs网站上。Rust提供了非常方便的包管理器cargo，它类似于Node.js的npm和Python的pip。但cargo不仅局限于包管理，还为Rust生态系统提供了标准的工作流。
在实际开发中，为了更快速下载第三方包，我们需要把crates.io换国内的镜像源，否则在拉取 crates.io 仓库代码会非常慢，Updating crates.io index 卡很久，很多次超时导致引用库没法编译。

在 $HOME/.cargo/config 中添加如下内容：

```
# 放到 `$HOME/.cargo/config` 文件中
[source.crates-io]
#registry = "https://github.com/rust-lang/crates.io-index"

# 替换成你偏好的镜像源
replace-with = 'ustc'
#replace-with = 'sjtu'

# 清华大学
[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

# 中国科学技术大学
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

# 上海交通大学
[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

# rustcc社区
[source.rustcc]
registry = "git://crates.rustcc.cn/crates.io-index"
```

如果所处的环境中不允许使用 git 协议，可以把上述地址改为：

```bash
registry = "https://mirrors.ustc.edu.cn/crates.io-index"
1
```

注意：cargo search 无法使用镜像。