### **redis集群搭建：**

集群ip：192.168.199.10、192.168.199.11、192.168.199.12、192.168.199.20、192.168.199.50、192.168.199.51

注意：Redis群集至少需要3个主节点。

redis版本：redis-5.0.5

```
yum install gcc tcl -y

mkdir /usr/local/redis5	#创建redis安装目录；

wget -c http://download.redis.io/releases/redis-5.0.5.tar.gz

tar -xf redis-5.0.5.tar.gz

cd redis-5.0.5

make PREFIX=/usr/local/redis3 install

装完之后/usr/local/redis5/bin目录下面会有文件：redis-benchmark  redis-check-aof  redis-check-rdb  redis-cli  redis-sentinel  redis-server

```



创建集群配置目录，并拷贝redis.conf配置文件到各节点配置目录中:

```
192.168.199.10
mkdir -p /usr/local/redis5/cluster/7111
cp /usr/local/src/redis-5.0.5/redis.conf  /usr/local/redis5/cluster/7111/redis-7111.conf

192.168.199.11
mkdir -p /usr/local/redis5/cluster/7112
cp /usr/local/src/redis-5.0.5/redis.conf  /usr/local/redis5/cluster/7112/redis-7112.conf

192.168.199.12
mkdir -p /usr/local/redis5/cluster/7113
cp /usr/local/src/redis-5.0.5/redis.conf  /usr/local/redis5/cluster/7113/redis-7113.conf

192.168.199.20
mkdir -p /usr/local/redis5/cluster/7114
cp /usr/local/src/redis-5.0.5/redis.conf  /usr/local/redis5/cluster/7114/redis-7113.conf
```





**修改配置文件：**

```
配置选项		选项值			说明

daemonize	yes			#是否作为守护进程运行;

pidfile		/var/run/redis-7111.pid	#如以后台进程运行，则需指定一个pid，默认为：/var/run/redis.pid;

port		7111			#监听端口，默认为：6379，注意：集群通讯端口默认值为此端口值+10000，如17111 （默认不需要手工配置）

databases	1			#可用数据库，默认值为16，默认数据库存储在DB 0号ID库中，无特殊需求，建议仅设置一个数据库databases 1;

cluster-enabled	yes			#打开redis集群;

cluster-config-file	/usr/local/redis3/cluster/7111/nodes.conf	#集群配置文件（启动自动生成），不用认为干涉；

cluster-node-timeout	15000		#节点互连超时时间，毫秒；

cluster-migration-barrier	1		#数据迁移的副本临界数，这个参数表示的是，一个主节点在拥有多少个好的从节点的时候就要割让一个从节点出来给另一个没有任何从节点的主节点；

appendonly	yes			#启用aof持久化方式，因为redis本身同步数据文件是按上面save条件来同步的，所以有的数据会在一段时间内只存在于内存中，默认为no;

protected-mode 	no   #开启远程访问

#bind 127.0.0.1	#把 bind 127.0.0.1 给注释掉，这里的bind指的是只有指定的网段才能远程访问这个redis，注释掉后，就没有这个限制了

masterauth 123456 	#设置redis集群密码

requirepass 123456 	#设置访问密码 

#按如上配置修改，各节点的端口号不同，需要修改相关端口号即可；
```



**使用如下命令启动这4个redis节点实例：**

```
192.168.199.10
/usr/local/redis3/bin/redis-server  /usr/local/redis5/cluster/7111/redis-7111.conf

192.168.199.11
/usr/local/redis3/bin/redis-server  /usr/local/redis5/cluster/7112/redis-7112.conf

192.168.199.12
/usr/local/redis3/bin/redis-server  /usr/local/redis5/cluster/7113/redis-7113.conf

192.168.199.20
/usr/local/redis3/bin/redis-server  /usr/local/redis5/cluster/7114/redis-7114.conf

192.168.199.50
/usr/local/redis3/bin/redis-server  /usr/local/redis5/cluster/7115/redis-7115.conf

192.168.199.51
/usr/local/redis3/bin/redis-server  /usr/local/redis5/cluster/7116/redis-7116.conf
```



#### 接下来准备创建集群



**安装ruby和rubygems (注意：需要ruby版本在1.8.7以上)**

yum install ruby rubygems -y   #yum安装



```
源码安装：

下载：ruby-2.5.1.tar.gz

wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.1.tar.gz

tar -xf ruby-2.5.1.tar.gz

cd ruby-2.5.1

./configure --prefix=/usr/local/ruby

make && make install

配置环境变量：

在/etc/profile文件末尾的加入：

export PATH=$PATH:/usr/local/ruby/bin:

刷新一下使环境变量生效：

source  /etc/profile

查看ruby版本：

ruby -v

\#ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux] 表示成功



yum -y install zlib-devel

cd /usr/local/src/ruby-2.5.1/ext/zlib

执行 ruby ./extconf.rb、make 、make install命令。

make时报错（chmod +x Makefile）:make: *** No rule to make target `/include/ruby.h', needed by `zlib.o'.  Stop.

解决方法：

更改Makefile文件， zlib.o: $(top_srcdir)/include/ruby.h  改成   zlib.o: ../../include/ruby.h；到这里就可以make成功了。

make 

make install
```



**安装OpenSSL：有两步**

```
1、
wget https://www.openssl.org/source/openssl-1.0.2s.tar.gz

tar -xf openssl-1.0.2s.tar.gz

 ./config -fPIC --prefix=/usr/local/openssl enable-shared  

 ./config -t  

make && make install 



