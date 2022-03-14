# Lotus常用环境变量使用说明

## 1. 通用环境变量

### FIL_PROOFS_PARAMETER_CACHE

proof 证明参数路径，默认在/var/tmp/filecoin-proof-parameters下。

```
export FIL_PROOFS_PARAMETER_CACHE=/home/user/nvme_disk/filecoin-proof-parameters
```

### FFI_BUILD_FROM_SOURCE

从源码编译底层库。

```
export FFI_BUILD_FROM_SOURCE=1
```

### IPFS_GATEWAY

配置证明参数下载的代理地址。

```
export IPFS_GATEWAY=https://proof-parameters.s3.cn-south-1.jdcloud-oss.com/ipfs/
```

### TMPDIR

临时文件夹路径，用于存放显卡锁定文件。

```
export TMPDIR=/home/user/nvme_disk/tmp
```

### RUST_LOG

配置Rust日志级别。

```
export RUST_LOG=Debug
```

GOPROXY

配置Golang代理。

```
export GOPROXY=https://goproxy.cn
```

## 2. Lotus Deamon环境变量

### LOTUS_PATH

lotus daemon 路径，例如：

```
export LOTUS_PATH=/home/user/nvme_disk/lotus
```

## 3. Lotus Miner环境变量

### LOTUS_MINER_PATH

lotus miner 路径，例如：

```
export LOTUS_MINER_PATH=/home/user/nvme_disk/lotusminer
```

### FULLNODE_API_INFO

lotus daemon API 环境变量；

```
export FULLNODE_API_INFO=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.JSdq-OviNQW2dZslvyargJsqgLrlYCjoZCIFkb2u96g:/ip4/192.168.1.10/tcp/1234/http
```

BELLMAN_CUSTOM_GPU`：指定GPU型号；

## 4. Lotus Worker环境变量

### LOTUS_WORKER_PATH

Lotus worker 路径；

```
export LOTUS_WORKER_PATH=/home/user/nvme_disk/lotusworker
```

### FIL_PROOFS_MAXIMIZE_CACHING

最大化内存参数；

```
export FIL_PROOFS_MAXIMIZE_CACHING=1
```

FIL_PROOFS_USE_MULTICORE_SDR

CPU多核心绑定；

```
export FIL_PROOFS_USE_MULTICORE_SDR=1
```

### FIL_PROOFS_USE_GPU_TREE_BUILDER

使用GPU计算Precommit2 TREE hash

```
export FIL_PROOFS_USE_GPU_TREE_BUILDER=1
```

### FIL_PROOFS_USE_GPU_COLUMN_BUILDER

使用GUP计算Precommit2 COLUMN hash；

```
export FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1
```

### FIL_PROOFS_MAX_GPU_TREE_BATCH_SIZE

高级的GPU使用率

使用GPU构建“ tree_r_last”（使用`FIL_PROOFS_USE_GPU_TREE_BUILDER=1`）时，可以对实验变量进行测试，以对您的硬件进行局部优化。

```
export FIL_PROOFS_MAX_GPU_TREE_BATCH_SIZE=700000
```

默认的批处理大小值为700,000个树节点。

### FIL_PROOFS_MAX_GPU_COLUMN_BATCH_SIZE

使用GPU构建“ tree_c”（使用`FIL_PROOFS_USE_GPU_COLUMN_BUILDER=1`）时，可以对两个实验变量进行测试，以对您的硬件进行局部优化。首先，您可以设定

```
export FIL_PROOFS_MAX_GPU_COLUMN_BATCH_SIZE=400000
```

默认值为400,000，这意味着我们一次编译了400,000列并将它们分批传递给GPU。每列是“单个节点x层数”（例如32GiB扇区有11层，因此每列由11个节点组成）。该值既可以用作合理的默认值，又可以测量出编译此大小批处理所需的时间与GPU消耗它所需的时间一样多（使用2080ti进行测试），我们并行进行此操作以最大程度地利用该值。吞吐量。如果设置得太大，更改此值可能会耗尽GPU RAM，如果设置得太低，则可能会降低性能。此设置可用于您在此步骤中进行的实验。

### FIL_PROOFS_COLUMN_WRITE_BATCH_SIZE

当存储从GPU返回的树数据时，可能影响整体“ tree_c”性能的第二个变量是并行写缓冲区的大小。该值设置为合理的默认值262,144，但是如果可以实现个人的性能优势，则可以根据需要对其进行调整。要调整此值，请使用环境变量

```
export FIL_PROOFS_COLUMN_WRITE_BATCH_SIZE=262144
```

请注意，此值会影响将列树持久化到磁盘时使用的并行度，并且如果未适当调整限制（例如使用`ulimit -n`），则可能会耗尽系统文件描述符。如果持久树由于“错误的文件描述符”错误而失败，请尝试将此值调整为更大的值（例如524288或1048576）。增大此值可一次处理较大的块，从而导致并行写入磁盘的次数更多（但更少）。

### 高级存储调整

对于持久化在磁盘上的“ tree_r_last”缓存的Merkle树，公开了一个用于调整所需存储空间量的值。缓存的merkle树类似于普通的merkle树，不同之处在于我们丢弃了基本级别以上的一些行。在丢弃过多数据时需要权衡取舍，这可能会导致在需要时重建几乎整个树。另一个极端是丢弃太少的行，这导致更高的磁盘空间利用率。选择默认值可以仔细权衡这种折衷，但是您可以根据本地硬件配置的需要对其进行调整。要调整此值，请使用环境变量

```
export FIL_PROOFS_ROWS_TO_DISCARD=N
```

请注意，如果您修改此值并使用它来密封扇区，则不能在不更新所有先前密封扇区的情况下（或者，放弃所有先前密封扇区的情况）对其进行修改。提供了用于此转换的工具，但它被认为是一项昂贵的操作，在使用新设置重新启动任何节点之前，应仔细计划和完成该工具。这样做的原因是，必须从带有新目标值FIL_PROOFS_ROWS_TO_DISCARD的密封副本文件中重建所有“ tree_r_last”树，以确保系统一致。

除非您了解修改的含义，否则不建议调整此设置。

### BELLMAN_NO_GPU

：不使用GPU计算Commit2；

- 如果要启用 GPU，则不能让这个环境变量（BELLMAN_NO_GPU）出现在系统的环境变量中（env）;
- 如果它出现在 env 中，则需要使用`unset BELLMAN_NO_GPU`命令取消，因为设置 `export BELLMAN_NO_GPU=0` 无效；

```
export BELLMAN_NO_GPU=1
```

### MINER_API_INFO

Lotus miner的API信息；

```
export MINER_API_INFO=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.JSdq-OviNQW2dZslvyargJsqgLrlYCjoZCIFkb2u96g:/ip4/192.168.1.10/tcp/1234/http
```

### BELLMAN_CUSTOM_GPU

指定Commit2的GPU型号；其中4352位cuda核心数

```
export BELLMAN_CUSTOM_GPU="GeForce RTX 2080 Ti:4352"
```