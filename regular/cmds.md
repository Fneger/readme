mount -t nfs -o nolock 192.168.1.11:/nfs /mnt/wnfs/

查看显卡性能

nvtop 

# netplay 配置网络

打开配置文件
vim /etc/netplan/*.yaml
测试配置文件
sudo netplan try
如果没问题，可以继续往下应用。
sudo netplan apply
重启网络服务
sudo systemctl restart system-networkd
如果是桌面版：
sudo systemctl restart network-manager

验证 IP 地址
ip a

## Netplan 配置文件详解

### 1、使用 DHCP：

network:
  version: 2
  renderer: networkd
  ethernets:
    enp3s0:
      dhcp4: true
      

### 2.使用静态 IP：

network:
  version: 2
  renderer: networkd
  ethernets:
    enp3s0:
      addresses:
        - 10.10.10.2/24
            gateway4: 10.10.10.1
            nameservers:
          search: [mydomain, otherdomain]
          addresses: [10.10.10.1, 1.1.1.1]
          

### 3、多个网口 DHCP：

network:
  version: 2
  ethernets:
    enred:
      dhcp4: yes
      dhcp4-overrides:
        route-metric: 100
    engreen:
      dhcp4: yes
      dhcp4-overrides:
        route-metric: 200

----------------------------------------------------------------

查看服务器22端口是否启动。

```
lsof -i:22
```

# 显卡驱动安装

[nvidia官网下载驱动](https://www.nvidia.cn/geforce/drivers/)

选择相应版本，例如NVIDIA-Linux-x86_64-460.56.run驱动

在安装之前，我提前安装了make以及gcc

```
sudo apt install make
sudo apt install gcc
```

安装驱动文件

```
sudo bash NVIDA-Linux-x86_64-460.56.run
```

查看显卡状态

```
nvidia-smi
```

之后需要禁用nouveau，在禁用之前，使用下面这句，能看到很多与nouveau相关的进程

```
lsmod | grep nouveau
```

之后使用gedit打开黑名单文件

```
sudo gedit /etc/modprobe.d/blacklist.conf
```

然后在文件末尾加上

```
blacklist nouveau
```

保存之后，在终端运行

```html
sudo update-initramfs -u
```

显卡驱动安装完成，重启之后就可以正常运行。

# 磁盘操作

显示某个文件系统的挂信息

```
df /dev/sda2
```

# rust 使用国内镜像，快速安装方法

[参考博文](https://www.cnblogs.com/hustcpp/p/12341098.html)

## 前言

由于rustup官方服务器在国外
 如果直接按照rust官网的安装方式安装非常容易失败，即使不失败也非常非常慢
 如果用国内的镜像则可以分分钟就搞定

## 官方安装方法

文档： https://www.rust-lang.org/tools/install

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

使用国内镜像的方法

1. 首先修改一下上面的命令，将安装脚本导出

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rust.sh
```

1. 打开 rust.sh 脚本

```
  8 
  9 # If RUSTUP_UPDATE_ROOT is unset or empty, default it.
 10 RUSTUP_UPDATE_ROOT="${RUSTUP_UPDATE_ROOT:-https://static.rust-lang.org/rustup}"
 11 
```

将 RUSTUP_UPDATE_ROOT 修改为

```
RUSTUP_UPDATE_ROOT="http://mirrors.ustc.edu.cn/rust-static/rustup"
```

这是用来下载 rustup-init 的， 修改后通过国内镜像下载

1. 修改环境变量

```
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
```

这让 rustup-init从国内进行下载rust的组件，提高速度

1. 最后执行修改后的rust.sh

```
bash rust.sh
```

## 更简便的方法那就是手动安装

```
wget https://mirrors.ustc.edu.cn/rust-static/rustup/dist/x86_64-apple-darwin/rustup-init  
```

然后执行

```
RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup rustup-init 
```

最后

rust 安装后，会在home目录创建 .cargo/env，为了以后都从国内镜像源下载包，可以将上面的环境变量加入到env文件

```
echo "RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup"  >> ~./ .cargo/env  
```



# 阵列卡使用

## LSI 9361

查看磁盘阵列卡信息

```
dmesg |grep -i raid
cat /proc/scsi/scsi
lsscsi
```

