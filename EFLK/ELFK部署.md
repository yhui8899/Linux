# 																		ELFK部署

#### ELK由Elasticsearch+Logstash+ Kibana三款软件的组合：

Elasticsearch：是个开源分布式搜索引擎，它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等，ELK官网：https://www.elastic.co/



Logstash：是一个完全开源的工具，他可以对你的日志进行收集、过滤，并将其存储供以后使用（如，搜索）。



 Kibana：也是一个开源和免费的工具，它Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，数据可视化，可以帮助您汇总、分析和搜索重要数据日志。



Beats ：轻量型采集器的平台，从边缘机器向Logstash 和Elasticsearch 发送数据。
Filebeat：轻量型日志采集器。

------------------------------

### Elasticsearch基本概念：

Node：运行单个ES实例的服务器

Cluster：一个或多个节点构成集群

Index：索引是多个文档的集合

Document：Index里每条记录称为Document，若干文档构建一个Index

Type：一个Index可以定义一种或多种类型，将Document逻辑分组

Field：ES存储的最小单元

Shards：ES将Index分为若干份，每一份就是一个分片

Replicas：Index的一份或多份副本

| Elasticsearch | 关系型数据库（比如Mysql） |
| ------------- | ------------------------- |
| Index         | Database  （数据库）      |
| Type          | Table           （表）    |
| Document      | Row             （行）    |
| Field         | Column      （字段）      |

------------------------

### 一、Elasticsearch集群部署：

ES-1_IP：192.168.83.129

ES-2_IP：192.168.83.130

##### 建议内存2G以上

#### 1、部署jdk环境：

```
下载jdk：jdk-8u181-linux-x64.tar.gz

tar -xf jdk-8u181-linux-x64.tar.gz -C /usr/local/

配置jdk环境变量，将下面配置文件追加到/etc/profile文件中；
export JAVA_HOME=/usr/local/jdk1.8.0_181
export CLASSPATH=$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH:$HOME/bin
然后执行：source /etc/profile

测试jdk:
[root@localhost ~]# java -version
java version "1.8.0_181"
Java(TM) SE Runtime Environment (build 1.8.0_181-b13)
Java HotSpot(TM) 64-Bit Server VM (build 25.181-b13, mixed mode)
看到如上信息表示jdk配置成功
```

#### 2、部署elasticsearch：

```
下载：elasticsearch-6.2.4.tar.gz  可到官网下载；

tar -xf  elasticsearch-6.2.4.tar.gz -C /usr/local/
```



#### 2.1 创建Elasticsearch 启动用户并授权：

```
useradd elk

chown -R elk.elk /usr/local/elasticsearch-6.2.4
```

##### 2.2  修改系统参数配置：

```
1、
vim  /etc/security/limits.conf		#加入如下代码

* soft nofile 65536			#设置文件打开数（软限制）
	
* hard nofile 65536			#设置文件打开数（硬限制）
-------------------------------------------------------
2、
vim  /etc/security/limits.d/20-nproc.conf  #加入如下代码：

soft  nproc  2048		#设置最大进程数

-------------------------------------------------------
3、
vim /etc/sysctl.conf	#在末尾端加入如下代码：

vm.max_map_count=655360		#设置最大虚拟内存

#设置后需要执行 sysctl -p  	使配置文件生效

```

##### 2.3修改配置文件：

```
vim /usr/local/elasticsearch-6.2.4/config/elasticsearch.yml
node.name: node-1			#要修改集群的名字，我这里两台所以是：node-1和node-2，默认是：node-1

network.host: 192.168.83.129	#填写主机IP即可

discovery.zen.ping.unicast.hosts: ["192.168.83.129", "192.168.83.130"] 
#集群的一个重要参数，填写ES集群节点的IP或者主机名，作用是为了ES集群节点自动发现来管理集群；

discovery.zen.minimum_master_nodes: 2  #最小master节点数必须要配，我们这里有两台ES所以数量是2

```

##### 3、 启动elasticsearch

```
 su - elk -c "/usr/local/elasticsearch-6.2.4/bin/elasticsearch -d"	
 #检查端口：
 [root@localhost ~]# netstat -tnlp|grep -Ew "9200|9300"
tcp6       0      0 :::9200                 :::*                    LISTEN      9942/java           
tcp6       0      0 :::9300                 :::*                    LISTEN      9942/java 

看到9200、9300端口表示elasticsearch启动成功
ES集群通信是使用9300端口来通信的
```

##### 4、查看集群状态：

http://192.168.83.130:9200/_cluster/health?pretty

