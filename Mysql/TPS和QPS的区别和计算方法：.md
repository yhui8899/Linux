# TPS和QPS的区别：

QPS：Queries Per Second，意思是“每秒查询率”，是一台服务器每秒能够响应的查询次数，是对一个特定的查询服务器（比如是读写分离的架构，就是读的服务器）在规定时间内所处理流量多少的衡量标准。

TPS：TransactionsPerSecond，意思是每秒事务数，一个事务是指一个客户机向服务器发送请求然后服务器做出反应的过程。客户机在发送请求时开始计时，收到服务器响应后结束计时，以此来计算使用的时间和完成的事务个数。

 

##### tps，即每秒处理事务数，每个事务包括了如下3个过程：

　　a.用户请求服务器

　　b.服务器自己的内部处理（包含应用服务器、数据库服务器等）

　　c.服务器返回给用户

　　如果每秒能够完成N个这三个过程，tps就是N；

 

qps，如果是对一个页面请求一次，形成一个tps，但一次页面请求，可能产生多次对服务器的请求（页面上有很多html资源，比如图片等），服务器对这些请求，就可计入“Qps”之中；

​         但是，如今的项目基本上都是前后端分离的，性能也分为前端性能和后端性能，通常默认是后端性能，即服务端性能，也就是对服务端接口做压测

​               如果是对一个接口（单场景）压测，且这个接口内部不会再去请求其它接口，那么tps=qps，否则，tps≠qps

​               如果是对多个接口（混合场景）压测，不加事务控制器，jmeter会统计每个接口的tps，而混合场景是要测试这个场景的tps，显然这样得不到混合场景的tps，所以，要加了事物控制器，结果才是整个场景的tps。

---------------------------------



在对数据库的性能监控上经常会提到QPS和TPS这两个名词，下面就分别简单的分享一下关于MySQL数据库中的QPS和TPS的意义和计算方法。

##### 1、QPS: 每秒Query 量，这里的QPS 是指MySQL Server 每秒执行的Query总量，计算方法如下：

```
Questions = SHOW GLOBAL STATUS LIKE 'Questions';
Uptime = SHOW GLOBAL STATUS LIKE 'Uptime';
QPS=Questions/Uptime
```

##### 2、 TPS: 每秒事务量，通过以下方式来得到客户端应用程序所请求的 TPS 值，计算方法如下：

```
Com_commit = SHOW GLOBAL STATUS LIKE 'Com_commit';
Com_rollback = SHOW GLOBAL STATUS LIKE 'Com_rollback';
Uptime = SHOW GLOBAL STATUS LIKE 'Uptime';
TPS=(Com_commit + Com_rollback)/Uptime
```

