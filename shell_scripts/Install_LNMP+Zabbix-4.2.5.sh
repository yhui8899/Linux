#!/bin/bash
#auto_install_LNMP+zabbix
#2018年12月5日16:34:52
#by xiaofeige

#Nginx
N_VER="1.12.2"
N_SOFT="nginx-1.12.2.tar.gz"
N_DIR="/usr/local/nginx"
N_URL="http://nginx.org/download"
N_ARGS="--with-http_stub_status_module --with-http_ssl_module"
N_PACK="gcc gcc-c++ pcre pcre-devel openssl openssl-devel wget"
#-----------------------------------------------------------------------------------------------------------------
#Mysql
M_DIR=/usr/local/mysql56
M_SOFT=mysql-5.6.44.tar.gz
M_VER=5.6.44
M_URL=http://mirrors.ustc.edu.cn/mysql-ftp/Downloads/MySQL-5.6/
M_PACK="gcc gcc-c++ pcre pcre-devel libxml2 libxml2-devel wget bzip2 bzip2-devel zlib zlib-devel tar gzip "
M_NAME=root
M_PSW=qazQAZ
#----------------------------------------------------------------------------------------------------------------
#PHP
P_DIR=/usr/local/php
P_VER=7.0.32
P_SOFT=php-7.0.32.tar.gz
P_URL="http://cn.php.net/distributions"
P_PACK1="openssl openssl-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel"
P_PACK2="pcre pcre-devel libxslt libxslt-devel bzip2 bzip2-devel libxml2 libxml2-devel  libevent-devel"
P_ARGS1="--with-freetype-dir --with-gd --with-gettext --with-iconv-dir --with-kerberos"
P_ARGS2="--with-libdir=lib64 --with-libxml-dir --with-mysqli --with-openssl --with-pcre-regex"
P_ARGS3="--with-pdo-mysql --with-pdo-sqlite --with-pear --with-png-dir --with-jpeg-dir --with-xmlrpc --with-xsl"
P_ARGS4="--with-zlib --with-bz2 --with-mhash --enable-fpm --enable-bcmath --enable-libxml --enable-inline-optimization"
P_ARGS5="--enable-gd-native-ttf --enable-mbregex --enable-mbstring --enable-opcache --enable-pcntl"
P_ARGS6="--enable-shmop --enable-soap --enable-sockets --enable-sysvsem --enable-sysvshm --enable-xml --enable-zip"
#----------------------------------------------------------------------------------------------------------------
#Zabbix
ZBD_USER=zabbix
ZDB_PSW=123456
DB_USER=$M_NAME
DB_PSW=$M_PSW
Z_VER=4.2.5
Z_SOFT=zabbix-4.2.5.tar.gz
Z_URL=https://nchc.dl.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/4.2.5/$Z_SOFT
Z_ARGS="--enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl"
Z_DIR="/usr/local/zabbix"
Z_SERVER=$Z_DIR/sbin/zabbix_server
#----------------------------------------------------------------------------------------------------------------

