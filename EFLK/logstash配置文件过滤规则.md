

#                   logstash配置文件过滤规则：

在企业中常常会使用logstash来匹配各种复杂的日志字段，如下是各个常用的插件和匹配规则：

#### 条件判断：

```
使用条件来决定filter和output处理特定的事件

比较操作：
	相等: ==, !=, <, >, <=, >=
	正则: =~(匹配正则), !~(不匹配正则)
	包含: in(包含), not in(不包含)
布尔操作：
	and(与), or(或), nand(非与), xor(非或)
一元运算符：
	!(取反)
	()(复合表达式), !()(对复合表达式结果取反)

可以像其他编程语言那样，条件if判断、多分支，嵌套。
```

配置文件常用字段：（公共选项）			

| 字段名称  | 类型   | 注解                                                         |
| --------- | ------ | ------------------------------------------------------------ |
| add_field | hash   | 添加字段到事件中，logstash读取的每一个记录都是一个事件；     |
| codec     | codec  | 解编码                                                       |
| tags      | array  | 做标志使用，例如项目的特征，为了后面好区分是什么日志，以数组的方式，可以添加做个标记 |
| type      | string | type与tags相似，以字符串的形式添加标记，type只能添加一个标记； |

### Logstash –输入（Input）插件

所有插件可以到官网去查看示例：

https://www.elastic.co/guide/en/logstash/6.2/index.html

##### Stdin示例

```
input {
  stdin {

  }
}

filter {

}

output {
  stdout{
    codec => rubydebug }
}
```

##### File示例：

```
input {
  file {
     path =>"/var/log/messages"		#支持通配符，例如：*.log
     tags =>"nginx"					#标签
     tags =>"access"
     type =>"syslog"				#类型，可以通过标签或类型来判断，将数据放到索引上；
  }
}
filter {

}
output {
  stdout{codec => rubydebug }
}
```

