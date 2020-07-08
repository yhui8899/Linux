#!/bin/bash
# single-install redis
# 2020年7月7日16:53:22
# author by xiaofeige
#####################################

if [[ `ps -ef|grep -v grep|grep redis|wc -l` != "0" ]] && [[ `netstat -tnlp|grep -w 6379` != "" ]];then
	echo -e "\033[33mRedis Service already Exist!\033[0m"
	exit 0
elif [[ `netstat -tnlp|grep -w 6379` != "" ]];then
	echo -e "\033[33mRedis Port already Exist!\033[0m"
	exit 0
fi

read -p "Please Enter install redis_version such as:x.x.x": redis_version
r_dir=/usr/local/redis
r_soft=redis-${redis_version}.tar.gz
r_url=http://download.redis.io/releases/${r_soft}

yum  install gcc tcl -y

if [[ ! -f ${r_soft} ]];then
    wget -c ${r_url}
    if [ $? -ne 0 ];then
	echo -e "\033[31m${r_soft} download failed!\033[0m"
	exit
    fi
fi

tar -xf ${r_soft}
cd redis-${redis_version}
make PREFIX=${r_dir} install

if [[ $? -ne 0 ]];then
    echo -e "\033[31mInstall Failed,please Check Software Package!\033[0m"
    exit 1
fi

#修改启动脚本
cp `pwd`/utils/redis_init_script /etc/init.d/redis
sed -i '1a\#chkconfig:2345 80 90' /etc/init.d/redis 
sed -i 's/EXEC=\/usr\/local\/bin\/redis-server/EXEC=\/usr\/local\/redis\/bin\/redis-server/g' /etc/init.d/redis
sed -i 's/CLIEXEC=\/usr\/local\/bin\/redis-cli/CLIEXEC=\/usr\/local\/redis\/bin\/redis-cli/g' /etc/init.d/redis 
sed -i '/^CONF/d' /etc/init.d/redis
sed -i '/pid$/aCONF=\"\/usr\/local\/redis\/conf\/\${REDISPORT}.conf"' /etc/init.d/redis 
sed -i 's/$EXEC $CONF/$EXEC $CONF \&/' /etc/init.d/redis 

#修改redis配置文件
mkdir -p ${r_dir}/conf
cp `pwd`/redis.conf  ${r_dir}/conf/6379.conf
sed -i '/daemonize/s/no/yes/' ${r_dir}/conf/6379.conf
sed -i '/pidfile/s/\/var\/run\/redis.pid/\/var\/run\/redis_6379.pid/' redis.conf 

echo 'export PATH=$PATH:/usr/local/redis/bin'>> /etc/profile
source  /etc/profile

read -p "请设置redis密码，无需设置密码请直接按Enter": input
if [[ $input != '' ]];then
	echo "requirepass ${input}" >>${r_dir}/conf/6379.conf
fi
/etc/init.d/redis start
sleep 5

if [[ `netstat -tnlp|grep -w 6379` != " " ]];then
	echo -e "\033[32mRedis-${redis_version} Install Successful\033[0m"
else
	echo -e "\031[32mRedis-${redis_version} Startup Failed\033[0m"
fi

exit 0
