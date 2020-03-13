

# 								日志数据引入Redis

![1583139151567](C:\Users\MAIBENBEN\AppData\Roaming\Typora\typora-user-images\1583139151567.png)

logstash把程序日志打到redis，logstash从redis中读取日志进行过滤然后在传送到ES集群中，kibana从ES集群中读取日志进行展示；

##### 优势：

1、相比上图，在多台服务器，大量日志情况下可减少对ES压力，队列起到缓冲作用，也可以一定程度保护数据不丢失。（当Logstash接收数据能力超过ES处理能力时，可增加队列均衡网络传输）

2、将收集的日志统一在Indexer中处理。

如果日志量大可采用Kafka做缓冲队列，相比Redis更适合大吞吐量。

----------------

##### 安装redis，IP地址：192.168.83.128

yum install epel-release -y

yum install redis -y

##### 配置redis：

```
vim /etc/redis/redis.conf
bind 0.0.0.0
requirepass foobared  改为：123456  #123456是访问密码；
```

##### 启动redis：

systemctl  restart redis

----------------------------

### 使用logstash将日志引入redis

在192.168.83.128中部署logstash然后将日志打入redis：

部署logstash前需要配好jdk环境：

```
下载logstash软件包：logstash-6.2.4.tar.gz

tar -xf logstash-6.2.4.tar.gz

mv logstash-6.2.4 /usr/local/
#创建配置目录：
mkdir -p /usr/local/logstash-6.2.4/conf.d
```

##### 创建配置文件：

```
vim logstash_to_redis.conf
input {
    file {
        path => ["/var/log/messages"]
        type => "system"
        tags => ["syslog","test"]
        start_position => "beginning"
    }
    file {
        path => ["/var/log/audit/audit.log"]
        type => "system"
        tags => ["auth","test"]
        start_position => "beginning"
    }
}

filter {

}

#日志输出到redis
output {
    redis {
        host => ["192.168.83.128:6379"]		#日志输出到redis
        password => "123456"				#redis密码
        db => "0"							#指定数据库
        data_type => "list"					#指定数据类型，list表示为列表类型
        key => "logstash"	#key可以自定义，会在redis中创建这个key然后把日志存到这个key中；
    }
}
```

##### 启动logstash：

/usr/local/logstash-6.2.4/bin/logstash -f /usr/local/logstash-6.2.4/conf.d/logstash-to-redis.conf 

查看redis中是否有我们的数据：

```
登录redis：redis-cli  -a 123456

keys *   可以看到我们的logstash库；
查看数据库：
127.0.0.1:6379> keys *
1) "logstash"
127.0.0.1:6379> llen logstash
(integer) 7757
#上面可以看到logstash中有7757条记录，说明成功了；
```

好了，我们已将/var/log/messages和/var/log/audit/audit.log日志写到redis中了，接来来我们要去192.168.83.131中使用logstash读取redis中的日志进行过滤在存入ES集群中

-------------------------------------------------

#### 创建配置文件：

cd /usr/local/logstash-6.2.4/conf.d/

vim logstash_from_redis.conf   #写入如下配置；

```
#日志从redis读入
input {
    redis {
        host => "192.168.83.128"		#redis主机IP
        port => 6379					#redis端口
        password => "123456"			#redis密码
        db => "0"						#指定数据库，要和logstash引入redis的一样
        data_type => "list"				#指定类型，需要和logstash引入redis的一样
        key => "logstash"				#指定key，要和logstash引入redis的一样
    }
}

#过滤
filter {

}

#将日志写入ES集群中
output {
    if [type] == "system" {
        if [tags][0] == "syslog" {
            elasticsearch {
                hosts  => ["http://192.168.83.129:9200","http://192.168.83.130:9200"]
                index  => "logstash-system-syslog-%{+YYYY.MM.dd}"
            }
            stdout { codec=> rubydebug }
        }
        else if [tags][0] == "auth" {
            elasticsearch {
                hosts  => ["http://192.168.83.129:9200","http://192.168.83.130:9200"]
                index  => "logstash-system-auth-%{+YYYY.MM.dd}"
            }
            stdout { codec=> rubydebug }
        }
    }
}
```

启动logstash：

```
/usr/local/logstash-6.2.4/bin/logstash -f /usr/local/logstash-6.2.4/conf.d/logstash_from_redis.conf
```

启动logstash后logstash会自动去消费redis的数据并且将数据写入ES集群；

----------------------------

### 使用filebeat将日志引入redis

如果只采集日志，Filebeat比Logstash更适合，filebeat占用资源少，配置简单。

filebeat把程序日志打到redis，logstash从redis中读取日志进行过滤然后在传送到ES集群中，kibana从ES集群中读取日志进行展示；

#### filebeat有两种采集模式

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

#### 配置文件字段详解：

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

#### 启动filebeat：

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

