## KVM虚拟机部署和管理（单机）

KVM是一个内核模块，无需安装，只需要装一些管理工具即可

#### 检测环境：查看宿主机支持 cpu 的硬件虚拟化技术

grep -E "vmx|svm" /proc/cpuinfo   

Intel 是 vmx，AMD 是svm

----------------

#### 安装qemu-kvm、libvirt

libvirt：用来管理kvm的一个工具

```
yum  install qemu qemu-kvm  libvirt  virt-install  -y
```

#### 创建虚拟机硬盘：

```
qemu-img create -f raw /opt/CentOS-7-x86_64.raw 10G
# -f ：	指定格式，指定硬盘的位置，指定大小，会创建一个raw格式的硬盘文件
创建完成之后使用file来查看一下：
file /opt/CentOS-7-x86_64.raw 
[root@localhost ~]# file /opt/CentOS-7-x86_64.raw 
/opt/CentOS-7-x86_64.raw: data
```

1、KVM默认监听了VNC的5900端口，所以需要使用VMC来连接，需要安装一个VNC客户端在电脑上，KVM监听的VNC默认端口5900，延伸是5901、5902......等

2、需要将ISO镜像放到刚刚创建磁盘在同一个目录下，方便安装使用；

----------------------

#### 启动libvirt服务：

```
systemctl  start libvirtd
----------------------------------------------------------------------------
#libvirt 启动后会自动生成一个桥接网卡：virbr0和vnet0
virbr0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.122.1  netmask 255.255.255.0  broadcast 192.168.122.255
        ether 52:54:00:30:8d:ae  txqueuelen 1000  (Ethernet)
        RX packets 75  bytes 5536 (5.4 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 63  bytes 7874 (7.6 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
----------------------------------------------------------------------------        
#同时默认还会启动一个dnsmasq服务，
dnsmasq服务的配置文件默认是：/var/lib/libvirt/dnsmasq/default.conf
[root@localhost opt]# cat /var/lib/libvirt/dnsmasq/default.conf
##WARNING:  THIS IS AN AUTO-GENERATED FILE. CHANGES TO IT ARE LIKELY TO BE
##OVERWRITTEN AND LOST.  Changes to this configuration should be made using:
##    virsh net-edit default
## or other application using the libvirt API.
##
## dnsmasq conf file created by libvirt
strict-order
pid-file=/var/run/libvirt/network/default.pid
except-interface=lo
bind-dynamic
interface=virbr0
dhcp-range=192.168.122.2,192.168.122.254
dhcp-no-override
dhcp-authoritative
dhcp-lease-max=253
dhcp-hostsfile=/var/lib/libvirt/dnsmasq/default.hostsfile
addn-hosts=/var/lib/libvirt/dnsmasq/default.addnhosts
```

#### 执行安装命令：

```
virt-install --virt-type kvm --name CentOS-7-x86_64 --ram 1024 --cdrom=/opt/CentOS-7-x86_64-DVD-1810.iso --disk path=/opt/CentOS-7-x86_64.raw --network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole
命令参数详解：
# --virt-type kvm：指定安装类型是：KVM
# --name CentOS-7-x86_64	指定的名称是：CentOS-7-x86_64
# --ram 1024		分配内存：1024
# --cdrom=/opt/CentOS-7-x86_64-DVD-1810.iso		指定ISO镜像
# --disk path=/opt/CentOS-7-x86_64.raw		指定磁盘文件：CentOS-7-x86_64.raw	
# --network network=default			#指定网络：default，指定的default就是：vnet0网卡
# --graphics vnc,listen=0.0.0.0 --noautoconsole	 启动VNC的图形界面，监听地址：0.0.0.0
-------------------------------------------------------------------------------------
会出现如下信息：
[root@localhost opt]# virt-install --virt-type kvm --name CentOS-7-x86_64 --ram 1024 --cdrom=/opt/CentOS-7-x86_64-DVD-1810.iso --disk path=/opt/CentOS-7-x86_64.raw --network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole

开始安装......
域安装仍在进行。您可以重新连接
到控制台以便完成安装进程。
#看到如上信息后，立刻使用VNC工具连接安装即可；
```

#### 设置网卡名称为:eth0

在VNC图形界面连接成功后会看到安装界面，把光标移动到Install CentOS 7，然后使用TAB键移动到最后输入如下命令然后按回车即可：

```
net.ifnames=0 biosdevname=0
```

根据提示完成操作系统安装即可；

-----------------------

### KVM命令：

```
virsh list --all				#查看所有的虚拟机
virsh start CentOS-7			#启动CentOS-7 虚拟机
```

使用brctl创建桥接网卡，使虚拟机和主机在同一个网段