```

  "cluster_name" : "elasticsearch",
  "status" : "green",	#集群的状态红绿灯，绿：健康，黄：亚健康，红：病态，一般有三个值：green（健康）、yellow（有可能副本分片有问题所以会出现yellow即是亚健康）和red（有问题的）三个值
  "timed_out" : false,
  "number_of_nodes" : 2,			#节点数
  "number_of_data_nodes" : 2,		#数据节点数
  "active_primary_shards" : 0,		#分片数，0个Index库
  "active_shards" : 0,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,	#未指定节点，仅使用一台机器部署会出现这种情况，这里指定了节点所以是0正常
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

##### 查看集群的节点数：curl -X GET "192.168.83.129:9200/_cat/nodes?v" 

```
[root@localhost logs]# curl -X GET "192.168.83.129:9200/_cat/nodes?v"
ip             heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
192.168.83.129           14          50   0    0.00    0.01     0.05 mdi       -      node-1
192.168.83.130           14          50   0    0.02    0.02     0.05 mdi       *      node-2
```

----------------------------------------------------



### 二、安装elasticsearch-head插件

elasticsearch-head插件是一款数据可视化插件，可以在上面创建和查询索引等；

##### 安装在192.168.83.129节点上即可：

##### 下载elasticsearch-head插件：

wget https://npm.taobao.org/mirrors/node/latest-v4.x/node-v4.4.7-linux-x64.tar.gz 

```
tar -zxvf node-v4.4.7-linux-x64.tar.gz 
mv node-v4.4.7 /usr/local/node4.4
# vim /etc/profile
NODE_HOME=/usr/local/node4.4
PATH=$NODE_HOME/bin:$PATH
export NODE_HOME PATH
```

##### 安装git和npm工具：

```
yum install git npm -y
```

##### 将elasticsearch-head插件克隆到主机：

```
git clone git://github.com/mobz/elasticsearch-head.git
```

```
cd elasticsearch-head

npm install
#由于官方源太慢了，所以更换为淘宝源：npm config set registry http://registry.npm.taobao.org 然后再执行：npm install 会快很多；
```

##### 出现报错：

```
npm WARN elasticsearch-head@0.0.0 license should be a valid SPDX license expression
npm ERR! Linux 3.10.0-957.el7.x86_64
npm ERR! argv "/usr/bin/node" "/usr/bin/npm" "install"
npm ERR! node v6.17.1
npm ERR! npm  v3.10.10
npm ERR! code ELIFECYCLE

npm ERR! phantomjs-prebuilt@2.1.16 install: `node install.js`
npm ERR! Exit status 1
npm ERR! 
npm ERR! Failed at the phantomjs-prebuilt@2.1.16 install script 'node install.js'.
npm ERR! Make sure you have the latest version of node.js and npm installed.
npm ERR! If you do, this is most likely a problem with the phantomjs-prebuilt package,
npm ERR! not with npm itself.
npm ERR! Tell the author that this fails on your system:
npm ERR!     node install.js
npm ERR! You can get information on how to open an issue for this project with:
npm ERR!     npm bugs phantomjs-prebuilt
npm ERR! Or if that isn't available, you can get their info via:
npm ERR!     npm owner ls phantomjs-prebuilt
npm ERR! There is likely additional logging output above.

npm ERR! Please include the following file with any support request:
npm ERR!     /root/elasticsearch-head/npm-debug.log

#解决方法：
执行：npm install phantomjs-prebuilt@2.1.14 --ignore-scripts
然后再执行：npm install 
```

#### 修改elasticsearch-head监听地址：

##### 由于elasticsearch-head默认是监听本地的9100端口，所以需要修改一下：

```
进入到elasticsearch-head目录：
添加：hostname: '*'
vim vim Gruntfile.js	
options: {
                                        port: 9100,
                                        hostname: '*',		#添加此行即可；
                                        base: '.',
                                        keepalive: true    
                                }
```

##### 修改elasticsearch.yml，增加跨域的配置；

为了解决跨域限制所以需要授权才可以连接到ES，默认是不允许连接到ES的；

```
#在末尾添加如下代码；
vim /usr/local/elasticsearch-6.2.4/config/elasticsearch.yml
http.cors.enabled: true
http.cors.allow-origin: "*"

