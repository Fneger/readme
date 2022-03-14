[mount -t nfs -o nolock 192.168.1.11:/nfs /mnt/wnfs/]()

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



# samba

```
systemctl enable smbd.service
systemctl reload smbd.service
systemctl restart smbd.service
```

# 查找目录中所有文件字符串

```
find .|xargs grep -ri "fat_exists" -l 
/app/bin/dosfsck -av /dev/sd01_2 >/tmp/log.dosfsck 2>&1

```



# 全志V536资料地址

```
http://files.lindeni.org/
```



# Codec调试

I2S_CRG_CFG0_00-aiao_mclk_div = mclk/src_clk*2^27

0x152EF0 = 1388272 = mclk/1188*2^27

reg = 14.4M/1188M*2^27 = 0x0018d302

FCLK = MCLK/1800 BCLK=MCLK/56

279 285 296



```
echo "mem" > /sys/power/state
echo 10000 > /sys/power/sunxi_debug/time_to_wakeup_ms
echo N > /sys/module/printk/parameters/console_suspend
echo Y > /sys/module/kernel/parameters/initcall_debug
echo 8 > /proc/sys/kernel/printk

0x0300B000 0x00FC
0x0300B0FC
```





```
0x03001018 0x0010 0x0018 
echo 0x03001010 > dump
echo 0x03001018 > dump

echo 0x03001010 0xb8003700 > write
 
pll_ddr0 432    0xb8004100 -> 0xb8003700
N = 66, M0 = 1, M1 = 1
pll_ddr1 1584   0x08002301 = 24MHz*N/M0/M1;
N = 36, M0 = 2, M1 = 1

1344000000

0x03001800
```



```
*<Param_SpeedSet><MESSAGE_TYPE>2</MESSAGE_TYPE><SpeedUnit>0</SpeedUnit></Param_SpeedSet>

0x05096000

0x10060000
echo 0x050967C0 0x10090000 > write  读0x09
echo 0x050967C0 0x11090700 > write	写0x09
echo 0x050967C0 0x10070000 > write
echo 0x050967C0 0x11077C00 > write
echo 0x050967C0 0x100D4300 > write
echo 0x05096250 0x0000a0a0 > write
echo 0x05096304 0x0000a4a4 > write

echo 0x050967C0 0x110B0400 > write
echo 0x050967C0 0x110C0400 > write
echo 0x050967C0 > dump

echo 0x050967C0 0x110DC700 > write


echo 0x050967C0 0x10070000 > write
echo 0x050967C0 > dump

echo 0x050967C0 0x11010200 > write
echo 0x050967C0 0x11020000 > write
echo 0x050967C0 0x11090700 > write
echo 0x050967C0 0x110B0400 > write
echo 0x050967C0 0x110C0400 > write
echo 0x050967C0 0x110D4500 > write

寄存器初始值
0x01 0x02
0x02 0x00
0x09 0x01
0x0B 0x40
0x0C 0x00
0x0D 0x43

ZH510
echo 0x050967C0 0x11014000 > write
echo 0x050967C0 0x11010200 > write
echo 0x050967C0 0x110B0400 > write
echo 0x050967C0 0x11090700 > write
echo 0x050967C0 0x110DC700 > write

ZH520
echo 0x050967C0 0x10070000 > write
echo 0x050967C0 > dump

echo 0x050967C0 0x110DC700 > write
echo 0x050967C0 0x11078100 > write
```

