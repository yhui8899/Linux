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