| file插件字段名称                                      | **I****nput type**                             | **R****equired** | **Default** | 注解                                                         |
| ----------------------------------------------------- | ---------------------------------------------- | ---------------- | ----------- | ------------------------------------------------------------ |
| close_older                                           | number                                         | No               | 3600        | 单位秒，打开文件多长时间关闭                                 |
| delimiter                                             | string                                         | No               | \n          | 每行分隔符                                                   |
| discover_interval                                     | number                                         | No               | 15          | 单位秒，多长时间检查一次path选项是否有新文件                 |
| exclude                                               | array                                          | No               |             | 排除监听的文件，跟path一样，支持通配符                       |
| max_open_files                                        | number                                         | No               |             | 打开文件最大数量                                             |
| path                                                  | array                                          | YES              |             | 输入文件的路径，可以使用通配符例如/var/log/**/*.log，则会递归搜索 |
| sincedb_path                                          | string                                         | No               |             | sincedb数据库文件的路径，用于记录被监控的日志文件当前位置    |
| sincedb_write_interval                                | number                                         | No               | 15          | 单位秒，被监控日志文件当前位置写入数据库的频率               |
| [start_position](#plugins-inputs-file-start_position) | [string](#string), one of ["beginning", "end"] | No               | end         | 指定从什么位置开始读取文件：开头或结尾。默认从结尾开始，如果要想导入旧数据，将其设置为begin。如果sincedb记录了此文件位置，那么此选项不起作用 |
| [stat_interval](#plugins-inputs-file-stat_interval)   | number                                         | No               | 1           | 单位秒，统计文件的频率，判断是否被修改。增加此值会减少系统调用次数。 |

---------------

##### TCP示例：

通过TCP套接字读取事件。与标准输入和文件输入一样，每个事件都被定位一行文本

主要的字段是host和port；

```
input {
  tcp {
     port =>12345
     type =>"nc"
  }
}
filter {

}
output {
  stdout{codec => rubydebug }
}
# nc 192.168.83.131 12345
```

-----------------------

##### Beats示例：

从Elastic Beats框架接收事件。

```
input {
  beats {
    port => 5044
  }
}
 
filter {
 
}

output {
  stdout { codec => rubydebug }
}
```

------

#### 编码插件（Codec）

Logstash处理流程：input->decode->filter->encode->output

json分为两种，json和json_lines

该解码器可用于解码（Input）和编码（Output）JSON消息。如果发送的数据是JSON数组，则会创建多个事件（每个元素一个）

如果传输JSON消息以\n分割，就需要使用json_lines。

```
input {
  stdin {
     codec =>json {					#json格式
        charset => ["UTF-8"]		#默认字符编码也是utf-8
     }
  }
}
filter {

}
output {
  stdout{codec => rubydebug }
}
```

------------------------------------

#### Multline示例：

匹配多行，可以将多行按照一定的特征进行聚合到一个事件中。（例如java的堆栈日志就会分为多行）

| **S**etting                                                  | **I**nput type                                 | Required | **Default** | **Description**                                              |
| ------------------------------------------------------------ | ---------------------------------------------- | -------- | ----------- | ------------------------------------------------------------ |
| [auto_flush_interval](#plugins-codecs-multiline-auto_flush_interval) | number                                         | No       |             |                                                              |
| [charset](#plugins-codecs-multiline-charset)                 | string                                         | No       | UTF-8       | 输入使用的字符编码                                           |
| [max_bytes](#plugins-codecs-multiline-max_bytes)             | bytes                                          | No       | 10M         | 如果事件边界未明确定义，则事件的的积累可能会导致logstash退出，并出现内存不足。与max_lines组合使用 |
| [max_lines](#plugins-codecs-multiline-max_lines)             | number                                         | No       | 500         | 如果事件边界未明确定义，则事件的的积累可能会导致logstash退出，并出现内存不足。与max_bytes组合使用 |
| [multiline_tag](#plugins-codecs-multiline-multiline_tag)     | string                                         | No       | multiline   | 给定标签标记多行事件                                         |
| [negate](#plugins-codecs-multiline-negate)                   | boolean                                        | No       | false       | 正则表达式模式，设置正向匹配还是反向匹配。默认正向           |
| [pattern](#plugins-codecs-multiline-pattern)                 | string                                         | Yes      |             | 正则表达式匹配                                               |
| [patterns_dir](#plugins-codecs-multiline-patterns_dir)       | array                                          | No       | []          | 默认带的一堆模式                                             |
| [what](#plugins-codecs-multiline-what)                       | [string](#string), one of ["previous", "next"] | Yes      | 无          | 设置未匹配的内容是向前合并还是向后合并。                     |

```
#Multline示例
input {
  stdin {
    codec => multiline {			#使用multiline解码插件
      pattern => "^\s"		#正则匹配，（重要的字段），以什么字符串开头的，这里是以任何字符开头的，如果不是以字符开头的则执行下面what的动作；
        what => "previous"	#如果不是以字上面符串开头的就合并到上一行，（what => "previous" or "next"） previous表示合并到上一行，next表示合并到下一行
    }
  }
}

#输出示例：
Expressdhskjdhasjkd xxxx xxxx
   aaaaaaaaaaa
   bbbbbbbbbbbbb^H^H
   ccccccccccc
dddddddddd^H

{
    "@timestamp" => 2020-03-01T08:14:56.917Z,
          "tags" => [
        [0] "multiline"
    ],
          "host" => "localhost.localdomain",
       "message" => "Expressdhskjdhasjkd xxxx xxxx\n   aaaaaaaaaaa\n   bbbbbbbbbbbbb\b\b\n   ccccccccccc",  #将Exp开头的和下面空开头的合并到一行了；
      "@version" => "1"
}

------------------------------------------------------------------------------------
#Multline示例2
input {
  stdin {
    codec => multiline {
      pattern => "pattern, a regexp"
      negate => "true" or "false"
      what => "previous" or "next"
    }
  }
}

#Multline示例3
input {
  stdin {
    codec => multiline {
      pattern => "^\["
      negate => true
      what => "previous"
    }
  }
}

#Multline示例4
input {
  stdin {
    codec => multiline {
      # Grok pattern names are valid! :)
      pattern => "^%{TIMESTAMP_ISO8601} "
      negate => true
      what => "previous"
    }
  }
}
```

------

### Logstash –过滤器（Filter）插件

Filter：过滤，将日志格式化。有丰富的过滤插件：Grok正则捕获、date时间处理、JSON编解码、数据修改Mutate等。

所有的过滤器插件都支持以下配置选项：

| Setting               | Input type | Required | **Default** | **Description**                                              |
| --------------------- | ---------- | -------- | ----------- | ------------------------------------------------------------ |
| add_field（常用）     | hash       | No       | {}          | 如果过滤成功，添加任何field到这个事件。例如：add_field => [ "foo_%{somefield}", "Hello world, from %{host}" ]，如果这个事件有一个字段somefiled，它的值是hello，那么我们会增加一个字段foo_hello，字段值则用%{host}代替。 |
| add_tag（常用）       | array      | No       | []          | 过滤成功会增加一个任意的标签到事件例如：add_tag => [ "foo_%{somefield}" ] |
| enable_metric         | boolean    | No       | true        |                                                              |
| id                    | string     | No       |             |                                                              |
| periodic_flush        | boolean    | No       | false       | 定期调用过滤器刷新方法                                       |
| remove_field （常用） | array      | No       | []          | 过滤成功从该事件中移除任意filed。例：remove_field => [ "foo_%{somefield}" ] |
| remove_tag            | array      | No       | []          | 过滤成功从该事件中移除任意标签，例如：remove_tag => [ "foo_%{somefield}" ] |

------------------------------

#### json过滤：

JSON解析过滤器，接收一个JSON的字段，将其展开为Logstash事件中的实际数据结构。

当事件解析失败时，这个插件有一个后备方案，那么事件将不会触发，而是标记为_jsonparsefailure，可以使用条件来清楚数据。也可以使用[tag_on_failure](#plugins-filters-json-tag_on_failure)

Json示例

```
input {
  stdin {
  }
}

filter {
  json {
    source => "message"		#源数据字段过滤，一般是message，必须要配置的字段；
    target => "content"		#将解析数据放到一个字段中；content内容的意思
  }
}
output {
  stdout{codec => rubydebug }
}

#过滤效果如下：
{"@timestamp":"2020-02-22T19:26:42+08:00","@version":"1","server_addr":"172.18.182.222","remote_addr":"101.133.153.99","host":"localhost","uri":"","body_bytes_sent":148,"bytes_sent":148,"upstream_response_time":0,"request":"NXSH-5.6.7","request_length":0,"request_time":0.032,"status":"400","http_referer":"","http_x_forwarded_for":"","http_user_agent":""}
{
       "content" => {
                  "http_referer" => "",
               "http_user_agent" => "",
                      "@version" => "1",
                          "host" => "localhost",
                           "uri" => "",
                   "remote_addr" => "101.133.153.99",
                    "bytes_sent" => 148,
          "http_x_forwarded_for" => "",
                  "request_time" => 0.032,
                       "request" => "NXSH-5.6.7",
                   "server_addr" => "172.18.182.222",
                        "status" => "400",
                    "@timestamp" => "2020-02-22T19:26:42+08:00",
        "upstream_response_time" => 0,
                "request_length" => 0,
               "body_bytes_sent" => 148
    },
```

------------------------------------------------------

#### kv过滤：

自动解析key=value。也可以任意字符串分割数据，主要用于字符串拆分；

field_split  一串字符，指定分隔符分析键值对

例如URL查询字符串拆分参数：

```
filter {
  kv {
     field_split => "&?"		#filed_split是常用的字段，用于拆分字符串指定的割符；
  }
}
#根据&和?分隔。
拆分的结果：
www.baidu.com?pin=12345~0&d=123&e=foo@bar.com&oq=bobo&ss=12345
{
             "d" => "123",			#以&为分割符
            "ss" => "12345",
            "oq" => "bobo",
      "@version" => "1",
             "e" => "foo@bar.com",
       "message" => "www.baidu.com?pin=12345~0&d=123&e=foo@bar.com&oq=bobo&ss=12345",
          "host" => "localhost.localdomain",
    "@timestamp" => 2020-03-01T11:13:49.186Z,
           "pin" => "12345~0"	#以？分割符拆分出来的
}
```

-----------------------------

#### geoip

开源IP地址库：

geoip获取IP地理位置的一个插件，通过geoip可以获取到IP的地理位置，需要用到一个地理IP的地理库来解析出地理位置，地理库需要手动下载。下载地址：https://www.maxmind.com/en/accounts/228521/geoip/downloads，需要先注册才可以下载，由于国外下载地址太慢了，所以我已将地理位置数据库上传至百度云：https://pan.baidu.com/s/1no-49vNICDnLVN4S4Rxytg 地理位置数据库最新更新时间是2020-02-25；

IP地址库使用示例：

```
filter {
  grok {
    match => {
      "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}"
    }
  }
  geoip {
      source => "client"    #source，根据你使用哪个字段去解析
      database => "/opt/GeoLite2-City.mmdb"	#指定IP的地理位置数据库
  }
}

#我们来查询一下123.58.180.8这个IP地址的所在位置，在logstash的控制台输入如下地址：
123.58.180.8 GET /index.html 123 0.047
{
      "@version" => "1",
    "@timestamp" => 2020-03-01T13:20:36.181Z,
        "method" => "GET",
         "geoip" => {
              "latitude" => 30.294,
             "longitude" => 120.1619,
        "continent_code" => "AS",
          "country_name" => "China",		
             "city_name" => "Hangzhou",		#所在城市	
         "country_code2" => "CN",			#国家代码 CN 中国
           "region_code" => "ZJ",
           "region_name" => "Zhejiang",		#地区：zhejiang
              "location" => {
            "lat" => 30.294,		#经纬度
            "lon" => 120.1619		#坐标
        },
                    "ip" => "123.58.180.8",
              "timezone" => "Asia/Shanghai",
         "country_code3" => "CN"
    },
       "message" => "123.58.180.8 GET /index.html 123 0.047",
        "client" => "123.58.180.8",
          "host" => "localhost.localdomain",
       "request" => "/index.html",
         "bytes" => "123",
      "duration" => "0.047"
}
```

--------------------------------------

#### date：

日志时间过滤器用于从字段中解析日期，然后使用日期或时间戳作为事件的logstash时间戳。

 如果不使用date插件，那么Logstash将处理事件作为时间戳。时间戳字段是Logstash自己添加到内置字段@timestamp，默认是UTC时间，比北京时间少8个小时。

插入到ES中保存的也是UTC时间，创建索引也是根据这个时间创建的。但Kibana是根据你当前浏览器的时区显示的（对timestamp加减）。

```
filter {
  if "nginx-access" in [tags] {
    grok {
      match => {		
        "message" => "%{IPV4:remote_addr} - (%{USERNAME:remote_user}|-) \[%{HTTPDATE:time_local}\] \"%{WORD:request_method} %{URIPATHPARAM:request_uri} HTTP/%{NUMBER:http_protocol}\" %{NUMBER:http_status} %{NUMBER:body_bytes_sent} \"%{GREEDYDATA:http_referer}\" \"%{GREEDYDATA:http_user_agent}\""
      }
    }
    date {
        locale => "en"
        match => ["time_local", "dd/MMM/yyyy:HH:mm:ss Z"]   # 默认target是@timestamp，所以time_local会更新@timestamp时间，@timestamp会根据匹配模式里的time_local时间进行匹配
    }
  }
}

#match：匹配的意思

```

----------------------

#### grok：

grok是将非结构化数据解析为结构化。

这个工具非常适于系统日志，mysql日志，其他Web服务器日志以及通常人类无法编写任何日志的格式。

默认情况下，Logstash附带约120个模式具体地址如下，也可以添加自己的模式（patterns_dir）

https://github.com/logstash-plugins/logstash-patterns-core/tree/master/patterns 可以参考里面的grok-patterns文件中的内容；

Grok调试网站：http://grok.ctnrs.com    

| Setting              | Input type | Required | **Default**       | **Description**                                    |
| -------------------- | ---------- | -------- | ----------------- | -------------------------------------------------- |
| break_on_match       | boolean    | No       | true              |                                                    |
| keep_empty_captures  |            | No       | false             | 如果true将空保留为事件字段                         |
| match（重要）        | hash       | No       | {}                | 一个hash匹配字段=>值                               |
| named_captures_only  | boolean    | No       | true              | 如果true，只存储                                   |
| overwrite（重要）    | array      | No       | []                | 重写覆盖已存在的字段的值                           |
| pattern_definitions  |            | No       | {}                |                                                    |
| patterns_dir（重要） | array      | No       | []                | 自定义模式                                         |
| patterns_files_glob  | string     | No       | *                 | Glob模式，用于匹配patterns_dir指定目录中的模式文件 |
| tag_on_failure       | array      | No       | _grokparsefailure | tags没有匹配成功时，将值附加到字段                 |
| tag_on_timeout       | string     | No       | _groktimeout      | 如果Grok正则表达式超时，则应用标记                 |
| timeout_millis       | number     |          | 30000             | 正则表达式超时时间                                 |

grok模式的语法是 %{SYNTAX:SEMANTIC}

SYNTAX模式名称

SEMANTIC匹配文本的标识符

例如：%{NUMBER:duration} %{IP:client}

例如：虚构http请求日志抽出有用的字段

55.3.244.1 GET /index.html 15824 0.043

```
filter {
  grok {
    match => { 
       "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" 	#使用空格隔开
    }
  }
}
%{IP:client}： 调用内置模式的语法，IP是模式的名称，模式匹配出来结果的标识；

#详解：
55.3.244.1 GET /index.html 15824 0.043
55.3.244.1 	#服务器IP地址，通过%{IP:client}，IP=(?:%{IPV6}|%{IPV4})来匹配，可以匹配IPV4和IPV6

GET				#请求方式，通过%{WORD:method}，WORD=\b\w+\b来匹配

/index.html		#请求的URI,通过%{URIPATHPARAM:request}，URIPATHPARAM %{URIPATH}(?:%{URIPARAM})?来匹配请求的资源名，request请求的意思

15824			#请求大小，通过%{NUMBER:bytes}，NUMBER (?:%{BASE10NUM})来匹配；

0.043			#请求时间，通过%{NUMBER:duration}，NUMBER (?:%{BASE10NUM})来匹配；

#示例详细信息如下：
55.3.244.1 GET /index.html 15824 0.043
{
         "bytes" => "15824",
        "method" => "GET",
        "client" => "55.3.244.1",
          "host" => "localhost.localdomain",
      "@version" => "1",
    "@timestamp" => 2020-03-01T14:12:29.088Z,
      "duration" => "0.043",
       "message" => "55.3.244.1 GET /index.html 15824 0.043",
       "request" => "/index.html"
}
```

自定义模式：

如果默认模式中没有匹配的，可以自己写正则表达式。

```
#模拟创建一个有ID的日志文件：
vim /opt/patterns
ID [0-9A-Z]{10,11}		#表示匹配数字或大写字母的10到11位；ID是模式名，正则[0-9A-Z]{10,11}范围
-------------------------
匹配如下：
filter {
  grok {
    patterns_dir =>"/opt/patterns"
    match => {
      "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration} %{ID:id}"              
    }
  }
}
可以看到新增了一个：%{ID:id}
------------------------------------
#具体示例如下：
55.3.244.1 GET /index.html 15824 0.043 123456789AB
{
       "message" => "55.3.244.1 GET /index.html 15824 0.043 123456789AB",
    "@timestamp" => 2020-03-01T14:26:35.843Z,
         "bytes" => "15824",
        "client" => "55.3.244.1",
          "host" => "localhost.localdomain",
        "method" => "GET",
       "request" => "/index.html",
            "id" => "123456789AB",		#这里就是我们新增的匹配字段
      "@version" => "1",
      "duration" => "0.043"
}
```

多模式匹配

一个日志可能有多种格式，一个匹配可以有多条规则匹配多种格式。

一条匹配模式，如果匹配不到，只会到message字段。

例如：新版本项目日志需要添加日志字段，需要兼容旧日志匹配

```
input {
  stdin {
    }
}

filter {
  grok {
    patterns_dir =>"/opt/patterns"
    match => [
      "message", "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration} %{ID:id}",
      "message", "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration} %{TAG:tag}"
    ]
  }
}
output {
  stdout{codec => rubydebug }
}
#使用[]，=>换成逗号
测试多模式匹配：
vim /opt/patterns #新增TAG匹配：
TAG SYSLOG1
------------------------
匹配结果：
55.3.244.1 GET /index.html 15824 0.043 SYSLOG1
{
        "method" => "GET",
      "@version" => "1",
        "client" => "55.3.244.1",
      "duration" => "0.043",
    "@timestamp" => 2020-03-01T14:47:01.742Z,
         "bytes" => "15824",
       "message" => "55.3.244.1 GET /index.html 15824 0.043 SYSLOG1",
           "tag" => "SYSLOG1",			#匹配TAG成功
       "request" => "/index.html",
          "host" => "localhost.localdomain"
}
55.3.244.1 GET /index.html 15824 0.043 123456789AB
{
        "method" => "GET",
      "@version" => "1",
        "client" => "55.3.244.1",
      "duration" => "0.043",
    "@timestamp" => 2020-03-01T14:47:16.452Z,
         "bytes" => "15824",
       "message" => "55.3.244.1 GET /index.html 15824 0.043 123456789AB",
            "id" => "123456789AB",		#匹配ID成功
       "request" => "/index.html",
          "host" => "localhost.localdomain"
}

```

### output输出插件：

以message和audit日志为例：

```，可以
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
output {
    if [type] == "system" {
        if [tags][0] == "syslog" {
            elasticsearch {
                hosts  => ["http://192.168.0.211:9200","http://192.168.0.212:9200","http://192.168.0.213:9200"]
                index  => "logstash-system-syslog-%{+YYYY.MM.dd}"	
            }
            stdout { codec=> rubydebug }   #输出到控制台
        }
        else if [tags][0] == "auth" {
            elasticsearch {
                hosts  => ["http://192.168.0.211:9200","http://192.168.0.212:9200","http://192.168.0.213:9200"]
                index  => "logstash-system-auth-%{+YYYY.MM.dd}"
            }
            stdout { codec=> rubydebug }  #输出到控制台
        }
    }
}

#elasticsearch插件有两个常用的参数：
1、hosts： ES集群主机+端口；
2、index： 索引，可以根据日志来区分存储位置的索引；
```

