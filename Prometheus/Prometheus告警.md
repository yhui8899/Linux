# Prometheus告警

由于Prometheus本身不支持告警功能，所以需要Alertmanager这个组件来完成告警功能，Prometheus将告警收集起来发给Alertmanager，由Alertmanager来处理或者发送通知给相关人员

![1585039519343](https://note.youdao.com/yws/api/personal/file/24BAE212607A480D81413A7626D0BF34?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

----------------------

部署Alertmanager

这里把Alertmanager和Prometheus安装在同一台主机上，也可以安装在其他主机，只要能通信即可；

```
下载Alertmanager：
wget https://github.com/prometheus/alertmanager/releases/download/v0.20.0/alertmanager-0.20.0.linux-amd64.tar.gz
---------------------------------------
tar -xf alertmanager-0.20.0.linux-amd64.tar.gz
mv alertmanager-0.20.0.linux-amd64.tar.gz /usr/local/alertmanager
```

Prometheus与Alertmanager通信

![1585039842020](https://note.youdao.com/yws/api/personal/file/9C1F0A08973949D3B922889517526B41?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

alertmanager配置文件详解：

```
vim alertmanager.yml
global:						#全局配置
  resolve_timeout: 5m		#解析超时时间
  smtp_smarthost: 'smtp.163.com:25'		#配置邮件发送服务器信息
  smtp_from: 'yhui8899@163.com'			#使用这个邮件地址发送告警
  smtp_auth_username: 'yhui8899@163.com'	#邮件发送账号
  smtp_auth_password: '123456'
  smtp_require_tls: false				#是否启用tls，这里false不启用
  
route:						#告警如何发送和分配
  group_by: ['alertname']	#这是alertmanager中的一个分组，采用标签作为分组的依据
  group_wait: 10s			#分组等待的时间为10秒，拿到告警后等待10秒再发送
  group_interval: 10s		#分组间隔10秒，就是上下两组发送告警的间隔时间；
  repeat_interval: 1h	#重复告警时间，第一次发送告警后同样的告警等待1小时再发送，可以自定义如：20m等
  receiver: 'email'		#接收者，这里是配置email邮件通知
receivers:					#定义告警接收者，
- name: 'email'			#这个name是由上面route配置好
  email_configs:
  - to: 'yhui8899@163.com'		#接收者邮箱地址
inhibit_rules:				#抑制角色，用于告警收敛的，主要是减少发送告警，只发送关键的
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
~                                           
```

配置文件检查：./amtool check-config alertmanager.yml

```
[root@localhost alertmanager]# ./amtool check-config alertmanager.yml 
Checking 'alertmanager.yml'  SUCCESS
Found:
 - global config
 - route
 - 0 inhibit rules
 - 1 receivers			#表示1个接收者
 - 0 templates

```

启动alertmanager

```
./alertmanager --config.file=./alertmanager.yml		#也可以配置为systemd启动

#监听端口：99093和9094
```

-----------

配置Prometheus与alertmanager通信

```
需要配置两部分：
配置通信
alerting:
  alertmanagers:
  - static_configs:
    - targets:
        - 127.0.0.1:9093	#填写alertmanager的服务器地址和端口
-------------------------------------------------------------------------
创建告警规则，到达一定的阀值就出发告警
rule_files:
  - "rules/*.yml"	#可以指定单个文件也可以使用正则匹配，这个位置是在当前配置文件的同级目录，写告警规则
  # - "second_rules.yml"
 #需要手动创建rules目录
mkdir rules

```

创建告警规则官方示例：https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/

告警规则如下：

```
vim test.yml
groups:
- name: general.rules
  rules:

    # 告警规则配置，服务停止5分钟以上就发送告警
  - alert: InstanceDown				
    expr: up == 0
    for: 5m
    labels:
      severity: error
    annotations:
      summary: "Instance {{ $labels.instance }} 服务已宕机"
      description: "{{ $labels.instance }} job {{ $labels.job }} 服务已停止5分钟无响应."
```

告警规则配置详解：

```
groups:			#告警组
- name: general.rules		#组名称，可以按照项目来定义这个名称
  rules:

  # 告警规则配置，服务停止5分钟以上就发送告警
  - alert: InstanceDown		#告警邮件的名字，可以自己定义
    expr: up == 0	#up等于0就触发告警，每一个示例都会有一个up状态，up是默认赋予当前被监控端的指标，可以判断被监控端job的一个状态，等于0表示服务down了，等于1表示服务正常，规则可以自己定义也可以写sql语法；
    for: 5m			#告警持续探测时间，5分钟内的状态都是0的话就触发告警，可以根据需求来定义时间
    labels:			#标签
      severity: error			#定义告警级别，
    annotations:	#注释，就是一些告警通知的信息；
      summary: "Instance {{ $labels.instance }} down已宕机"		#instance 实例的意思
      		#{{ $labels.instance }}这里调用了监控job服务的值，例如：0和1；
      description: "{{ $labels.instance }} job {{ $labels.job }} 服务已停止5分钟以上."
 --------------------------------------------------------------------------------------- 
#annotations    注解的意思
#summary 		摘要的意思
#description  描述的意思
```

注意：{{ $labels.instance }}  instance是标签名称，如下图的mountpoint也是标签名；

```
{{ $labels.instance }} 可以直接调用instance标签的值，取出来的值是主机的IP地址；
```

![1585133106723](https://note.youdao.com/yws/api/personal/file/E1844046D1E84A77BEE8EDDCB3D48E3E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)



磁盘使用率大于80%的告警示例：

```
vim test.yml
groups:
- name: node.rules
  rules:

    # 告警规则配置，服务停止5分钟以上就发送告警
  - alert: nodefilesystemUsage			
    expr: 100 - (node_filesystem_free_bytes{fstype=~"ext4|xfs"} / node_filesystem_size_bytes{fstype=~"ext4|xfs"} * 100) > 80
    for: 1m
    labels:
      severity: Warning
    annotations:
      summary: "Instance {{ $labels.instance }} : {{ $labels.mountpoint}} 分区使用率过高"
      description: "{{ $labels.instance }} ： {{ $labels.mountpoint }} 分区使用率大于80% (当前值：{{ $value }})."
      #{{ $value }} 是上面expr条件中获取的值；
```

检测一下配置文件语法是否有问题：

```
./promtool check config ./prometheus.yml 
```

重启Prometheus

```
systemctl restart prometheus.service
```

配置生效之后就可以看到配置规则了，浏览器访问：http://192.168.83.136:9090

![1585134711105](https://note.youdao.com/yws/api/personal/file/EFADFE817E1641C1A90EB05E307C0EB1?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)



模拟一下mysqld_export宕机

```
[root@localhost ~]# ps -ef|grep mysqld
root      12288   7304  0 16:11 pts/0    00:00:06 ./mysqld_exporter --config.my-cnf=/usr/local/mysqld_exporter/my.cnf
root      19392  12408  0 18:31 pts/1    00:00:00 grep --color=auto mysqld
[root@localhost ~]# kill -9 12288
```

然后在Prometheus的监控页面也可以看得到故障了：

![1585046141326](https://note.youdao.com/yws/api/personal/file/F5238FBA9E9D4EC199604DEA0E4A01C6?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

上图的state状态如果是FIRING的话就会通知Alertmanager会等待预设的时间然后发送告警

正常的话也可以收到邮件告警了

Alertmanager相关配置官方文档如下：

```
https://prometheus.io/docs/alerting/configuration/
```

支持企业微信告警，

```
[ wechat_api_url: <string> | default = "https://qyapi.weixin.qq.com/cgi-bin/" ]
[ wechat_api_secret: <secret> ]
[ wechat_api_corp_id: <string> ]
```

目前不支持钉钉告警，可以在github上下载第三方插件来实现，也是使用webhook接口来实现的；

如需对接第三方系统的话也可以使用webhook来实现；

----------------

### 告警状态：

| 告警状态 | 描述                                             |
| -------- | ------------------------------------------------ |
| Inactive | 这里什么都没有发生，等待发送通知给alertmanager   |
| Pending  | 已触发阈值，但未满足告警持续时间                 |
| Firing   | 已触发阈值且满足告警持续时间。警报发送给接受者。 |

--------------

### 告警分配：

多个route分配规则策略，根据不同的服务发送给相关的接收者

```
#多个接收器，根据标签匹配发送不同的接收器，如果标签不匹配会发送到默认的接收器；
route:			
  receiver: 'default-receiver'		#默认接收器，如果所有规则都不匹配的话就会发送到这个接收器
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  group_by: [cluster, alertname]
  
  routes:						#子路由
  - receiver: 'database-pager'		#定义接收器，名称可以自定义
    group_wait: 10s
    match_re:						#match_re正则匹配
      service: mysql|cassandra #匹配service=mysql或cassandra的就会发送到database-pager接收器中，可以根据实际情况去设置这个标签；	
 
  - receiver: 'frontend-pager'		#定义接收器，名称可以自定义
    group_by: [product, environment]
    match:							#match匹配
      team: frontend		#所有带有team等于frontend的标签告警都会发送到frontend-pager接收器，可以根据实际情况去设置这个标签；	

  receivers:					#定义接收器组,接收告警信息的成员就在这里配置
  - name: ‘database-pager'			#接收告警的组名，和上面要保持一致
      email_configs:				#配置邮件的告警方式
      - to: 'xiaofeige@163.com'	#告警接收者邮箱
  - name: ‘frontend-pager'			#另一个接收告警的组名，和上面要保持一致
      email_configs:					#配置邮件的告警方式
      - to: 'xiaofeige@163.com'	#告警接收者邮箱
```

-------------

### 告警收敛

alertmanager告警收敛中有很多中机制，主要的有三种：分组，抑制，静默

| 名称               | 描述                                             |
| ------------------ | ------------------------------------------------ |
| 分组（group）      | 将类似性质的警报分类为单个通知                   |
| 抑制（Inhibition） | 当警报发出后，停止重复发送由此警报引发的其他警报 |
| 静默（Silences）   | 是一种简单的特定时间静音提醒的机制               |

 1、分组：减少告警消息的数量、同类告警聚合帮助运维排查问题

```
vim alertmanager.yml
route:
  group_by: ['alertname']	#根据标签进行分组，可以写多个标签用逗号分开
  group_wait: 10s			#发送告警等待时间，10s内收到相同的告警就合并为一封邮件发送
  group_interval: 10s		#发送告警间隔时间。
  repeat_interval: 30m		#重复告警发送间隔时间。
```

2、抑制规则，当收到告警标签

```
vim alertmanager.yml
inhibit_rules:				#抑制规则配置，主要是消除冗余的告警
  - source_match:			#匹配告警发送之后其他告警就会被抑制掉，其他告警指的是其他的target_match
      severity: 'critical'	#当收到告警级别是（critical）危险时就会抑制掉下面warning的告警邮件；
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']	#所有的告警必须要匹配这里的标签这个规则才成立，标签可以在Prometheus主配文件或者相关文件中定义，equal（等于的意思）

```

3、静默（Silences）配置静默在alertmanager管理后台中配置，其主要的作用是用于预期告警，例如服务更新维护时间可以启用静态模式，默认监听端口是：9093，访问的地址是：http://192.168.83.136:9093/

![1585129854376](https://note.youdao.com/yws/api/personal/file/37A495B456794C079795B81B85AB4681?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

-----------

### 一条告警的出发流程：

![1585131614738](https://note.youdao.com/yws/api/personal/file/8846FA2F546546308D2B5B88A60CCF68?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)