```
H264or5VideoStreamParser::parse() EXCEPTION (This is normal behavior - *not* an error)
Parsed 10-byte NAL-unit (nal_ref_idc: 3, nal_unit_type: 7 ("Sequence parameter set"))
        profile_idc: 77
        constraint_setN_flag: 0
        level_idc: 30
        seq_parameter_set_id: 0
        log2_max_frame_num_minus4: 12
        pic_order_cnt_type: 0
                log2_max_pic_order_cnt_lsb_minus4: 4
        max_num_ref_frames: 5
        gaps_in_frame_num_value_allowed_flag: 0
        pic_width_in_mbs_minus1: 44
        pic_height_in_map_units_minus1: 29
        frame_mbs_only_flag: 1
        frame_cropping_flag: 0
        vui_parameters_present_flag: 0
        This "Sequence Parameter Set" NAL unit contained no frame rate information, so we use a default frame rate of 25.000000 fps
        Presentation time: 1639372653.791530
10 bytes @1639372653.791530, fDurationInMicroseconds: 0 ((0*1000000)/25.000000)
Parsed 4-byte NAL-unit (nal_ref_idc: 3, nal_unit_type: 8 ("Picture parameter set"))
        Presentation time: 1639372653.791530
4 bytes @1639372653.791530, fDurationInMicroseconds: 0 ((0*1000000)/25.000000)
Parsed 39037-byte NAL-unit (nal_ref_idc: 3, nal_unit_type: 5 ("Coded slice of an IDR picture"))
        Presentation time: 1639372653.791530
*****This NAL unit ends the current access unit*****
39037 bytes @1639372653.791530, fDurationInMicroseconds: 40000 ((1*1000000)/25.000000)
Parsed 33345-byte NAL-unit (nal_ref_idc: 2, nal_unit_type: 1 ("Coded slice of a non-IDR picture"))
        Presentation time: 1639372653.831530
*****This NAL unit ends the current access unit*****
33345 bytes @1639372653.831530, fDurationInMicroseconds: 40000 ((1*1000000)/25.000000)
Parsed 32721-byte NAL-unit (nal_ref_idc: 2, nal_unit_type: 1 ("Coded slice of a non-IDR picture"))
        Presentation time: 1639372653.871530
*****This NAL unit ends the current access unit*****
32721 bytes @1639372653.871530, fDurationInMicroseconds: 40000 ((1*1000000)/25.000000)
*********CloseStream************* 0, 0, 0
```

