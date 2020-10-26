### zabbix监控linux服务器tcp连接状态

获取TCP连接数的方法有如下几种：

```shell
netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,state[key]}'

netstat -an|awk '/^tcp/{print $NF}'|sort|uniq -c|sort -nr

ss -ant | awk 'NR>1 {++s[$1]} END {for(k in s) print k,s[k]}'

# netstat是遍历/proc下面每个PID目录，ss直接读/proc/net下面的统计信息。所以ss执行的时候消耗资源以及消耗的时间都比netstat少很多。
```

编写获取tcp连接数脚本，内容如下：

创建脚本存放目录：

```shell
mkdir -p  /service/scripts/
cd  /service/scripts/
```

创建脚本文件并写入如下内容：

vim  tcp_status.sh

```shell
#!/bin/bash

[ $# -ne 1 ] && echo "Usage:CLOSE-WAIT|CLOSED|CLOSING|ESTAB|FIN-WAIT-1|FIN-WAIT-2|LAST-ACK|LISTEN|SYN-RECV SYN-SENT|TIME-WAIT" && exit 1
tcp_status_fun(){
        TCP_STAT=$1
        #netstat -n | awk '/^tcp/ {++state[$NF]} END {for(key in state) print key,state[key]}' > /tmp/netstat.tmp
        ss -ant | awk 'NR>1 {++s[$1]} END {for(k in s) print k,s[k]}' > /tmp/ss.tmp
        TCP_STAT_VALUE=$(grep "$TCP_STAT" /tmp/ss.tmp | cut -d ' ' -f2)
        if [ -z $TCP_STAT_VALUE ];then
                TCP_STAT_VALUE=0
        fi
        echo $TCP_STAT_VALUE
}
tcp_status_fun $1
```

添加脚本执行权限：

```shell
chmod +x tcp_status.sh
```

在zabbix-agent配置文件中添加如下配置：

```shell
UserParameter=tcp_status[*],/bin/bash /service/scripts/tcp_status.sh "$1"
```

重启zabbix-agent端：

```shell
/etc/init.d/zabbix_agentd restart
```

在zabbix服务端通过zabbix_get测试是否能正常获取值

```shell
zabbix_get -s 192.168.100.101 -k tcp_status[ESTAB] 

获取的内容如下，能正常获取到值说明正常：
[root@localhost ~]# zabbix_get -s 219.129.18.234 -k tcp_status[ESTAB]
2
```

在zabbix web端添加模板和配置监控项图形等：

【添加模板】

![image-20201015171330016](https://note.youdao.com/yws/api/personal/file/31F41B6DDD884AC4B021E1243D618B3E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

【添加监控项】

![image-20201015171444997](https://note.youdao.com/yws/api/personal/file/55501C666A43462BAD4050D3D544B505?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20201015171533485](https://note.youdao.com/yws/api/personal/file/3910A7D4DE9544AFA54519C732D560F1?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

根据如上的方式添加监控项：CLOSED、CLOSE-WAIT-1、ESTAB、CLOSING、CLOSE-WAIT、LAST-ACK、LISTEN、CLOSE-WAIT-2、TIME-WAIT、SYN-SENT、SYN-RCVD等11种TCP状态；

![image-20201015171751818](https://note.youdao.com/yws/api/personal/file/291D360B327F474B96C44C8988AD4140?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

【添加图形】

![image-20201015171821862](https://note.youdao.com/yws/api/personal/file/B2561649420F4D75A7B7D9CD0DA3EC23?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

![image-20201015171910297](https://note.youdao.com/yws/api/personal/file/A2A52C7160C7427D931A2A817F4F434E?method=download&shareKey=538acbd17b6249b46ef3b6a6c3bde9aa)

TCP的11种连接状态详解如下：

```shell
LISTEN：等待从任何远端TCP 和端口的连接请求。
SYN_SENT：发送完一个连接请求后等待一个匹配的连接请求。
SYN_RECEIVED：发送连接请求并且接收到匹配的连接请求以后等待连接请求确认。
ESTABLISHED：表示一个打开的连接，接收到的数据可以被投递给用户。连接的数据传输阶段的正常状态。
FIN_WAIT_1：等待远端TCP 的连接终止请求，或者等待之前发送的连接终止请求的确认。
FIN_WAIT_2：等待远端TCP 的连接终止请求。
CLOSE_WAIT：等待本地用户的连接终止请求。
CLOSING：等待远端TCP 的连接终止请求确认。

LAST_ACK：等待先前发送给远端TCP 的连接终止请求的确认（包括它字节的连接终止请求的确认）
TIME_WAIT：等待足够的时间过去以确保远端TCP 接收到它的连接终止请求的确认。
TIME_WAIT 两个存在的理由：
1.可靠的实现tcp全双工连接的终止；
2.允许老的重复分节在网络中消逝。
CLOSED：不在连接状态（这是为方便描述假想的状态，实际不存在）
```

到此TCP连接状态监控就完成啦；
