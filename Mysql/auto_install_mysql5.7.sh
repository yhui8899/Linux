#!/bin/bash
#2018年11月6日10:58:17
#auto_install_mysql5.7.23
#by xiaofeige 2018
#########################
M_DIR=/usr/local/mysql5
M_DATADIR=/data/mysql
M_PORT=3306
M_VER=5.7.25
M_SOFT=mysql-5.7.25.tar.gz
M_URL=https://mirrors.tuna.tsinghua.edu.cn/mysql/downloads/MySQL-5.7
BOOT_DIR=/usr/local/boost
BOOT_URL=http://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/
BOOT_SOFT=boost_1_59_0.tar.gz
M_PACK="gcc-c++ ncurses-devel cmake make perl gcc autoconf automake zlib libxml2 libxml2-devel libgcrypt libtool bison"

if [ -s $M_DIR ];then
	echo -e "\033[31m您已安装过mysql,请卸载后重试！\033[0m"
	exit
fi

yum -y install $M_PACK
if [ ! -f $BOOT_SOFT ];then
	wget -c  ${BOOT_URL}$BOOT_SOFT
fi
tar -xf $BOOT_SOFT

mkdir –p  $BOOT_DIR

mv boost_1_59_0 $BOOT_DIR

if [ ! -f $M_SOFT ];then

	wget -c $M_URL/$M_SOFT
fi

tar -xf $M_SOFT
if [ $? -ne 0 ];then
	echo -e "\033[31m${M_SOFT}解压失败！\033[0m"
	exit
fi
cd mysql-$M_VER

cmake  .  -DCMAKE_INSTALL_PREFIX=$M_DIR/ \
-DMYSQL_UNIX_ADDR=/tmp/mysql.sock \
-DMYSQL_DATADIR=$M_DATADIR/ \
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
-DWITH_DEBUG=0 \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=$BOOT_DIR
if [ $? -ne 0 ];then
	echo -e "\033[31m${M_SOFT}预编译失败！\033[0m"
	exit
fi

make && make install
if [ $? -ne 0 ];then
        echo -e "\033[31m${M_SOFT}编译安装失败！\033[0m"
        exit
fi


groupadd mysql

useradd -g mysql  -r mysql

cd $M_DIR &&  chown mysql:mysql -R .

mkdir -p $M_DATADIR && chown  mysql:mysql -R $M_DATADIR
\cp /etc/my.cnf /etc/my.cnf.bak

cat >/etc/my.cnf<<EOF
[mysqld]
# These are commonly set, remove the # and set as required.
basedir = $M_DIR
datadir = $M_DATADIR
port = 3306
# server_id = .....
socket = /tmp/mysql.sock
skip-grant-tables
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
EOF

$M_DIR/bin/mysqld --initialize --user=mysql --datadir=$M_DATADIR  --basedir=$M_DIR
if [ $? -ne 0 ];then
	echo -e "\033[31m${M_SOFT}初始化失败！\033[0m"
fi

ln -s  $M_DIR/bin/*   /usr/bin/

\cp support-files/mysql.server  /etc/init.d/mysqld

chmod +x /etc/init.d/mysqld

chkconfig  --add mysqld

chkconfig  --level 35 mysqld  on

service  mysqld   restart
if [ $? -eq 0 ];then
	echo -e "\033[32m恭喜您！mysql${M_VER}安装成功！\033[0m"
fi









