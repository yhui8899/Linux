## **LVS负载均衡部署：**

VIP地址：192.168.83.188

LVS-LB：192.168.83.129

ReadServer1：192.168.83.130

ReadServer2：192.168.83.137

因为LVS是Linux的内核模块所以只要安装ipvsadm管理工具即可：

**安装LVS管理工具：**

**1）源码安装ipvsadm：**

wget  -c  

http://www.linuxvirtualserver.org/software/kernel-2.6/ipvsadm-1.24.tar.gz 

ln -s /usr/src/kernels/2.6.*  /usr/src/linux

tar xzvf ipvsadm-1.24.tar.gz 

cd ipvsadm-1.24 

make 

make install

**2）yum安装ipvsadm：**

yum  install ipvsadm* -y

**添加如下：**

ipvsadm -A -t 192.168.83.188:80 -s rr

ipvsadm -a -t 192.168.83.188:80 -r 192.168.83.130 -g -w 2

ipvsadm -a -t 192.168.83.188:80 -r 192.168.83.137 -g -w 2

**在LD中绑定子网卡**

cd /etc/sysconfig/network-scripts/

cp ifcfg-ens33 ifcfg-ens33:1

输入如下信息：

BOOTPROTO=static
IPV6INIT=yes
DEVICE=ens33:1
ONBOOT=yes
IPADDR=192.168.83.188
NETMASK=255.255.255.0

**启动子网卡**：ifup  ens33:1

**在RS中绑定VIP：后端的两台机器操作都是一样的**

 cd /etc/sysconfig/network-scripts/

cp ifcfg-lo  ifcfg-lo:1

**输入如下信息：**

DEVICE=lo:1
IPADDR=192.168.83.188
NETMASK=255.255.255.255
ONBOOT=yes
NAME=loopback

**启动lo:1子网卡：**

ifup lo:1

最后访问：http://192.168.83.128即可打开后端的web页面即表示正常；

