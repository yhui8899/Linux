һ��nginx
������nginx������������Ҫ��volume��wwwroot���ص�������
ǰ�᣺
1�������Զ������磺docker network create net-test
2������volume��docker volume create wwwroot
3������������docker run -itd --name=lnmp_nginx --net=net-test --mount src=wwwroot,dst=/wwwroot -h lnmp_nginx -p88:80 5cef3d3992eb

����PHP
������PHP������������Ҫ��volume��wwwroot���ص�������
docker run -itd --name=lnmp_php --net=net-test --mount src=wwwroot,dst=/wwwroot -h lnmp_php 50d1abfa674f

ע�⣺��������PHP����������nginx����