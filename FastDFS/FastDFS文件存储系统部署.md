# FastDFS文件存储系统部署

#### 1、fastDFS介绍：

fastDFS 是以C语言开发的一项开源轻量级分布式文件系统，他对文件进行管理，主要功能有：文件存储，文件同步，文件访问（文件上传/下载）,特别适合以文件为载体的在线服务，如图片网站，视频网站等

```
分布式文件系统：
基于客户端/服务器的文件存储系统
对等特性允许一些系统扮演客户端和服务器的双重角色，可供多个用户访问的服务器，比如，用户可以“发表”一个允许其他客户机访问的目录，一旦被访问，这个目录对客户机来说就像使用本地驱动器一样
```

#### FastDFS由跟踪服务器(Tracker Server)、存储服务器(Storage Server)和客户端(Client)构成。

```
Tracker server 追踪服务器
追踪服务器负责接收客户端的请求，选择合适的组合storage server ，tracker server 与 storage server之间也会用心跳机制来检测对方是否活着。
Tracker需要管理的信息也都放在内存中，并且里面所有的Tracker都是对等的（每个节点地位相等），很容易扩展
客户端访问集群的时候会随机分配一个Tracker来和客户端交互。

Storage server 储存服务器
实际存储数据，分成若干个组（group），实际traker就是管理的storage中的组，而组内机器中则存储数据，group可以隔离不同应用的数据，不同的应用的数据放在不同group里面，

优点：
海量的存储：主从型分布式存储，存储空间方便拓展,
fastDFS对文件内容做hash处理，避免出现重复文件
然后fastDFS结合Nginx集成, 提供网站效率
```

