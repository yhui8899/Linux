#!/bin/bash
#2019年11月5日09:02:23
#author by xiaofeige
##################################
# 1）关闭selinux和防火墙	 	 #	
# 2）优化sysctl.conf内核参数     #
# 3）优化limit.conf参数	         #
# 4）安装常用的工具软件包	 	 #
##################################
YUM_PACK="epel-release net-tools vim lrzsz wget git unzip gcc make openssl-devel gcc-c++ ntpdate bash-completion telnet"
SYSCTL_DIR=/etc/
LIMIT_DIR=/etc/security/

yum install $YUM_PACK -y

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭selinux
check_selinux=`sestatus|grep disabled|wc -l`
if [[ $check_selinux == 0 ]];then
	sed -i '/^SELINUX/s/enforcing/disabled/g' /etc/selinux/config
	setenforce 0
fi

#配置sysctl.conf 内核参数
if [[ ! -f ${SYSCTL_DIR}sysctl.conf ]];then
	echo -e "\033[31msysctl.conf Files Not Exist\033[0m"
	exit 1
fi

\cp ${SYSCTL_DIR}sysctl.conf ${SYSCTL_DIR}sysctl.conf.bak
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

cat >${SYSCTL_DIR}sysctl.conf <<EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 10000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.ip_local_port_range = 1024 65535
EOF

sleep 2
sysctl -p >>/dev/null 2>&1

if [[ ! -f ${LIMIT_DIR}limits.conf ]];then
	echo -e "\033[31mlimits.conf Files Not Exist\033[0m"
	exit 1 
fi

\cp ${LIMIT_DIR}limits.conf ${LIMIT_DIR}limits.conf.bak

check_limit=`grep "soft" ${LIMIT_DIR}limits.conf |grep -Ev "^#"|wc -l`
if [[ ${check_limit} == 0 ]];then
	echo '*     soft       noproc                 65536' >>${LIMIT_DIR}limits.conf
	echo '*     hard       noproc                 65536' >>${LIMIT_DIR}limits.conf
	echo '*     soft       nofile                 65536' >>${LIMIT_DIR}limits.conf
	echo '*     hard       nofile                 65536' >>${LIMIT_DIR}limits.conf
	echo -e "\033[32mulimit change Successfully\033[0m"
else
	echo -e "\033[33mulimit don't change\033[0m"
fi
sleep 2
echo -e "\033[32msystem initialization end\033[0m"




















