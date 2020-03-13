#!/bin/bash
#auto_install_rabbitmq
#2019年4月11日16:09:27
#by Author:xiaofeige
ER_NAME="Erlang"
ER_DIR=/usr/local/erlang
ER_PACK="gcc glibc-devel make ncurses-devel openssl-devel xmlto tar wget"
ER_VERSION="otp_src_20.2"
ER_SOFT="${ER_VERSION}.tar.gz"
ER_SOFT_URL="http://erlang.org/download/$ER_SOFT"

MQ_DIR=/usr/local/rabbitmq
MQ_SOFT="rabbitmq-server-generic-unix-3.6.15.tar"
MQ_SRC_DIR="rabbitmq_server-3.6.15"
MQ_URL="http://www.rabbitmq.com/releases/rabbitmq-server/v3.6.15/${MQ_SOFT}.xz"
MQ_USER="admin"
MQ_PWD="admin123"
IPADDR=`ip addr|grep "global"|cut -f 1 -d /|awk '{print $2}'`

#安装Erlang
function install_Erlang(){
	yum install  $ER_PACK -y

if [[ ! -f $ER_SOFT ]];then
	wget -c $ER_SOFT_URL
fi

	tar -xf $ER_SOFT
	cd $ER_VERSION
if [ $? -ne 0 ];then
	echo -e "\033[31m${ER_VERSION}目录不存在！\033[0m"
	exit 1
fi

	./configure --prefix=$ER_DIR
if [[ $? -ne 0 ]];then
	echo -e "\033[31m${ER_NAME}预编译失败!\033[0m"
	exit 1
fi

	make && make install

if [[ $? -ne 0 ]];then
        echo -e "\033[31m${ER_NAME}编译安装失败!\033[0m"
        exit 1
fi

echo "export PATH=\$PATH:/usr/local/erlang/bin" >>/etc/profile
sleep 2
source /etc/profile
}
#安装RabbitMQ

function install_RabbitMQ(){
if [[ ! -f ${MQ_SOFT}.xz ]];then
	wget -c $MQ_URL
	xz -d ${MQ_SOFT}.xz
	tar -xf $MQ_SOFT
else
	xz -d ${MQ_SOFT}.xz
	tar -xf $MQ_SOFT
fi

if [[ ! -d $MQ_SRC_DIR ]];then
	echo -e "\033[31m${MQ_SRC_DIR}目录不存在!\033[0m"
	exit 1
else
	cp -pa $MQ_SRC_DIR $MQ_DIR
fi

echo export PATH=\$PATH:/usr/local/rabbitmq/sbin >>/etc/profile
source /etc/profile

rabbitmq-server -detached
rabbitmqctl status
if [[ $? -ne 0 ]];then
	echo -e "\033[31mRabbitMQ启动失败，请检查安装是否正确！\033[0m"
	exit 1
fi

rabbitmq-plugins enable rabbitmq_management
if [[ $? -ne 0 ]];then
        echo -e "\033[31mRabbitMQ插件安装失败!\033[0m"
        exit 1
fi

rabbitmqctl add_user ${MQ_USER} $MQ_PWD
rabbitmqctl set_permissions -p "/" ${MQ_USER} ".*" ".*" ".*"
rabbitmqctl set_user_tags ${MQ_USER} administrator

if [[ $? -ne 0 ]];then
	echo -e "\033[31m用户添加失败，请检查程序是否运行!\033[0m"
	exit 1
fi

netstat -tnlp|grep -E "15672|25672"

echo -e "\033[32m恭喜您RabbitMQ安装成功，您可以打开浏览器访问管理页面：http://${IPADDR}:15672\033[0m"
echo -e "\033[32mUser:${MQ_USER} Passwd:$MQ_PWD\033[0m"
}

read -p "
	1) install_Erlang
	
	2) install_RabbitMQ

	请选择以上软件安装:" input

case $input in

	1)
	install_Erlang
	;;
	2)
	install_RabbitMQ
	;;
esac
















































	




