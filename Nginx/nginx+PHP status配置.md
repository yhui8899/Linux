### 启用nginx status配置

在默认主机里面加上location或者你希望能访问到的主机里面。

```
server {
    location /nginx-status {
        stub_status on;
        #access_log /home/www/phpernote/nginx_status.log;//访问日志，这里可以设置为off将其关闭
        access_log off;
        #allow 127.0.0.1;#允许访问的IP
        #deny all;
    }
}
```

**重启nginx**
**请依照你的环境重启你的nginx**

service nginx restart

打开status页面，这里是通过命令行获取的，将得到如下结果：

curl http://127.0.0.1/nginx-status

```
Active connections: 11921 
server accepts handled requests
 11989 11989 11991 
Reading: 56 Writing: 127 Waiting: 242
```



**nginx status详解**

```
active connections – 活跃的连接数量

server accepts handled requests — 总共处理了11989个连接 , 成功创建11989次握手, 总共处理了11991个请求

reading — 读取客户端的连接数

writing — 响应数据到客户端的数量

waiting — 开启 keep-alive 的情况下,这个值等于 active – (reading+writing), 意思就是 Nginx 已经处理完正在等候下一次请求指令的驻留连接。所以,在访问效率高,请求很快被处理完毕的情况下,Waiting数比较多是正常的.如果reading +writing数较多,则说明并发访问量非常大,正在处理过程中。

以上是nginx的status信息

php-fpm和nginx一样内建了一个状态页，对于想了解php-fpm的状态以及监控php-fpm非常有帮助。

启用php-fpm状态功能
编辑php-fpm.conf 配置文件 找到pm.status_path配置项

pm.status_path = /php-status

nginx配置
在默认主机里面加上location或者你希望能访问到的主机里面。
```



```
server {
    #nginx的状态页面
    location /nginx-status {
        stub_status on;
        access_log off;
        #allow 127.0.0.1;#允许访问的IP
        #deny all;
    }
```


   #php的状态页面
    location /php-status {
        fastcgi_pass  127.0.0.1:9000;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $fastcgi_script_name;
        #allow x.x.x.x;
        access_log off;
        #deny all;
    }
}
重启nginx和php-fpm
打开status页面

```
pool:                      www
process manager:      dynamic
start time:           13/Nov/2018:15:29:58 +0800
start since:          1237
accepted conn:        54
listen queue:         0
max listen queue:     0
listen queue len:     128
idle processes:       14
active processes:     1
total processes:      15
max active processes: 1
max children reached: 0
slow requests:        0
```

**php-fpm status详解**

```
pool – fpm池子名称，大多数为www 
process manager – 进程管理方式,值：static, dynamic or ondemand. dynamic 
start time – 启动日期,如果reload了php-fpm，时间会更新 
start since – 运行时长 
accepted conn – 当前池子接受的请求数 
listen queue – 请求等待队列，如果这个值不为0，那么要增加FPM的进程数量 
max listen queue – 请求等待队列最高的数量 
listen queue len – socket等待队列长度 
idle processes – 空闲进程数量 
active processes – 活跃进程数量 
total processes – 总进程数量 
max active processes – 最大的活跃进程数量（FPM启动开始算） 
max children reached - 大道进程最大数量限制的次数，如果这个数量不为0，那说明你的最大进程数量太小了，请改大一点。 
6、 php-fpm状态页可以通过带参数实现个性化，可以带参数json、xml、html并且前面三个参数可以分别和full做一个组合。

json格式：http://127.0.0.1/php-status?json

xml格式： http://127.0.0.1 /php-status?xml

html 格式： http://127.0.0.1 /php-status?html 
full格式： http://127.0.0.1 /php-status?full
```

full详解

```
pid – 进程PID，可以单独kill这个进程. You can use this PID to kill a long running process. 
state – 当前进程的状态 (Idle, Running, …) 
start time – 进程启动的日期 
start since – 当前进程运行时长 
requests – 当前进程处理了多少个请求 
request duration – 请求时长（微妙） 
request method – 请求方法 (GET, POST, …) 
request URI – 请求URI 
content length – 请求内容长度 (仅用于 POST) 
user – 用户 (PHP_AUTH_USER) (or ‘-’ 如果没设置) 
script – PHP脚本 (or ‘-’ if not set) 
last request cpu – 最后一个请求CPU使用率。 
last request memorythe - 上一个请求使用的内存
```

查看php-fpm的slowlog 慢执行
通过slow requests: 52 发现有慢执行

php-fpm.conf 配置文件

找到request_slowlog_timeout = 0这一行，默认值为0，表示不开启slowlog，将其值改为3s，表示跟踪执行时间达到或超过3s的脚本。 
找到slowlog，它的值表示慢执行日志的路径。

修改完后需要重启php， 
查看日志文件，slowlog的文件的内容大概是这样的：

[31-Dec-2012 09:50:00] [pool www] pid 2874 
script_filename = /htdocs/blog/index.php 
[0x0000000001cf4ff0] mysql_query() /htdocs/blog/class/mysql.php:9 
[0x0000000001cf4ec0] query() /htdocs/blog/class/mysql.php:26 
[0x0000000001cf4a70] one() /htdocs/blog/class/ware.php:88 
[0x0000000001cf46c8] query() /htdocs/blog/function/common.php:132 
[0x0000000001cf3a40] +++ dump failed 
这样就可以很明显看到什么mysql.php的mysql_query()方法执行的语句超时了。