添加完之后重启elasticsearch
```

##### 修改head连接es的地址，将localhost修改为ES的IP地址。

##### 在elasticsearch-head目录下执行：vim _site/app.js

```
cd elasticsearch-head
vim _site/app.js
this.base_uri = this.config.base_uri || this.prefs.get("app-base_uri") || "http://192.168.83.129:9200";
#找到上面的代码把：http://localhost:9200改为：http://192.168.83.129:9200 即可。
```



#### 启动elasticsearch-head

```
npm run start	#前台运行
nohup npm run start &	 #后台运行

或者在后台启动：
nohup ./node_modules/grunt/bin/grunt server &   

注意：需先进入elasticsearch-head目录执行；

```

-------------------------



##  三、logstash部署：

logstash+kibana主机IP：192.168.83.131

由于logstash是使用java语言编写的，所以需要安装java环境；

#### 安装部署logstash：

​	下载logstash软件包：logstash-6.2.4.tar.gz

​     tar -xf logstash-6.2.4.tar.gz -C /usr/local/

##### logstash默认端口：9600

##### 创建配置文件目录：

mkdir  -p /usr/local/logstash-6.2.4/conf.d

#### 创建配置文件并写入配置：

```
#标准输入、输出；
vim /usr/local/logstash-6.2.4/conf.d
input {
  stdin {
  }
}

filter {
}

output {	
  stdout{		#标准输出到控制台，
  	codec => rubydebug }  #	codec解码，通过rubydebug插件来解码打印debug信息；
}
```

#### logstash启动参数：

```
logstash  -f  	#指定配置文件位置

	例如：logstash  -f  test.conf

logstash -t  	#测试配置文件语法是否正确

	例如：logstash  -t   -f  test.conf

logstash -r  #动态加载配置文件，无需重启logstash，和reload相似，适用于标准输入，不是每个插件都支持；
	例如：logstash -r -f test.conf
```

##### 启动测试文件来测试一下：

cd  /usr/local/logstash-6.2.4/bin

./logstash  -f ../conf.d/test.conf

```
{
      "@version" => "1",						#版本
    "@timestamp" => 2020-03-01T06:27:32.160Z,	#时间戳，一般是会慢8小时的
       "message" => "hello",					#输入的内容
          "host" => "localhost.localdomain"		#主机名
}
```

-------------------------



### 四、Kibana部署：

kibana是一款图像化界面的软件，可以从elasticsearch中读取日志进行展示；

下载或上传kibana软件：kibana-6.2.4-linux-x86_64.tar.gz

```
tar -xf kibana-6.2.4-linux-x86_64.tar.gz
mv kibana-6.2.4-linux-x86_64 /usr/local/kibana-6.2.4
```

##### 修改配置文件：

```
vim /usr/local/kibana-6.2.4/kibana.yml
elasticsearch.url: "http://192.168.83.129:9200" 
#把elasticsearch的URL地址改为ES主节点的IP即可；

server.host: "0.0.0.0"
#把localhost改为0.0.0.0地址即可，默认localhost是监听127.0.0.1地址
```

##### 启动kibana：

```
nohup /usr/local/kibana-6.2.4/bin/kibana &
```

##### 访问kibana：

http://192.168.83.131:5601

#### kibana图形化界面导航介绍：

```
Discover： 发现的意思，查看索引数据的；

Visualize： 可视化的意思，创建一些图表等等;

Dashboard ：仪表盘的意思，可以将创建一些主要的图表放在这里用于直观的数据展示；

Dev Tools：	开发工具;

Management ：管理的意思，索引管理、创建、和一些高级配置；       
```

#### 在kibana中创建索引步骤：

Management ---->Index Patterns（索引模式） ---->Create Index Pattern（创建索引模式）找到需要创建的索引logstash-system-auth-* ---->Next step ---->@timestamp---->（选择时间戳）----->Create Index Pattern---->创建完成，匹配完成之后在Discover中可以看到数据；



增强kibana的安全性，由于kibana自身没有提供安全认证，elastic有一款软件叫：X-Pack可以做安全认证而且功能也多但是要收费，所以这里使用nginx来给kibana做安全认证，利用nginx的反向代理来给kibana增强安全性；

#### 安装nginx：

nginx代理IP：192.168.83.128

```
安装nginx依赖包：yum install gcc gcc-c++ openssl-devel zlib-devel pcre-devel -y
下载nginx软件包：wget -c  http://nginx.org/download/nginx-1.7.7.tar.gz
tar -xf nginx-1.7.7.tar.gz
cd nginx-1.7.7
./configure --prefix=/usr/local/nginx
make && make install

```

##### nginx 配置如下：

```
worker_processes  1;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    charset utf-8;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            proxy_pass http://192.168.83.131:5601;		#设置代理地址
            auth_basic "Please input user and passowrd";	#提示用户输入账号密码
            auth_basic_user_file /usr/local/nginx/conf/passwd.db;  #指定用户密码文件
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

    }

}

