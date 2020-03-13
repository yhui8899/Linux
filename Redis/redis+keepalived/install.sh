#!/bin/bash
# Author: xiaofeige 
# QQ: 355638930
# redis and keepalived install script


#修改内核参数
#修改启动脚本(redis_6379)和slave配置文件(redis_slave.conf) 中所涉及的IP

# Source function library.
. /etc/init.d/functions

#set -o nounset
#set -o errexit

readonly redisDir="/usr/local/redis-3.2.12"
readonly redisTarGz="redis-3.2.12.tar.gz"

SHDIR=$(cd `dirname $0`;pwd)

Check_Redis_Pid() {
    REDIS_PID=$(ps -C redis-server --no-heading|wc -l)
    if [[ "${REDIS_PID}" != "0" ]]; then
        echo "Redis Server is runing or redis dir exists"
        exit 1
    fi
}

#add sysctl
Add_Sysctl() {
#    echo "net.core.somaxconn = 10240" >> /etc/sysctl.conf

    VMOM=`grep "vm.overcommit_memory" /etc/sysctl.conf`
    if [[ $? == 1 ]]; then
        echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
    else
        sed -i "s/$VMOM/vm.overcommit_memory = 1/g" /etc/sysctl.conf
    fi
    sysctl -p >/dev/null 2>&1
}

#change ip
Change_RD_IP() {
    IP1=`grep "LOCALIP=" $SHDIR/redis_6379 |awk -F'=' '{print $2}'`
    read -p "Enter LOCAL IP: " LOCALIP
    echo $LOCALIP | perl -ne 'return 1 unless /\b(?:(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5]))\b/' >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        CHECKIP=`ip addr |grep $LOCALIP |awk '{print $2}' |awk -F'/' '{print $1}'`
        if grep -w "$LOCALIP" <<< $CHECKIP >/dev/null 2>&1 ; then
            sed -i "s/LOCALIP=$IP1/LOCALIP=$LOCALIP/g" $SHDIR/redis_6379
        else
            echo "LOCAL IP $LOCALIP inactive"
            exit 1
        fi
    else
        echo "LOCAL IP: $LOCALIP Error"
        exit 1
    fi
	
    IP2=`grep "REMOTEIP=" $SHDIR/redis_6379 |awk -F'=' '{print $2}'`
    IP3=`grep "slaveof" $SHDIR/redis_slave.conf |awk '{print $2}'`
    read -p "Enter REMOTE IP: " REMOTEIP
    echo $REMOTEIP | perl -ne 'return 1 unless /\b(?:(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5]))\b/' >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        sed -i "s/REMOTEIP=$IP2/REMOTEIP=$REMOTEIP/g" $SHDIR/redis_6379
        sed -i "s/slaveof $IP3/slaveof $REMOTEIP/g" $SHDIR/redis_slave.conf
    else
        echo "REMOTE IP: $REMOTEIP Error"
        exit 1
    fi
}

#install redis 
Install_Redis() { 
    yum install -y gcc >/dev/null 2>&1
    mkdir -p ${redisDir} && cd ${redisDir}
    wget http://download.redis.io/releases/${redisTarGz} && tar zxf ${redisTarGz} --strip-component=1
    echo "Install Reids, Pls Wait..."
    make >/dev/null 2>&1 && make install >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        echo "OK: redis is installed, exit."
        mkdir -p /etc/redis/data
        \cp -pa $SHDIR/redis_master.conf /etc/redis/
        \cp -pa $SHDIR/redis_slave.conf /etc/redis/
        \cp -pa $SHDIR/redis_6379 /etc/init.d/
        chmod +x /etc/init.d/redis_6379
    else
        echo "ERROR: redis is NOT installed, exit."
    fi
}