```
brctl addbr br0					#创建一个br0网卡
brctl show						#查看网卡
[root@localhost opt]# brctl show
bridge name     bridge id               STP enabled     interfaces
br0             8000.000000000000       no
virbr0          8000.525400308dae       yes             virbr0-nic
--------------------------------------------------------------------
把宿主机的ens33桥接到br0这个网卡上
brctl addif br0 ens33		
#注意，桥接后网络会断开，需要把ens33的IP地址设置到br0上面才行，操作如下：
1、删除ens33网卡IP： ip addr del dev ens33 192.168.83.129/24
2、配置br0网卡IP： ifconfig br0 192.168.83.129/24 up
3、添加路由网关：route add default gw 192.168.83.2
--------------------------------------------------------------------

```

KVM虚拟机创建完成后会生成 一个配置文件：/etc/libvirt/qemu/CentOS-7.xml，该配置文件是虚拟机的所有配置信息都在里面，注意切勿使用vim来修改此配置文件，需要使用：virsh edit CentOS-7 来修改，虚拟机的配置基本上是修改这个xml文件来添加或修改配置

把虚拟机修改为桥接网卡的模式：

virsh edit CentOS-7

```
把默认的网卡信息：
 <interface type='network'>
      <mac address='52:54:00:c4:93:ad'/>
      <source network='default'/>	
改为：
 <interface type='bridge'>		#把默认的type='network'改为：type='bridge'
      <mac address='52:54:00:c4:93:ad'/>
      <source bridge='br0'/>	#把默认的network='default'改为：bridge='br0'

#bridge 桥接的意思
```

启动虚拟机：

```
virsh start CentOS-7
```

使用VNC登录之后如果启用了DHCP就会自动获取一个与宿主机同一网段的IP地址

--------------------------

### KVM虚拟机配置修改

由于虚拟机有可能需要增加配置如：CPU、内存等，都是修改虚拟机的xml配置文件：

##### 在宿主机上面操作

#### 配置CPU：

virsh edit CentOS-7

```
找到CPU对应的配置：<vcpu placement='static'>1</vcpu>	#目前CPU的分配模式是静态的，1颗CPU
可以修改为动态的： <vcpu placement='auto' current="1">2</vcpu>	#分配模式改为：auto 支持热添加，current="1">2表示当前的CPU是1个，最大是2个。
#改完之后需要重启虚拟机
#current：当前的意思；
```

修改完虚拟机的xml文件后就等于CPU支持热添加了，修改完配置文件后需要重启生效，其实也可以在创建虚拟机的之后把参数加上: --vcpus 4  maxcpus=8  表示分配4个CPU给虚拟机，最大可用分配8个；

重启后执行如下命令：

```
virsh setvcpus CentOS-7 2 --live			#表示把虚拟机分配2个CPU
```

查看第二个CPU是否是开启状态：

```
cat /sys/devices/system/cpu/cpu1/online  
或者：
cat /proc/interrupts			#显示有2个CPU在工作表示正常
```



### 配置内存：

在宿主机上面操作

virsh edit CentOS-7

```
找到内存配置代码：
<memory unit='KiB'>1048576</memory>		#最大可用内存是1G
<currentMemory unit='KiB'>1048576</currentMemory>	#当前内存1G
改为：
<memory unit='KiB'>4048576</memory>		#最大可用内存改为了4G
<currentMemory unit='KiB'>1048576</currentMemory>	
#改完之后需要重启虚拟机
```

查看虚拟机当前的内存：

```
virsh qemu-monitor-command CentOS-7 --hmp --cmd info balloon
-------------------------------------------------------------
查看虚拟机内存
[root@localhost ~]# virsh qemu-monitor-command CentOS-7 --hmp --cmd info balloon
balloon: actual=1024
```

给虚拟机加大内存：

```
virsh qemu-monitor-command CentOS-7 --hmp --cmd balloon 4096  #给虚拟机内存加到4G了
查看虚拟机内存：
[root@localhost ~]# virsh qemu-monitor-command CentOS-7 --hmp --cmd info balloon
balloon: actual=3954
#看到如上信息表示虚拟机内存热添加成功；
```

-------------------------------------

KVM安装Windows虚拟机：

参考：https://www.unixhot.com/article/70

下载Windows的Virtio驱动程序：

```
https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/
```

创建磁盘：

```
qemu-img create -f raw /opt/windows2008.raw 10G
```

创建Windows2008虚拟机：

```
virt-install --virt-type kvm --name windows2008 --vcpus 2 --memory 2048 --cdrom /opt/windows_server_2008r2.iso --disk path=/opt/windows2008.raw,device=disk,bus=virtio  --network bridge=br0 --graphics vnc,listen=0.0.0.0 --noautoconsole --os-type=windows --disk path=/opt/virtio/virtio-win-1.7.4.iso,device=floppy  --os-type=windows --os-variant win2k8 --boot cdrom
#-network bridge=br0 	指定网络模式bridge桥接模式，绑定br0网卡
# --disk path=/opt/virtio/virtio-win-1.7.4.iso	指定驱动文件
# device=floppy		#设备类型软驱，用来装载virtio驱动，rloppy 软驱的意思
# --os-type=windows		#指定OS类型：windows
```

使用VNC连接进行安装根据提示安装完成即可；

参考：https://www.unixhot.com/article/70