一、nginx
构建完nginx后启动容器需要将volume的wwwroot挂载到容器；
前提：
1、创建自定义网络：docker network create net-test
2、创建volume卷：docker volume create wwwroot
3、启动容器：docker run -itd --name=lnmp_nginx --net=net-test --mount src=wwwroot,dst=/wwwroot -h lnmp_nginx -p88:80 5cef3d3992eb

二、PHP
构建完PHP后启动容器需要将volume的wwwroot挂载到容器；
docker run -itd --name=lnmp_php --net=net-test --mount src=wwwroot,dst=/wwwroot -h lnmp_php 50d1abfa674f

注意：需先启动PHP容器再启动nginx容器