![image-20200519193348663](https://note.youdao.com/yws/api/personal/file/F740421056AD485CB96E37EE0E0DB3BF?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)



#### 2、读写操作：

##### 1) 写入数据

```
写操作的时候，storage会将他所挂载的所有数据存储目录的底下都创建2级子目录，每一级256个总共65536个，新写的文件会以hash的方式被路由到其中某个子目录下，然后将文件数据作为本地文件存储到该目录中。
```

![image-20200519193538564](https://note.youdao.com/yws/api/personal/file/C26CFFE7EC83415CA5F8F8F1DF96DFAA?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)



##### 2) 下载文件：

```
当客户端向Tracker发起下载请求时，并不会直接下载，而是先查询storage server（检测同步状态），返回storage server的ip和端口，
然后客户端会带着文件信息（组名，路径，文件名），去访问相关的storage，然后下载文件。
```

![image-20200519193559278](https://note.youdao.com/yws/api/personal/file/FD3EB4B2B4BE4FF689B96F9663F64CBD?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

--------------

### 部署规划：

主机IP：192.168.83.132

软件包我已打包上传到百度网盘：

```
链接：https://pan.baidu.com/s/1tica0VWowow-RbceSGcXSg 提取码：t5fs 
```

也可以到下面的地址获取

github地址：https://github.com/happyfish100

源码下载地址：https://sourceforge.net/projects/fastdfs/files/

论坛地址：http://bbs.chinaunix.net/forum-240-1.html

-----------

##### 下载软件包：

```
fastdfs-6.04.zip

fastdfs-nginx-module-1.22.zip

libfastcommon-1.0.43.zip

nginx-1.15.2.tar.gz
```

上传安装包到两台服务器的/usr/local/src/目录下

##### 安装相关依赖插件：

```
yum install make cmake gcc gcc-c++ -y
```

### 安装libfastcommon

```
unzip libfastcommon-1.0.43.zip
cd  libfastcommon-1.0.43
./make.sh
./make.sh install
-------------------------------------------
libfastcommon默认安装到了：
/usr/lib64/libfastcommon.so
/usr/lib/libfastcommon.so
其实是同一个文件，安装的时候会自动创建软连接：
ln -s /usr/lib64/libfastcommon.so /usr/lib/libfastcommon.so
```

------------

### 安装fastdfs:

##### 安装相关依赖库：

```
yum install perl pcre pcre-devel zlib zlib-devel openssl openssl-devel -y
```

##### 安装fastdfs:

```
unzip fastdfs-6.04.zip 
cd fastdfs-6.04
./make.sh
./make.sh install
```

##### 查看一下fdfs_trackerd，fdfs_storaged这两个文件是否存在

```
ll /etc/init.d/{fdfs_trackerd,fdfs_storaged}
```

##### 创建数据目录：

```
mkdir -p /home/yunwei/fastdfs/{tracker,storage}
```

##### 配置和启动tracker

cd  /etc/fdfs

```
cp client.conf.sample client.conf
cp storage.conf.sample storage.conf
cp tracker.conf.sample tracker.conf
```

vim  tracker.conf

```
base_path=/home/yunwei/fastdfs/tracker
#把这个base_path改为我们刚刚创建的目录即可
```

##### 启动tracker

```
service fdfs_trackerd start
```

启动之后会在/home/yunwei/fastdfs/tracker目录下生成两个目录：data和logs两个目录

tracker默认的端口是：22122

```
[root@localhost tracker]# netstat -tnlp|grep -w 22122
tcp        0      0 0.0.0.0:22122           0.0.0.0:*               LISTEN      21483/fdfs_trackerd 
```

##### 修改storage配置文件

vim  /etc/fdfs/storage.conf

```
base_path=/home/yunwei/fastdfs/storage
	#设置storage的基础路径，这里将tracker和storage放在同一个目录中
store_path0=/home/yunwei/fastdfs/storage
	#设置存放文件的路径
tracker_server=192.168.83.132:22122
	#设置tracker服务器的IP和端口，这里的tracker和storage是同一台主机
storage的默认端口是：23000
```

#####  启动storage：

```
service fdfs_storaged start
```

##### 查看一下端口：

```
[root@localhost data]# netstat -tnlp|grep -w 23000
tcp        0      0 0.0.0.0:23000           0.0.0.0:*               LISTEN      22107/fdfs_storaged 
```

启动后会在data目录中生成很多目录，以后的文件就是存储在这里

![image-20200519165714291](https://note.youdao.com/yws/api/personal/file/803A0617C4094064A6673DE93C4B0584?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

### 使用FastDFS自带的工具测试

修改client.conf 配置文件：

vim /etc/fdfs/client.conf

```
base_path=/home/yunwei/fastdfs/storage
tracker_server=192.168.83.132:22122
```

上传一张图片测试一下：

先找一张图片传到服务器：

```
/usr/bin/fdfs_upload_file /etc/fdfs/client.conf /root/5.jpg
#上传文件命令：/usr/bin/fdfs_upload_file
#指定client.conf 配置文件：/etc/fdfs/client.conf
#指定要上传的文件：/root/5.jpg
```

上传成功会返回一个路径：

```
[root@localhost ~]# /usr/bin/fdfs_upload_file /etc/fdfs/client.conf /root/5.jpg 
group1/M00/00/00/wKhThV7DoXiAUtNTAArmLvwOrG8389.jpg
返回的地址路径是：group1/M00/00/00/wKhThF7DtUuACe2rAArmLvlJbbU238.jpg
#前面的group1/M00/可以在配置文件中修改
在服务器上查看文件的位置如下：
/home/yunwei/fastdfs/storage/data/00/00/wKhThF7DtUuACe2rAArmLvlJbbU238.jpg
```

------------------

### FastDFS整合Nginx

##### 1、在tracker上安装Nginx

在每个tracker上安装Nginx的主要目的是做负载均衡及高可用，如果只有一台tracker可以不配置Nginx，一个tracker可以对应多个storage，通过Nginx对storage负载均衡

解压：fastdfs-nginx-module-master.zip 

```
unzip fastdfs-nginx-module-1.22.zip
```

##### 修改配置文件：

cd fastdfs-nginx-module-1.22/src

vim config

```
ngx_module_incs="/usr/include/fastdfs /usr/include/fastcommon/"
CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/include/fastcommon/"
修改以上两处即可
```

![image-20200519172914679](https://note.youdao.com/yws/api/personal/file/561E6DB17CDF47CE9C367AB6C1C76749?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

将fastdfs-nginx-module-master/src下的mod_fastdfs.conf配置文件拷贝至/etc/fdfs/目录下

```
cp -pa mod_fastdfs.conf /etc/fdfs/
```

##### 修改 mod_fastdfs.conf配置文件：

vim /etc/fdfs/mod_fastdfs.conf

```
tracker_server=192.168.83.132:22122
url_have_group_name = true
store_path0=/home/yunwei/fastdfs/storage
```

#####  进入之前解压的fastdfs目录下，把http.conf、mime.conf两个文件移动至/etc/fdfs

```
cd  /usr/local/src/fastdfs-6.04/conf
cp -pa http.conf mime.types /etc/fdfs/
```

##### 安装Nginx

```
 tar -xf nginx-1.15.2.tar.gz 
./configure --prefix=/usr/local/nginx --sbin-path=/usr/bin/nginx --add-module=/usr/local/src/fastdfs-nginx-module-1.22/src
make && make install
```

##### 配置Nginx：

```
 server {
        listen       80;
        server_name  localhost;

        location ~/group([0-9]) {
            ngx_fastdfs_module;
        }
```

##### 启动Nginx：

```
/usr/bin/nginx
```

##### 浏览器访问：

```
http://192.168.83.132/group1/M00/00/00/wKhThF7DtUuACe2rAArmLvlJbbU238.jpg
```

![image-20200519185203463](https://note.youdao.com/yws/api/personal/file/685BF902FE91407488ED27A22AEE199F?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

到此FastDFS就部署完成了！