#主要是如下三个配置：
proxy_pass http://192.168.83.131:5601;		#设置代理地址
auth_basic "Please input user and passowrd";	#提示用户输入账号密码
auth_basic_user_file /usr/local/nginx/conf/passwd.db;   #指定用户密码文件
-------------------------------
#创建密码文件：
密码格式：用户名:密码
#由于使用明文密码不安全所以需要用openssl工具来对密码进行加密
示例：
openssl passwd -crypt xiaofeige
[root@localhost conf]# openssl passwd -crypt xiaofeige 
Warning: truncating password to 8 characters
odZ/7Nd/3MuGg		#生成的加密密码

----------------------------------
将用户名密码写入密码文件：
vim /usr/local/nginx/conf/passwd.db
admin:odZ/7Nd/3MuGg
#最后测试一下即可；
http://192.168.83.128  提示输入用户名密码登录表示成功；
```



### 五、filebeat部署：

如果只采集日志，Filebeat比Logstash更适合，filebeat占用资源少，配置简单。

filebeat把程序日志打到redis，logstash从redis中读取日志进行过滤然后在传送到ES集群中，kibana从ES集群中读取日志进行展示；

##### filebeat有两种采集模式

1、通过模块去采集系统或应用日志

2、通过Prospectors的方式来采集系统或应用日志

这里使用Prospectors采集

filebeat官网文档：https://www.elastic.co/guide/en/beats/filebeat/current/index.html

##### 前提需要先部署jdk环境：

 下载filebeat软件：filebeat-6.2.1-linux-x86_64.tar.gz

```
tar -xf filebeat-6.2.1-linux-x86_64.tar.gz

mv filebeat-6.2.1-linux-x86_64 /usr/local/filebeat-6.2.1
```

filebeat主配置文件：filebeat.yml，直接在此文件中配置要采集的日志即可；

清空filebeat.yml文件写入如下内容：

#### 把日志写入redis：

```
vim filebeat.yml

filebeat.prospectors:
- type: log			#日志类型
  paths:
    - /var/log/messages		#指定路径
  tags: ["syslog"，“test”]		#以数组的形式写tags,可以写过个用逗号分开；
  #exclude_lines: ['^DBG']		#排除以DBG开头的文件，这里没用到
  #include_lines: ['^ERR','^WARN'] 引入以ERR和WARN开头的文件，这里没用到
  fields:				#添加字段：
    type: system		#由于type字段是在fields下面的所以需要添加fields_under_root: true
  fields_under_root: true	#添加这个之后type字段就等于和fields同级了，方便与logstash相对应；

#添加第二个日志：
- type: log				#注意，收集一个日志就写一个type即可！
  paths:
    - /var/log/audit/audit.log
  tags: ["auth","test"]
  fields:
    type: system
  fields_under_root: true			#必须要加这一行，否则无法匹配上面的type；

#输出到redis：
output.redis:
  hosts: ["192.168.83.128"]		#redis主机IP地址
  password: "123456"		#redis密码
  key: "filebeat"	#定义key，会自动在redis中创建然后将数据写入key此中
  db: 0				#数据库
  datatype: list	#数据类型：list，列表形式
```

#### 参数字段解释：

```
paths # 指定监控的文件，可通配符匹配。如果要对目录递归处理，例如/var/log/*/*.log
encoding：指定监控的文件编码类型，使用plain和utf-8都可以处理中文日志
exclude_lines: ['^DEBUG']    # 排除 DEBUG开头的行
include_lines: ['^ERR', '^WARN'] # 只读取ERR，WARN开头的行
fields_under_root #设置true，则新增字段为根目录。否则是fields.level
fields  # 新增字段，向输出的日志添加额外的信息，方面后面分组统计
processors # 定义处理器，在发送数据之前处理事件。
drop_fields # 指定删除的字段
output.console:  # 以JSON格式控制台输出
  pretty: true
```

官方文档：https://www.elastic.co/guide/en/beats/filebeat/current/redis-output.html

##### 启动filebeat：

```
nohup /usr/local/filebeat-6.2.1/filebeat & 
```

#### 查看redis数据

```
[root@localhost ~]# redis-cli -a 123456
127.0.0.1:6379> keys *
1) "filebeat"
127.0.0.1:6379> llen filebeat
(integer) 7874
127.0.0.1:6379> 
#上面可以看到filebeat已经将日志打入redis中
```

