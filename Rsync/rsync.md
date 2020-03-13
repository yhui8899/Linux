# 								Rsync同步

##### 普通文件推送或拉取

##### 本地文件同步：

```
rsync -avz /bak/ /tmp/  #将本地的/bak/目录同步至/tmp/目录, 

rsync -avz --delete /bak/ /tmp/ --delete  #将本地的/bak/目录同步至/tmp/目录,--delete参数用于删除源目录中不存在而目标目录中存在的文件或目录

```

##### 远程文件推送拉取：

```
push：推送文件  rsync  -avz /etc/hosts -e 'ssh -p 22'  root@192.168.83.144:/home
	# 'ssh -p 22'  指定ssh和端口

pull：拉取文件 rsync  -avz /etc/hosts -e 'ssh -p 22'  root@192.168.83.144:/home/hosts /tmp
```



##### 参数详解：

-a  :归档模式，表示以递归方式传输文件，并保持所有文件属性，等同于 -rtopgD参数一样

-v  :详细模式输出，传输是的进度等信息

-z  --compress : 传输时进行压缩以提高传输效率，--compress-level=NUM 可按级别压缩

-r   ：递归，对子目录以递归模式，即目录下所有目录都同样传输

-t    :保持文件时间信息

-P   ：显示同步的过程及传输是的进度信息

-e    :使用的信道协议，指定替代rsh的shell程序，例如：ssh

--exclude=PATTERN: 指定排除不需要传输的文件模式

-avz   相当于：vzrtopgDl参数  -avz是最常用的



##### 实例：

```
push：rsync -avz /etc/hosts -e "ssh -p22" root@192.168.83.137:/tmp

pull：rsync -avz -e "ssh -p22" root@192.168.83.137:/tmp/hosts  /tmp
以上所使用的是系统用户来传输的
```



----------------

### 守护进程方式：

服务端：192.168.83.128

客户端：192.168.83.144

客户端：192.168.83.137

##### 客户端往服务端传送数据：

服务端rsyncd.conf 配置如下：

```
uid = rsync			
gid = rsync
use chroot = no
max connections = 200		#最大连接数
timeout = 100				#超时时间
pid file = /var/log/rsync/rsyncd.pid	
lock file = /var/log/rsync/rsync.lock    #锁文件，服务启动或者停止的时候会用到
log file = /var/log/rsync/rsyncd.log

[data]			#模块名称，自定义
path = /wwwroot/		#rsync服务端路径，将来客户端要往这里传文件或者从这里拉取文件；
ignore errors			#忽略错误
read only = false		#关闭只读，即允许用户读写文件
list = false			#可以读取列表文件
host allow = *			#允许主机连接
hosts deny = 0.0.0.0/32		#拒绝主机连接
auth users = rsync_backup	#验证授权用户，即虚拟用户
secrets file = /etc/rsyncd.password		#指定上面虚拟用户的密码文件
```

创建一个rsync用户：useradd rsync -s /sbin/nologin -M		# -M  不创建家目录

chown  -R rsync.rsync /wwwroot/				#目录授权

echo "rsync_backup:yhui8899" >> /etc/rsyncd.password		#将用户和密码写到密码文件，用户就是上面授权的用户；

chmod 600 /etc/rsyncd.password			#鉴于安全问题所以需要对这个文件修改权限，让其他用户看不见

启动rsync:

rsync --daemon

也可以用：systemctl  start  rsyncd

```
[root@localhost ~]# ps -ef|grep rsync
root      11104   1382  0 06:30 pts/0    00:00:00 man rsync
root      13800      1  0 07:56 ?        00:00:00 rsync --daemon
root      13805   1382  0 07:57 pts/0    00:00:00 grep --color=auto rsyn
或者：
[root@localhost ~]# netstat -tnlp|grep 873
tcp        0      0 0.0.0.0:873             0.0.0.0:*               LISTEN      13800/rsync         
tcp6       0      0 :::873                  :::*                    LISTEN      13800/rsync  

rsync默认端口是：873
```

##### 可以使用lsof  -i tcp:873 端口来查询服务

```
[root@localhost ~]# lsof -i tcp:873
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
rsync   13800 root    4u  IPv4  72899      0t0  TCP *:rsync (LISTEN)
rsync   13800 root    5u  IPv6  72900      0t0  TCP *:rsync (LISTEN)
```

到此服务端就配置完成：

------------

#### 配置客户端：

配置密码文件：

```
echo "yhui8899"  >/etc/rsync.password  #注意这里的密码要和服务端配置的一样，因为客户端就是使用这个密码去连接服务器的；
```

设置权限：

```
chmod  600  /etc/rsync.password 
```

到此客户端就配置完成了，只有这两步；

---------------

##### 守护进程的使用语法：

