## harbor镜像仓库部署：

wget -c https://storage.googleapis.com/harbor-releases/harbor-offline-installer-v1.6.1.tgz

tar -xf harbor-offline-installer-v1.6.1.tgz

cd harbor

```
vim  harbor.cfg 
hostname = 192.168.83.129
harbor_admin_password = Harbor12345		#设置harbor登录密码，默认是：Harbor12345	
```

**安装docker-compose-Linux-x86_64**

```
由于docker-compose是二进制包直接放到/usr/bin目录下即可使用

mv  docker-compose-Linux-x86_64   /usr/bin/docker-compose

chmod +x  /usr/bin/docker-compose
```

进入harbor目录：

```
cd harbor

./prepare 

./install.sh 

正常装完会自动启动harbor

手动启动harbor：docker-compose up -d 注意：必须在harbor目录下执行，否则会报错找不到配置文件；

注意：如果主机原来启用了80端口的话会有冲突导致启动barbor失败；
```



查看barbor状态：

docker-compose ps

登录：http://192.168.83.129 ，账号：admin  密码：Harbor12345

——————————————————————————————————

传镜像：

先登录镜像仓库，默认是以https访问镜像仓库的如果是http访问的话需要在/etc/docker/daemon.json文件中添加可信任，代码如下：

```
 {"insecure-registries":["192.168.83.129"]}
```

或者添加如下覆盖原有的即可：

```
{"registry-mirrors": ["http://f1361db2.m.daocloud.io"],
 "insecure-registries":["192.168.83.129"]
}
```

添加完成之后重启docker生效

登录仓库：

docker login 192.168.83.129

提示输入用户名密码登录即可；

**推送镜像前需要先打tag**

```
barbor指导：
docker tag SOURCE_IMAGE[:TAG] 192.168.83.129/library/IMAGE[:TAG]

如：
docker tag nginx:v1 192.168.83.129/library/nginx:v1
docker tag php:v1 192.168.83.129/library/php:v1
```



**然后在push上传到镜像仓库：**

```
docker push 192.168.83.129/library/php:v1

docker push 192.168.83.129/library/nginx:v1

上传完镜像之后在barbor页面项目中的library可以看见刚刚push的镜像；

```