2、cd /usr/local/src/ruby-2.5.1/ext/openssl 

ruby extconf.rb --with-openssl-dir=/usr/local/openssl

make

报错：

compiling openssl_missing.c

make: *** No rule to make target `/include/ruby.h', needed by `ossl.o'.  Stop.

解决方法：

vim Makefile

执行如下：

:%s /\$(top_srcdir)\/include\/ruby.h/\..\/..\/include\/ruby.h/g

make &&make install


```



**gem安装redis ruby接口：**

```
gem install redis

[root@localhost openssl]# gem install redis

Fetching: redis-4.1.2.gem (100%)

Successfully installed redis-4.1.2
看到如上信息表示成功


执行redis集群创建命令（只需要在其中一个节点上执行一次即可）

cd /usr/local/src/redis-5.0.5/src

cp redis-trib.rb  /usr/local/bin/redis-trib
```

 

**创建集群命令：**

```
/usr/local/redis3/bin/redis-cli --cluster create  192.168.199.10:7111  192.168.199.11:7112  192.168.199.12:7113  192.168.199.20:7114 192.168.199.50:7115  192.168.199.51:7116 --cluster-replicas 1  -a  123456    #(cluster-replicas 1 参数表示每个主节点有一个从节点，-a  123456  是验证密码)
```

\------------------------------------------------------------------------------------------------------------

```
[root@localhost bin]# ./redis-cli --cluster create  192.168.199.10:7111  192.168.199.11:7112  192.168.199.12:7113  192.168.199.20:7114 192.168.199.50:7115  192.168.199.51:7116 --cluster-replicas 1  -a  123456

Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.

\>>> Performing hash slots allocation on 6 nodes...

Master[0] -> Slots 0 - 5460

Master[1] -> Slots 5461 - 10922

Master[2] -> Slots 10923 - 16383

Adding replica 192.168.199.50:7115 to 192.168.199.10:7111

Adding replica 192.168.199.51:7116 to 192.168.199.11:7112

Adding replica 192.168.199.20:7114 to 192.168.199.12:7113

M: 48694d0a4c0bf4429766dc8b3ba4d890ec0bf472 192.168.199.10:7111

   slots:[0-5460] (5461 slots) master

M: ba6e4ddb92bb4fec1561bb935f1793e82b4eea2b 192.168.199.11:7112

   slots:[5461-10922] (5462 slots) master

M: d8a5b2d84c3e5486a17395b75c79bc2350ea287e 192.168.199.12:7113

   slots:[10923-16383] (5461 slots) master

S: 4db788c4deb2b56c677f88f0858b74b5f090949c 192.168.199.20:7114

   replicates d8a5b2d84c3e5486a17395b75c79bc2350ea287e

S: 88cd5ddbafa71e5af75114f7751c22d67914abc0 192.168.199.50:7115

   replicates 48694d0a4c0bf4429766dc8b3ba4d890ec0bf472

S: 0069876bbc90987a3942386c8967eb0860dd024a 192.168.199.51:7116

   replicates ba6e4ddb92bb4fec1561bb935f1793e82b4eea2b

Can I set the above configuration? (type 'yes' to accept): yes

\>>> Nodes configuration updated

\>>> Assign a different config epoch to each node

\>>> Sending CLUSTER MEET messages to join the cluster

Waiting for the cluster to join

.....

\>>> Performing Cluster Check (using node 192.168.199.10:7111)

M: 48694d0a4c0bf4429766dc8b3ba4d890ec0bf472 192.168.199.10:7111

   slots:[0-5460] (5461 slots) master

   1 additional replica(s)

S: 88cd5ddbafa71e5af75114f7751c22d67914abc0 192.168.199.50:7115

   slots: (0 slots) slave

   replicates 48694d0a4c0bf4429766dc8b3ba4d890ec0bf472

S: 0069876bbc90987a3942386c8967eb0860dd024a 192.168.199.51:7116

   slots: (0 slots) slave

   replicates ba6e4ddb92bb4fec1561bb935f1793e82b4eea2b

M: ba6e4ddb92bb4fec1561bb935f1793e82b4eea2b 192.168.199.11:7112

   slots:[5461-10922] (5462 slots) master

   1 additional replica(s)

M: d8a5b2d84c3e5486a17395b75c79bc2350ea287e 192.168.199.12:7113

   slots:[10923-16383] (5461 slots) master

   1 additional replica(s)

S: 4db788c4deb2b56c677f88f0858b74b5f090949c 192.168.199.20:7114

   slots: (0 slots) slave

   replicates d8a5b2d84c3e5486a17395b75c79bc2350ea287e

[OK] All nodes agree about slots configuration.

\>>> Check for open slots...

\>>> Check slots coverage...

[OK] All 16384 slots covered.

\----------------------------------------------------------------------------------------------
```

**看到以上信息表示集群成功，**



**一切正常的情况下输出一下信息；**

```
[OK] All nodes agree about slots configuration.

\>>> Check for open slots...

\>>> Check slots coverage...

[OK] All 16384 slots covered.


./redis-cli -c -p 7113 -a 123456  #登录本机

./redis-cli -c -p 7113 -a 123456 -h 192.168.199.12  #登录集群主机
```

创建keys值,

如：set  xiaofeige  hello,world;

-> Redirected to slot [7551] located at 192.168.199.11:7112  #表示这个key值写到了192.168.199.11主机的slot [7551]这个槽中





**/usr/local/redis5/bin/redis-cli -c -p 7111 -a 123456 cluster nodes  #查看集群情况**