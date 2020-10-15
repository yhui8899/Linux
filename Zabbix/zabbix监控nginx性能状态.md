### zabbix监控nginx性能状态

#### 一、配置nginx

nginx在生产环境中应用广泛，所以需要对nginx性能进行监控，从而发现故障隐患，nginx的监控性能指标可分为：基本活动指标、错误指标、性能指标：

| 名称                        | 描述                        | 指标类型     |
| --------------------------- | --------------------------- | ------------ |
| Accepts（接受）             | nginx所接受的客户端连接数   | 资源：功能   |
| Handled（已处理）           | 成功的客户端连接数          | 资源：功能   |
| Active（活跃）              | 当前活跃的客户端连接数      | 资源：功能   |
| Dropped（已丢弃，计算得出） | 丢弃的连接数（接受-已处理） | 工作：错误   |
| Requests（请求数）          | 客户端请求数                | 工作：吞吐量 |

监控nginx性能状态需要模块的支持，也就是安装：-with-http_stub_status_module模块，然后在nginx配置文件中配置开启status状态，将如下配置写到nginx配置文件中，然后重启nginx；

``` shell
server {
        listen 82;
        server_name localhost;

        location /nginx-status {
        stub_status on;
        access_log off;
        #allow 127.0.0.1;
        #deny all;
     }
}
```

配置启用nginx的status状态后可执行测试一下是否能获取到数据：

curl -s  http://127.0.0.1:82/nginx-status  能获取到如下数据说明配置启用status正常

```shell
[root@localhost ~]# curl -s http://127.0.0.1:82/nginx-status
Active connections: 1 
server accepts handled requests
 9817 9817 9802 
Reading: 0 Writing: 1 Waiting: 0 
```

编写获取nginx性能状态的脚本，将如下代码写入脚本文件中，通过awk取status的各个状态数值；

cd  /usr/local/zabbix/etc/zabbix_agentd.conf.d/

vim nginx_monitor.sh

``` shell
#!/bin/bash
NGINX_PORT=82
NGINX_COMMAND=$1
nginx_active(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk '/Active/ {print $NF}'
}
nginx_reading(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk '/Reading/ {print $2}'
}
nginx_writing(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk '/Writing/ {print $4}'
       }
nginx_waiting(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk '/Waiting/ {print $6}'
       }
nginx_accepts(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk 'NR==3 {print $1}'
       }
nginx_handled(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk 'NR==3 {print $2}'
       }
nginx_requests(){
    /usr/bin/curl -s "http://127.0.0.1:"$NGINX_PORT"/nginx-status/" |awk 'NR==3 {print $3}'
       }
case $NGINX_COMMAND in
active)
nginx_active;
;;
reading)
nginx_reading;
;;
writing)
nginx_writing;
;;
waiting)
nginx_waiting;
;;
accepts)
nginx_accepts;
;;
handled)
nginx_handled;
;;
requests)
nginx_requests;
;;
      *)
echo $"USAGE:$0 {active|reading|writing|waiting|accepts|handled|requests}"
esac
```

给nginx_monitor.sh脚本文件授权：

```shell
chmod +x  nginx_monitor.sh
```

自定义模板将取值status的状态写成脚本，放在UserParmeter后面，最后通过zabbix_get测试·agent端是否得到状态值：

```
Accepts：接受的客户端请求数

Active：当前活跃的连接数

Handled：处理的请求数（正常服务器响应）

Requests：客户端处理的请求出（吞吐量）

Reading:当接收到的请求时，连接离开waiting状态，并且该请求本身使Reading状态统计数增加，这种状态下，nginx会读取客户端请求首部，请求首部是比较小的，因此这通常是一种快捷的操作

Writing：请求被读取之后，使得Writing状态计数增加，并保持在该状态，直到响应返回给客户端，这便意味着，该请求在writing状态时，一方面NGINX
```

#### 二、配置zabbix-agent

修改zabbix_agentd.conf配置文件如下：

vim /usr/local/zabbix/etc/zabbix_agentd.conf

``` shell
LogFile=/tmp/zabbix_agentd.log
Server=192.168.100.5
ServerActive=192.168.100.5
Hostname=web
Include=/usr/local/zabbix/etc/zabbix_agentd.conf.d/*.conf
UnsafeUserParameters=1
UserParameter=status[*],/bin/bash /usr/local/zabbix/etc/zabbix_agentd.conf.d/nginx_monitor.sh "$1"
```

修改文件保存后重启zabbix_agent客户端：

```shell
 /etc/init.d/zabbix_agentd restart
```

测试：

在zabbix服务端测试一下能否获取agent端的nginx状态数值：

```shell
[root@zabbix-server ~]# /usr/local/zabbix/bin/zabbix_get 192.168.100.5 -k status
USAGE:/usr/local/zabbix/etc/zabbix_agentd.conf.d/nginx_monitor.sh {active|reading|writing|waiting|accepts|handled|requests}
#如下是获取到的数据：
[root@zabbix-server ~]# /usr/local/zabbix/bin/zabbix_get 192.168.100.5 -k status[handled]
9290
```

#### 三、配置zabbix web端

【创建模板】：

![image-20201015143552865](https://note.youdao.com/yws/api/personal/file/AA7D71839CEC4516B7487A0220FD48C2?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

【创建监控项】

根据zabbix-agent中的nginx_status.sh的参数，总共要创建active、reading、writing、waiting、accepts、handled、requests这7项

![image-20201015143936479](https://note.youdao.com/yws/api/personal/file/198FB7B9501A4D229669C40A801FDE1B?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20201015144147741](https://note.youdao.com/yws/api/personal/file/53042D6E5B2C45028297D4A914523638?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

按照如上步骤将active、reading、writing、waiting、accepts、handled、requests这7项添加完成

![image-20201015144310770](https://note.youdao.com/yws/api/personal/file/98A958E6C884450A9249C0F5A19569BD?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

[图形创建]

![image-20201015144359456](https://note.youdao.com/yws/api/personal/file/9D53F524205C4C368F95FE4D4E594261?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20201015144505096](https://note.youdao.com/yws/api/personal/file/54F0F8DF08874A5C8067D0AD544E6BFC?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

zabbix监控nginx性能状态到此就结束拉！