# install keepalived
Setting_VIP() {
    echo "Install Keepalived, Pls Wait..."
    yum install -y keepalived >/dev/null 2>&1
    systemctl enable keepalived.service
    \cp -pa $SHDIR/keepalived.tpl $SHDIR/keepalived.conf

    sed -i "s/CHANGE_LOCAL_IP/$LOCALIP/g" $SHDIR/keepalived.conf
    sed -i "s/CHANGE_REMOTE_IP/$REMOTEIP/g" $SHDIR/keepalived.conf

    read -p "Enter Keepalived VIP: " VIPIP
    echo $VIPIP | perl -ne 'return 1 unless /\b(?:(?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5]))\b/' >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        sed -i "s/CHANGE_VIP_IP/$VIPIP/g" $SHDIR/keepalived.conf
    else
        echo "Keepalived VIP: $VIP Error"
        exit 1
    fi

    #setting state,interface,priority
    read -p "Enter MASTER OR BACKUP: " KROLE
    if [[ "$KROLE" = "MASTER" || "$KROLE" = "BACKUP" ]]; then
        sed -i "s/CHANGE_ROLE/$KROLE/g" $SHDIR/keepalived.conf
    else
        echo "Enter MASTER OR BACKUP Error"
        exit 1
    fi
	
    LNETID=`ip addr |grep "BROADCAST" |awk '{print $2}'`
    read -p "Select Interface Name ${LNETID%?} : " KNETID
    if grep -w "$KNETID" <<< $LNETID >/dev/null 2>&1 ; then
        sed -i "s/CHANGE_NETID/$KNETID/g" $SHDIR/keepalived.conf
    else
        echo "Enter Interface Name Error"
        exit 1
    fi

    read -p "Enter MASTER Priority or BACKUP Priority: " KPRIOID
    if echo $KPRIOID | grep -q '[^0-9]' ; then
        echo "this is not a num,please input num"
        exit 1
    else
        sed -i "s/PRIO_ID/$KPRIOID/g" $SHDIR/keepalived.conf
    fi
	
    #auto setttig RID, VRID
    #RID=`grep -w "router_id" $SHDIR/keepalived.conf |awk '{print $2}'`
    #VRID=`grep -w "virtual_router_id" $SHDIR/keepalived.conf |awk '{print $2}'`
    RID_Number=`echo $LOCALIP |awk -F'.' '{print $4}'`
    VIP_Number=`echo $VIPIP |awk -F'.' '{print $4}'`
    sed -i "s/RID_NUMBER/RID_${RID_Number}/g" $SHDIR/keepalived.conf
    sed -i "s/CHANGE_VRID/${VIP_Number}/g" $SHDIR/keepalived.conf
	
    \cp -pa $SHDIR/keepalived.conf /etc/keepalived/keepalived.conf

    #setting keepalived log file
    sed -i 's/KEEPALIVED_OPTIONS="-D"/KEEPALIVED_OPTIONS="-D -d -S 0"/g' /etc/sysconfig/keepalived
	
    KLOGS=`grep "keepalived.log" /etc/rsyslog.conf`
    if [[ $? == 1 ]]; then
        echo "local0.*           /var/log/keepalived.log" >> /etc/rsyslog.conf
    else
        echo "keepalived logs file already exists"
    fi
    systemctl restart rsyslog.service
    action "keepalived is installed, exit." /bin/true
}

#chk_redis.sh
Setting_Redis_Script() {
    CIP1=`grep "LOCALIP=" $SHDIR/check_redis.sh |awk -F'=' '{print $2}'`
    CIP2=`grep "REMOTEIP=" $SHDIR/check_redis.sh |awk -F'=' '{print $2}'`
    CVIP=`grep "VIPIP=" $SHDIR/check_redis.sh |awk -F'=' '{print $2}'`
    sed -i "s/LOCALIP=$CIP1/LOCALIP=$LOCALIP/g" $SHDIR/check_redis.sh
    sed -i "s/REMOTEIP=$CIP2/REMOTEIP=$REMOTEIP/g" $SHDIR/check_redis.sh
    sed -i "s/VIPIP=$CVIP/VIPIP=$VIPIP/g" $SHDIR/check_redis.sh
    \cp -pa $SHDIR/check_redis.sh /etc/keepalived/check_redis.sh
    chmod +x /etc/keepalived/check_redis.sh
}

Check_Redis_Pid
Add_Sysctl
Change_RD_IP
Install_Redis
Setting_VIP
Setting_Redis_Script