```
Access via rsync daemon:
         Pull: rsync [OPTION...] [USER@]HOST::SRC... [DEST]
               rsync [OPTION...] rsync://[USER@]HOST[:PORT]/SRC... [DEST]
         Push: rsync [OPTION...] SRC... [USER@]HOST::DEST
               rsync [OPTION...] SRC... rsync://[USER@]HOST[:PORT]/DEST
```

测试：

先做备份，然后将备份文件传送到服务器：

```
tar -czvf html_$(date +%F).tar.gz ORCLfmap/      #按日期命名：
```

#### 执行push推送同步命令：

案例一：rsync [OPTION...] SRC... [USER@]HOST::DEST		模块的方式

```
rsync -avzp html_2019-12-29.tar.gz rsync_backup@192.168.83.128::data   
#data是服务端配置文件中定义的模块名
```

出现报错：

```
[root@localhost opt]# rsync -avzp html_2019-12-29.tar.gz rsync_backup@192.168.83.128::data
Password: 
sending incremental file list
html_2019-12-29.tar.gz
rsync: chgrp ".html_2019-12-29.tar.gz.ECDeYm" (in data) failed: Operation not permitted (1)

sent 107 bytes  received 2,719 bytes  628.00 bytes/sec
total size is 300,947  speedup is 106.49
rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1178) [sender=3.1.2]
```

报错原因：这个文件的owner和group都是root，而我同步过去的用户是rsync用户是一个普通用户不是root，因此报错。

##### 解决方法：把这个文件权限改成rsync即可：

chown rsync.rsync html_2019-12-29.tar.gz 

##### 再重新执行一遍同步命令：

rsync -avzp html_2019-12-29.tar.gz rsync_backup@192.168.83.128::data

```
[root@localhost opt]# rsync -avzp html_2019-12-29.tar.gz rsync_backup@192.168.83.128::data
Password: 
sending incremental file list
html_2019-12-29.tar.gz

sent 121 bytes  received 2,623 bytes  609.78 bytes/sec
total size is 300,947  speedup is 109.67
```

OK ，没有报错啦；

##### 由于上面没有指定密码文件所以需要手工输入密码，接下来指定一下密码文件：

rsync -avzp html_2019-12-29.tar.gz rsync_backup@192.168.83.128::data --password-file=/etc/rsync.password

```
[root@localhost opt]# rsync -avzp html_2019-12-29.tar.gz rsync_backup@192.168.83.128::data --password-file=/etc/rsync.password
sending incremental file list

sent 78 bytes  received 20 bytes  196.00 bytes/sec
total size is 300,947  speedup is 3,070.89
```

##### 上面看到已经不需要输入密码啦；

--------------------------------

##### 案例二：rsync [OPTION...] SRC... rsync://[USER@]HOST[:PORT]/DEST	

rsync -avzp html_2019-12-29.tar.gz rsync://rsync_backup@192.168.83.128:873/data --password-file=/etc/rsync.password

##### 或者不加端口号：

rsync -avzp html_2019-12-29.tar.gz rsync://rsync_backup@192.168.83.128/data --password-file=/etc/rsync.password 

```
[root@localhost opt]# rsync -avzp html_2019-12-29.tar.gz rsync://rsync_backup@192.168.83.128:873/data --password-file=/etc/rsync.password   
sending incremental file list
html_2019-12-29.tar.gz

sent 299,302 bytes  received 43 bytes  598,690.00 bytes/sec
total size is 300,947  speedup is 1.01
```

##### 以上两种方式都可以；

-----------------------

Linux 推送数据给Windows：

以Windows为服务端：192.168.83.144

客户端：192.168.83.137

服务端的rsyncd.conf配置文件如下：

```
use chroot = false
strict modes = false
hosts allow = *
log file = rsyncd.log
lock file = rsyncd.lock
port = 873
uid = 0
gid = 0
max connections = 10

# Module definitions
# Remember cygwin naming conventions : c:\work becomes /cygwin/c/work
#
[webtest]
path = /cygdrive/d/wwwroot/test
read only = false
hosts allow = 192.168.83.144,192.168.83.128,192.168.83.137
auth users = rsync_backup
secrets file = rsync.secrets
transfer logging = yes
```

##### rsync.secrets内容：给客户连接的账号密码

```
rsync_backup:123456
```

##### 客户端执行数据推送命令：

rsync -avz html_2019-12-29.tar.gz --port 873 rsync_backup@192.168.83.144::webtest --password-file=/etc/rsync.password

```
[root@localhost opt]# rsync -avz html_2019-12-29.tar.gz --port 873 rsync_backup@192.168.83.144::webtest --password-file=/etc/rsync.password
sending incremental file list
html_2019-12-29.tar.gz

sent 299,294 bytes  received 34 bytes  54,423.27 bytes/sec
total size is 300,947  speedup is 1.01
```

看到如上信息表示文件推送成功