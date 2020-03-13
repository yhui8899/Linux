#git安装部署笔记：

### 部署gitlab：

##### gitlab服务器：192.168.83.138

##### gitlab对内存要求较高，建议6G以上内存，内存不足会报错

下载gitlab版本：gitlab-ce-10.2.3-ce.0.el7.x86_64.rpm    #ce为社区版，免费

##### rpm包安装gitlab

```
rpm -ivh gitlab-ce-10.2.3-ce.0.el7.x86_64.rpm
```

##### 安装相关软件包：

```
yum install curl policycoreutils openssh-server openssh-clients postfix -y
```

##### 第一次启动gitlab的时候需要初始化:

##### 执行命令：gitlab-ctl  reconfigure     #直到出现如下信息表示完成：

Running handlers:
Running handlers complete
Chef Client finished, 382/541 resources updated in 02 minutes 30 seconds
gitlab Reconfigured!

##### 默认gitlab是安装的/opt/gitlab目录下，可以查看一下

​	

```
查看gitlab安装命令：rpm -pql  gitlab-ce-10.2.3-ce.0.el7.x86_64.rpm|more
```



##### 查看一下gitlab状态：

gitlab-ctl status	显示如下信息为正常

```
[root@localhost ~]# gitlab-ctl status
run: gitaly: (pid 4122) 130s; run: log: (pid 3781) 185s
run: gitlab-monitor: (pid 4140) 129s; run: log: (pid 3856) 173s
run: gitlab-workhorse: (pid 4103) 130s; run: log: (pid 3728) 198s
run: logrotate: (pid 3765) 191s; run: log: (pid 3764) 191s
run: nginx: (pid 3738) 197s; run: log: (pid 3737) 197s
run: node-exporter: (pid 3831) 179s; run: log: (pid 3830) 179s
run: postgres-exporter: (pid 4172) 128s; run: log: (pid 3993) 155s
run: postgresql: (pid 3507) 252s; run: log: (pid 3506) 252s
run: prometheus: (pid 4158) 128s; run: log: (pid 3936) 161s
run: redis: (pid 3446) 263s; run: log: (pid 3445) 263s
run: redis-exporter: (pid 3910) 167s; run: log: (pid 3909) 167s
run: sidekiq: (pid 3712) 199s; run: log: (pid 3711) 199s
run: unicorn: (pid 3674) 206s; run: log: (pid 3673) 206s
```

##### 访问一下gitlab页面：

http://192.168.83.138

默认使用nginx做为web界面。
注：如果后期web界面访问时，总报502，要把防火墙清空规则，另外内存要大于4G，不然内存不够也报502错误；

##### 第一次登陆的时候需要为root设置密码，root是gitlab的超级管理员

管理gitlab命令如下：

```
启动gitlab：gitlab-ctl	start

重启gitlab：gitlab-ctl	restart

停止gitlab：gitlab-ctl	stop
```



### 汉化gitlab：

1、上传汉化补丁：gitlab-patch-zh.tat.gz

2、也可到GitHub下载汉化补丁：

```
git clone https://gitlab.com/xhang/gitlab.git

# 默认是下载最新的汉化版本，如要下载指定版本如下：

git clone https://gitlab.com/xhang/gitlab.git -b v10.23-zh
```

##### 查看补丁版本：cat gitlab/VERSION

```
cd  gitlab

git diff v10.2.3 v10.2.3-zh > ../10.2.3-zh.diff     #生成10.2.3-zh.diff文件

patch -d /opt/gitlab/embedded/service/gitlab-rails -p1 < /root/10.2.3-zh.diff
```

##### 如果提示如下：

```
|diff --git a/app/assets/javascripts/awards_handler.js b/app/assets/javascripts/awards_handler.js

|index 976d32a..7967edb 100644

|--- a/app/assets/javascripts/awards_handler.js

|+++ b/app/assets/javascripts/awards_handler.js

\--------------------------

File to patch:

#这个报错可以直接按回车跳过，这是因为补丁中有一些较新的文件，但是我们安装的gitlab并没有这个文件存在；
```

如果报错提示没有patch这个命令则需要安装：yum install patch -y  安装后再执行即可

汉化完之后重启gitlab：gitlab-ctl   restart

登录gitlab页面：

http://192.168.83.138		#看到中文页面，表示汉化成功；

如果启动报错的话检查端口是否被占用或者重启服务：

```
gitlab-ctl reconfigure

gitlab-ctl restart
```

如上无法解决，请查看报错日志；



##### 安装git客户端使用gitlab

​	yum  install  gitlab  -y

##### 修改gitlab仓库默认的域名：gitlab.example.com

vim /var/opt/gitlab/gitlab-rails/etc/gitlab.yml

把host 改为IP地址或者域名，默认是：gitlab.example.com

```
 gitlab:
    ## Web server settings (note: host is the FQDN, do not include http://)
    host: 192.168.83.138		#把gitlab默认的域名改为IP地址或域名即可
    port: 80
    https: false
```

如上配置修改完重启gitlab即可；gitlab-ctl restart

##### 从gitlab仓库拉取代码：

​	git clone  http://192.168.83.138/xiaofeige/xiaofeige-web.git