function install_nginx(){
if [[ -s $N_DIR ]];then
	echo -e "\033[33m您已安装过nginx，请卸载后重试！\033[0m"
	exit
fi

yum -y install $N_PACK

if [[ ! -f $N_SOFT ]];then

	wget -c $N_URL/$N_SOFT
fi
tar -xf $N_SOFT
if [[ $? -ne 0 ]];then
	echo -e "\033[31m${N_SOFT}解压失败！\033[0m"
fi
cd nginx-$N_VER

./configure --prefix=$N_DIR $N_ARGS
if [[ $? -ne 0 ]];then
	 echo -e "\033[31m${N_SOFT}预编译失败！\033[0m"
fi
make && make install
if [[ $? -ne 0 ]];then
         echo -e "\033[31m${N_SOFT}安装失败！\033[0m"
fi

$N_DIR/sbin/nginx -t
if [[ $? -ne 0 ]];then
         echo -e "\033[31 nginx测试失败，请检查配置文件是否正确！\033[0m"
	 exit
fi
	echo -e "\033[32m恭喜您！nginx_${N_VER}安装成功,正在为您配置nginx\033[0m"
sleep 3s

#Config_Virtual_host
cp $N_DIR/conf/nginx.conf $N_DIR/conf/nginx.conf.bak

grep -Ev "^$|#" $N_DIR/conf/nginx.conf |sed '/server/,$d' >$N_DIR/conf/nginx.swp

mv $N_DIR/conf/nginx.swp $N_DIR/conf/nginx.conf

if [[ ! -d $N_DIR/conf/vhost ]];then
	mkdir -p $N_DIR/conf/vhost
fi
NUM=`grep "include   vhost/*" $N_DIR/conf/nginx.conf |wc -l`

if [[ $NUM -eq 0 ]];then
	echo -e "include   vhost/*; \n}" >>$N_DIR/conf/nginx.conf
fi
cat $N_DIR/conf/vhost/localhost>>/dev/null 2>&1 
if [[ $? -ne 0 ]];then	
cat>$N_DIR/conf/vhost/localhost<<EOF
server {
        listen       80;
        server_name  localhost;

        location / {
            root   html/;
            index   index.php index.html index.htm;
        }

        location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
EOF
fi
$N_DIR/sbin/nginx 
if [[ $? -eq 0 ]];then
	echo -e "\033[32mnginx配置完成！\033[0m"
fi
systemctl stop firewalld

setenforce 0

sleep 3s
}


####install_MYSQL
function install_mysql(){

if [[ -s $M_DIR ]];then
	echo -e "\033[032m您已安装过MYSQL，正在为您启动服务！\033[0m"
	service mysqld restart
	netstat -tnlp|grep 3306
	if [[ $? -eq 0 ]];then
		echo -e "\033[032m已成功为您启动MYSQL服务！\033[0m"
	else
		echo -e "\033[031mMYSQL服务启动失败，请检查安装和配置是否正确！\033[0m"
		
	fi
	exit
fi

yum -y install ${M_PACK} cmake  ncurses-devel ncurses autoconf

if [[ ! -f $M_SOFT ]];then
wget -c $M_URL/$M_SOFT
fi
tar -xf $M_SOFT
if [[ $? -ne 0 ]];then
	echo -e "\033[031mMYSQL${M_VER}解压失败！\033[0m"
	exit
fi

cd mysql-$M_VER

cmake  .  -DCMAKE_INSTALL_PREFIX=$M_DIR/ \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DMYSQL_DATADIR=/data/mysql \
-DSYSCONFDIR=/etc \
-DMYSQL_USER=mysql \
-DMYSQL_TCP_PORT=3306 \
-DWITH_XTRADB_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_EXTRA_CHARSETS=1 \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DEXTRA_CHARSETS=all \
-DWITH_BIG_TABLES=1 \
-DWITH_DEBUG=0

if [[ $? -ne 0 ]];then
	echo -e "\033[031mMYSQL${M_VER}预编译失败！\033[0m"
	exit
fi

make&&make install

if [[ $? -ne 0 ]];then
	echo -e "\033[031mMYSQL${M_VER}安装失败！\033[0m"
	exit
fi

cd /$M_DIR
\cp support-files/my-default.cnf /etc/my.cnf
\cp support-files/mysql.server /etc/init.d/mysqld 

chkconfig --add mysqld 
chkcomfig --level 35 mysqld on
mkdir -p  /data/mysql
grep -E '^mysql' /etc/passwd
if [[ $? -eq 0 ]];then
	echo -e "\033[032mMYSQL用户已存在，无需创建！\033[0m"
fi
useradd  mysql

$M_DIR/scripts/mysql_install_db --user=mysql --datadir=/data/mysql/ --basedir=$M_DIR/
if [[ ! $? -eq 0 ]];then
	echo -e "\033[031mMYSQL${M_VER}初始化失败！\033[0m"
	exit
fi

ln  -s  $M_DIR/bin/* /usr/bin/

service  mysqld  restart

ps -ef|grep mysqld

mysqladmin -u$M_NAME password $M_PSW

netstat -tnlp|grep 3306
if [[ $? -eq 0 ]];then

	echo -e "\033[032m恭喜！MYSQL${M_VER}安装成功！Mysql中root用户的初始密码是:$M_PSW\033[0m"
fi

}

#####install_php
function install_php(){

if [[ -s $P_DIR ]];then
	echo -e "\033[33m您已经安装过PHP软件，请卸载后重试！\033[0m"
	exit
fi

yum -y install $P_PACK1 $P_PACK2

if [[ ! -f $P_SOFT ]];then
	wget -c $P_URL/$P_SOFT
fi

tar -xf $P_SOFT
if [[ $? -ne 0 ]];then
	echo -e "\033[31m${P_SOFT}解压失败！\033[0m"
	exit
fi

cd php-$P_VER

./configure --prefix=$P_DIR $P_ARGS1 $P_ARGS2 $P_ARGS3 $P_ARGS4 $P_ARGS5 $P_ARGS6
if [[ $? -ne 0 ]];then
	echo -e "\033[31mnginx-${P_VER}预编译失败！\033[0m"
	exit 1
fi

make && make install
if [[ $? -ne 0 ]];then
        echo -e "\033[31mnginx-${P_VER}安装失败！\033[0m"
        exit 1
fi

#cp_file
#拷贝配置文件至安装目录的lib目录下命名为：php.ini;
cp php.ini-production $P_DIR/lib/php.ini

#拷贝进程管理器配置文件至安装目录的etc目录下命名为：php-fpm.conf;
cp $P_DIR/etc/php-fpm.conf.default $P_DIR/etc/php-fpm.conf

#拷贝php-fpm启动文件至安装目录的bin目录下;
\cp sapi/fpm/php-fpm  $P_DIR/sbin/

#开启的危害，将php.ini配置文件中的：cgi.fix_pathinfo=0 把1改为0;
echo -e "cgi.fix_pathinfo=0">>$P_DIR/lib/php.ini

#复制配置文件;
cp $P_DIR/etc/php-fpm.d/www.conf.default  $P_DIR/etc/php-fpm.d/www.conf

cat>/usr/local/nginx/html/info.php<<EOF
<?php
phpinfo();
?>
EOF
IP=`ifconfig|grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}"|grep -Ev "^255|255$"|grep -v "127.0.0.1"`
$P_DIR/sbin/php-fpm
netstat -tnlp |grep 9000 >>/dev/null 2>&1

if [[ $? -eq 0 ]];then
	echo -e "\033[32m恭喜您！PHP安装成功！请在浏览器打开:http://$IP/info.php访问PHP安装信息;\033[0m"
else
	echo -e "\033[31mPHP启动失败，请检查配置文件是否正确！\033[0m"
fi
}

#auto_install_zabbox_server
function install_zabbix_server(){

if [[ -f $Z_SERVER ]];then
        echo -e "\033[33m您已安装过zabbix_server,请卸载后重试！\033[0m"
        exit 0
fi

if [[ ! -f $Z_SOFT ]];then
        wget -c $Z_URL
fi

tar -xf $Z_SOFT
if [[ $? -ne 0 ]];then
        echo -e "\033[31mzabbix-${Z_VER}解压失败，请检查文件是否存在！\033[0m"
        exit 1
fi

cd zabbix-$Z_VER

yum -y  install  curl  curl-devel  net-snmp net-snmp-devel  perl-DBI  mariadb-devel mysql-devel wget* tar*

grep "zabbix" /etc/group 

if [[ $? -ne 0 ]];then
        groupadd  zabbix
        useradd  -g  zabbix  zabbix
        usermod  -s  /sbin/nologin  zabbix
fi

#创建zabbix数据库;
mysql -u$DB_USER -p$DB_PSW -e "use zabbix;" >>/dev/null 2>&1

if [[ $? -ne 0 ]];then
        mysql -u$DB_USER -p$DB_PSW -e "create database zabbix charset=utf8;"
fi

#给zabbix数据库授权给zabbix用户;
mysql -u$DB_USER -p$DB_PSW -e "grant all on zabbix.* to zabbix@'%' identified by '123456'"
mysql -u$DB_USER -p$DB_PSW -e "grant all on zabbix.* to zabbix@'localhost' identified by '123456'"
if [[ $? -ne 0 ]];then
         echo -e "\033[31m数据库授权失败！\033[0m"
         exit 1
fi
#导入zabbix数据到数据库;
mysql -u$ZBD_USER -p$ZDB_PSW zabbix < database/mysql/schema.sql
if [[ $? -ne 0 ]];then
        echo -e "\033[31mschema数据库导入失败，请检查数据库用户名是否正确！\033[0m"
        exit 1
fi

mysql -u$ZBD_USER -p$ZDB_PSW zabbix < database/mysql/images.sql
if [[ $? -ne 0 ]];then
        echo -e "\033[31mimages数据库导入失败，请检查数据库用户名是否正确！\033[0m"
        exit 1
fi

mysql -u$ZBD_USER -p$ZDB_PSW zabbix < database/mysql/data.sql
if [[ $? -ne 0 ]];then
        echo -e "\033[31mdata数据库导入失败，请检查数据文件是否存在以及用户名是否正确！\033[0m"
        exit 1
fi

#预编译zabbix-server;
./configure --prefix=${Z_DIR} ${Z_ARGS}
if [[ $? -ne 0 ]];then
        echo -e "\033[31mzabbix-${Z_VER}预编译失败！\033[0m"
        exit 1
fi

make && make install
if [[ $? -ne 0 ]];then
        echo -e "\033[31mzabbix-${Z_VER}编译安装失败！\033[0m"
        exit 1
fi

ln -s $Z_DIR/sbin/zabbix_*  /usr/local/sbin/


#Zabbix server安装完毕,
cd ${Z_DIR}/etc/
cp  zabbix_server.conf  zabbix_server.conf.bak
#------修改zabbix_server配置文件如下：--------------------------
#LogFile=/tmp/zabbix_server.log 默认无需更改

#DBHost=localhost 将默认localhost改成：127.0.0.1
sed -i 's/# DBHost=localhost/DBHost=127.0.0.1/g' $Z_DIR/etc/zabbix_server.conf
#DBName=zabbix  默认为zabbix 无需更改
#DBUser=zabbix  默认为zabbix 无需更改

#DBPassword=    更改密码为:123456
sed -i 's/# DBPassword=/DBPassword=123456/g' $Z_DIR/etc/zabbix_server.conf
#--------------------------------------------------------------

#同时cp zabbix_server启动脚本至/etc/init.d/目录，启动zabbix_server, Zabbix_server默认监听端口为10051。
cd -
#cd  zabbix-$Z_VER
cp  misc/init.d/tru64/zabbix_server  /etc/init.d/zabbix_server
chmod o+x /etc/init.d/zabbix_server

#安装zabbix-WEB端
cp -a  frontends/php/* $N_DIR/html/
chmod 757 $N_DIR/html/conf

#修改php.ini配置文件
#修改时区;
sed -i '/date.timezone/i date.timezone = PRC' /usr/local/php/lib/php.ini 
sed -i 's/post_max_size = 8M/post_max_size = 16M/'  /usr/local/php/lib/php.ini
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /usr/local/php/lib/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/' /usr/local/php/lib/php.ini

pkill php-fpm

$P_DIR/sbin/php-fpm

#重启zabbix

/etc/init.d/zabbix_server  restart

sleep 10s

netstat -tnlp|grep 10051
if [[ $? -eq 0 ]];then
        echo -e "\033[32mzabbix-${Z_VER}服务端安装成功,zabbix数据库密码是:${ZDB_PSW} 请登录WEB端进行安装配置！\033[0m"

fi

}

#auto_install_zabbix_agent

function install_zabbix_agent(){
yum install gcc gcc-c++ pcre pcre-devel wget tar  -y
sleep 3s
if [[ ! -f $Z_SOFT ]];then
        wget -c $Z_URL
fi

grep "zabbix" /etc/group 

if [[ $? -ne 0 ]];then
        groupadd  zabbix
        useradd  -g  zabbix  zabbix
        usermod  -s  /sbin/nologin  zabbix
fi

tar -xf $Z_SOFT
if [[ $? -ne 0 ]];then
        echo -e "\033[31mzabbix-${Z_VER}解压失败，请检查文件是否存在！\033[0m"
        exit 1
fi

cd zabbix-$Z_VER

./configure  --prefix=${Z_DIR}  --enable-agent
if [[ $? -ne 0 ]];then
        echo -e "\033[31mzabbix-Agent-预编译失败！\033[0m"
        exit 1
fi

make && make install
if [[ $? -ne 0 ]];then
        echo -e "\033[31mzabbix-Agent编译安装失败！\033[0m"
        exit 1
fi

sed -i 's/Hostname=Zabbix server/Hostname=127.0.0.1/' $Z_DIR/etc/zabbix_agentd.conf

ln  -s  $Z_DIR/sbin/zabbix_*  /usr/local/sbin/

#拷贝zabbix_Agent启动文件
cp misc/init.d/tru64/zabbix_agentd /etc/init.d/zabbix_agentd

chmod o+x /etc/init.d/zabbix_agentd

/etc/init.d/zabbix_agentd  start

ps -ef|grep zabbix_agent

echo -e "\033[33m请手工修改Agent端配置文件：/usr/local/zabbix/etc/zabbix_agentd.conf

LogFile=/tmp/zabbix_agentd.log   (默认无需修改)

Server=127.0.0.1                （zabbix_server端IP地址）       

ServerActive=127.0.0.1          （zabbix_server端IP地址）

Hostname = 127.0.0.1            （Agent端IP地址）
其他保持默认即可！\033[0m"

}

read  -p "
1) Install_Nginx

2) Install_Mysql

3) Install_PHP

4) install_zabbix_server

5) install_zabbix_agent

6)	install_all
请选择您要安装的程序:" input

case $input in
	
	1)
	install_nginx
	;;
	2)
	install_mysql
	;;
	3)
	install_php
	;;
	4)
	install_zabbix_server
	;;
	5)install_zabbix_agent
	;;
	6)
	install_nginx
	install_mysql
	install_php
	install_zabbix_server
	install_zabbix_agent
	;;
esac