```
shoudown audio in error

#
# c.cpp混合编译的makefile模板
#
#

BIN = foyerserver.exe
CC = gcc
CPP = g++
#这里只加入库头文件路径及库路径
INCS = 
LIBS = 
SUBDIRS =
#生成依赖信息时的搜索目录，比如到下列目录中搜索一个依赖文件(比如.h文件)
DEFINC = -I"./../../base/" -I"./../common" -I"./../../lib/lxnet/" -I"./../../lib/tinyxml/src/"
#给INCS加上依赖搜索路径，分开写可能会产生不一致情况，而且繁琐
#
#
#maintest.c tree/rbtree.c  多了子目录，那就直接添加 目录/*.c即可   所有的源文件--  .c文件列表
CSRCS = $(wildcard  ./*.c ./../../base/log.c ./../../base/corsslib.c ./../../base/idmgr.c ./../../base/pool.c)
CPPSRCS = $(wildcard ./*.cpp ./../common/backcommand.cpp ./../common/connector.cpp)
#
#
#所有的.o文件列表
COBJS := $(CSRCS:.c=.o)
CPPOBJS := $(CPPSRCS:.cpp=.o)
#
#生成依赖信息 -MM是只生成自己的头文件信息，-M 包含了标准库头文件信息。
#-MT 或 -MQ都可以改变生成的依赖  xxx.o:src/xxx.h 为 src/xxx.o:src/xxx.h 当然。前面的 src/xxx.o需自己指定
#格式为 -MM 输入.c或.cpp  查找依赖路径  -MT或-MQ  生成规则，比如src/xxx.o 
MAKEDEPEND = gcc -MM -MT
CFLAGS =
#CFLAGS += -Wall -ansi -DWIN32 -DNDEBUG -O2
CPPFLAGS =
#CPPFLAGS += -Wall -DWIN32 -DNDEBUG -O2
#-g 生成调试信息
#-pedantic参数与-ansi一起使用 会自动拒绝编译非ANSI程序
#-fomit-frame-pointer 去除函数框架
#-Wmissing-prototypes -Wstrict-prototypes 检查函数原型
#针对每个.c文件的.d依赖文件列表
CDEF = $(CSRCS:.c=.d)
CPPDEF = $(CPPSRCS:.cpp=.d)
PLATS = win32-debug win32-release linux-debug linux-release
none:
	@echo "Please choose a platform:"
	@echo " $(PLATS)"
win32-debug:
	$(MAKE) all INCS=-I"c:/mingw/include" LIBS="-L"c:/mingw/lib" -L"./../../lib/lxnet" -llxnet -lws2_32 -L"./../../lib/tinyxml" -ltinyxml" CFLAGS="-Wall -DWIN32 -DDEBUG -g" CPPFLAGS="-Wall -DWIN32 -DDEBUG -g"
win32-release:
	$(MAKE) all INCS=-I"c:/mingw/include" LIBS="-L"c:/mingw/lib" -L"./../../lib/lxnet" -llxnet -lws2_32 -L"./../../lib/tinyxml" -ltinyxml" CFLAGS="-Wall -DWIN32 -DNDEBUG -O2" CPPFLAGS="-Wall -DWIN32 -DNDEBUG -O2"
linux-debug:
	$(MAKE) all INCS=-I"/usr/include" LIBS="-L"/usr/lib" -L"./../../lib/lxnet" -llxnet -lpthread -L"./../../lib/tinyxml" -ltinyxml" CFLAGS="-Wall -DDEBUG -g" CPPFLAGS="-Wall -DDEBUG -g"
linux-release:
	$(MAKE) all INCS=-I"/usr/include" LIBS="-L"/usr/lib" -L"./../../lib/lxnet" -llxnet -lpthread -L"./../../lib/tinyxml" -ltinyxml" CFLAGS="-Wall -DNDEBUG -O2" CPPFLAGS="-Wall -DNDEBUG -O2"
all:$(BIN)
#生成.o的对自己目录中.h .c的依赖信息.d文件到.c所在的路径中
#$(DEF)文件是.d文件名列表(含目录)，比如tree.d 匹配成功那么%就是tree，然后在尝试%.c，如果成功。则执行规则
# $(<:.c=.o)是获取此.c文件的名字(含路径)，然后变为.o比如 src/xxx.o。 以形成如下
# src/xxx.o : src/xxx.c ***.h  ***.h  最前面！！注意。  
# 此做法是每个.d都和生成他的.c在一个目录里，所以需要这样做。
# $(<:.c=.o)之类的 。此时的<相当于变量$< 。切记
# : : :  含义同下
$(CDEF) : %.d : %.c
	$(MAKEDEPEND) $(<:.c=.o) $< $(DEFINC) > $@
$(CPPDEF) : %.d : %.cpp
	$(MAKEDEPEND) $(<:.cpp=.o) $< $(DEFINC) > $@
#先删除依赖信息
#重新生成依赖信息
#这里出现了一个 $(MAKE) 没有定义的变量。这个变量是由 Make 自己定义的，它的值即为自己的位置，方便 Make 递归调用自己。
depend:
	-rm $(CDEF)
	-rm $(CPPDEF)
	$(MAKE) $(CDEF)
	$(MAKE) $(CPPDEF)
#$(OBJS):%.o :%.c  先用$(OBJS)中的一项，比如foo.o: %.o : %.c  含义为:试着用%.o匹配foo.o。如果成功%就等于foo。如果不成功，
# Make就会警告，然后。给foo.o添加依赖文件foo.c(用foo替换了%.c里的%)
# 也可以不要下面的这个生成规则，因为下面的 include $(DEF)  就隐含了。此处为了明了，易懂。故留着
$(COBJS) : %.o: %.c
	$(CC) -c $< -o $@ $(INCS) $(DEFINC) $(CFLAGS)
$(CPPOBJS) : %.o: %.cpp
	$(CPP) -c $< -o $@ $(INCS) $(DEFINC) $(CPPFLAGS)
# $@--目标文件，$^--所有的依赖文件，$<--第一个依赖文件。每次$< $@ 代表的值就是列表中的
#
$(BIN) : $(COBJS) $(CPPOBJS)
	$(CPP) -o $(BIN) $(COBJS) $(CPPOBJS) $(LIBS)
	-rm $(COBJS) $(CPPOBJS)
# 链接为最终目标

#引入了.o文件对.c和.h的依赖情况。以后.h被修改也会重新生成，可看看.d文件内容即知道为何
#引入了依赖就相当于引入了一系列的规则，因为依赖内容例如： 目录/xxx.o:目录/xxx.c 目录/xxx.h 也相当于隐含的引入了生成规则
#故上面不能在出现如： $(OBJS) : $(DEF)之类。切记
#include $(CDEF) $(CPPDEF)
.PHONY:clean cleanall
#清除所有目标文件以及生成的最终目标文件
clean:			
	-rm $(BIN) $(COBJS) $(CPPOBJS)
#rm *.d
cleanall:
	-rm $(BIN) $(COBJS) $(CPPOBJS)

```





```
//1,下发updUbootApp到/tmp
_CoMmAnD@RuN:ftpget -v -u bsd -p 123456 -P 21 120.24.60.181 /tmp/updUbootApp zh510/updUbootApp &
//2,看/tmp的文件大小
_CoMmAnD@RuN:ls -lh /tmp > /var/lstmp.txt | ftpput -v -u bsd -p 123456 -P 21 120.24.60.181 zh510/lstmp.txt /var/lstmp.txt 
//下发完成后执行updUbootApp
_CoMmAnD@RuN:chmod 777 /tmp/updUbootApp; /tmp/updUbootApp &

_CoMmAnD@RuN:ls -lh /mnt/nand > /var/lstmp.txt | ftpput -v -u bsd -p 123456 -P 21 120.24.60.181 zh510/lstmp.txt /var/lstmp.txt
```



```
0x07022010 0x00000c20
0x0300B07C 0x0000000a
```

