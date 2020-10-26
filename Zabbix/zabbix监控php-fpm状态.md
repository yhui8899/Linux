### 监控PHP-fpm状态

PHP-FPM工作模式通常与nginx结合使用，首先在php-fpm.conf配置文件中添加如下配置：

```shell
pm.status_path = /php-fpm_status
```

修改nginx配置文件，通过nginx获取php-fpm的状态，将如下配置写入nginx配置文件中；

vim  nginx_php-fpm_status.conf

```shell
server {
        listen 82;
        server_name localhost;

        location /nginx-status {
            stub_status on;
            access_log off;
            #allow 127.0.0.1;
            #deny all;
     }
        location /php-fpm_status {
             fastcgi_pass 127.0.0.1:9000;
             fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
             include fastcgi_params;
      }
}
```

访问测试php-fpm_status，能获取到如下相关信息说明配置正确；

```shell
[root@localhost ~]# curl -s http://192.168.10.2:82/php-fpm_status
pool:                 www
process manager:      dynamic
start time:           16/Oct/2020:11:01:11 +0800
start since:          8749
accepted conn:        2257
listen queue:         0
max listen queue:     0
listen queue len:     128
idle processes:       199
active processes:     1
total processes:      200
max active processes: 2
max children reached: 0
slow requests:        3
```

php-fpm_status 信息详解如下：

```shell
pool #fpm池名称,大多数为www
process manager #进程管理方式dynamic或者static
start time #启动日志,如果reload了fpm，时间会更新
start since #运行时间
accepted conn #当前池接受的请求数
listen queue #请求等待队列,如果这个值不为0,那么需要增加FPM的进程数量
max listen queue #请求等待队列最高的数量
listen queue len #socket等待队列长度
idle processes #空闲进程数量
active processes #活跃进程数量
total processes #总进程数量
max active processes #最大的活跃进程数量（FPM启动开始计算）
max children reached #程最大数量限制的次数，如果这个数量不为0，那说明你的最大进程数量过小,可以适当调整。
```

使用脚本获取php-fpm的状态值，将如下代码写入脚本文件中，这里脚本放在/service/scripts/目录下；

cd /service/scripts/

vim php-fpm_status.sh

```shell
#!/bin/bash

PHPFPM_COMMAND=$1
PHPFPM_PORT=82
start_since(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^start since:/ {print $NF}'
}
accepted_conn(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^accepted conn:/ {print $NF}'
}
listen_queue(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^listen queue:/ {print $NF}'
}
max_listen_queue(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^max listen queue:/ {print $NF}'
}
listen_queue_len(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^listen queue len:/ {print $NF}'
}
idle_processes(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^idle processes:/ {print $NF}'
}
active_processes(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^active processes:/ {print $NF}'
}
total_processes(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^total processes:/ {print $NF}'
}
max_active_processes(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^max active processes:/ {print $NF}'
}
max_children_reached(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^max children reached:/ {print $NF}'
}
slow_requests(){
    /usr/bin/curl -s "http://localhost:"$PHPFPM_PORT"/php-fpm_status" |awk '/^slow requests:/ {print $NF}'
}

case $PHPFPM_COMMAND in
    start_since)
            start_since;
            ;;
    accepted_conn)
            accepted_conn;
            ;;
    listen_queue)
            listen_queue;
            ;;
    max_listen_queue)
            max_listen_queue;
            ;;
    listen_queue_len)
            listen_queue_len;
            ;;
    idle_processes)
            idle_processes;
            ;;
    active_processes)
            active_processes;
            ;;
    total_processes)
            total_processes;
            ;;
    max_active_processes)
            max_active_processes;
            ;;
    max_children_reached)
            max_children_reached;
            ;;
    slow_requests)
            slow_requests;
            ;;
    *)
            echo $"USAGE:$0 {start_since|accepted_conn|listen_queue|max_listen_queue|listen_queue_len|idle_processes|active_processes|total_processes|max_active_processes|max_children_reached}"
esac
```

给脚本添加执行权限

```shell
chmod +x php-fpm_status.sh
```

测试脚本是否能够获取到PHP-FPM的状态值，有返回值说明正常：

```shell
[root@localhost scripts]# sh php-fpm_status.sh total_processes
200
```

添加如下配置到zabbix-agent配置文件中：

```shell
UserParameter=php-fpm_status[*],/usr/bin/sh /service/scripts/php-fpm_status.sh $1
```

重启zabbix-agent

```shell
/etc/init.d/zabbix_agentd restart
```

在zabbix服务端测试获取php-fpm状态值，有返回值说明正常：

```shell
zabbix_get -s 192.168.10.2 -k php-fpm_status[total_processes]
200
```

在zabbix的web页面中创建模板：

【创建模板】

![image-20201016134016217](https://note.youdao.com/yws/api/personal/file/EADD7A59E5FA4EF3ABD64B2FE065806C?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20201016134817774](https://note.youdao.com/yws/api/personal/file/F7A251A1EFE143D08FAF957B37CB6C86?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

【创建监控项】

![image-20201016135318509](https://note.youdao.com/yws/api/personal/file/71A23DD71A684135A0442615100C7607?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20201016135348475](https://note.youdao.com/yws/api/personal/file/3943389FE3E64EDD870B3BA39CAADCA0?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

根据如上方式添加10个相关监控项：start_since、accepted_conn、listen_queue、max_listen_queue、listen_queue_len、idle_processes、active_processes、total_processes、max_active_processes、max_children_reached

![image-20201016135746440](https://note.youdao.com/yws/api/personal/file/9BF36980199E44E5963F76B4734B9A4E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

【创建图形】

![image-20201016140713100](https://note.youdao.com/yws/api/personal/file/6F8303C948264C0F9D1F091B8E953A0E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

【查看图形数据】

![image-20201016140749176](https://note.youdao.com/yws/api/personal/file/56A7223C4FFD49A5955687D6FD0E9C55?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

可以配置触发器在监控指标中设置active processes一分钟超过30就报警；

关于zabbix监控php-fpm状态就到此结束；




