#!/bin/bash
#author	xiaofeige QQ:355638930
#2019年8月27日19:59:34

O_SOFT_DIR=/opt
O_SOFT1="linux.x64_11gR2_database_1of2.zip"
O_SOFT2="linux.x64_11gR2_database_2of2.zip"
YUM_PACK1="gcc gcc-c++ make binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel elfutils-libelf-devel-static glibc glibc-common"
YUM_PACK2="glibc-devel ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel numactl-devel sysstat unixODBC unixODBC-devel" 
YUM_PACK3="kernel-headers pcre-devel readline rlwrap unzip"
ORACLE_BASE=/data/u01/app/oracle
O_PWD=123456
HOSTNAME=`hostname`
DBHOME=`find / -type d -name "dbhome_*"`
if [[ -s $DBHOME ]];then
	echo -e "\033[33m您已安装过Oracle数据库，请卸载后重试！\033[0m"
	exit 0
fi

ping -c2 baidu.com
if [[ $? -ne 0 ]];then
	echo nameserver 8.8.8.8 >>/etc/resolv.conf
	ping -c2 baidu.com >>/dev/null 2>&1
fi

ls /etc/yum.repos.d/epel* >>/dev/null 2>&1
if [[ $? -ne 0 ]];then
	yum install epel-release -y
	yum clean all
	yum makecache -y
fi

yum install -y ${YUM_PACK1} ${YUM_PACK2} ${YUM_PACK3}

cd $O_SOFT_DIR

if [[ ! -f ${O_SOFT_DIR}/${O_SOFT1} ]];then
        echo -e "\033[33m请将${O_SOFT1}安装包上传至${O_SOFT_DIR}目录下!\033[0m"
        exit 1
elif    [[ ! -f ${O_SOFT_DIR}/${O_SOFT2} ]];then
        echo -e "\033[33m请将${O_SOFT2}安装包上传至${O_SOFT_DIR}目录下!\033[0m"
        exit 1
fi

unzip $O_SOFT1 
unzip $O_SOFT2
if [[ $? -ne 0 ]];then
	echo -e "\033[31m${O_SOFT1} ${O_SOFT2} 文件解压失败！\033[0m"
	exit
fi


groupadd oinstall&&groupadd dba&&useradd -g oinstall -G dba oracle
echo ${O_PWD} | passwd --stdin oracle
if [[ $? -ne 0 ]];then
	echo -e "\033[31mOracle账户密码设置错误！ \033[0m"
fi

mkdir -p ${ORACLE_BASE}/product/11.2.0/dbhome_1
mkdir ${ORACLE_BASE}/{oradata,inventory,fast_recovery_area}
chown -R oracle:oinstall ${ORACLE_BASE}
chmod -R 775 ${ORACLE_BASE}

\cp /etc/sysctl.conf /etc/sysctl.conf.bak

cat >>/etc/sysctl.conf<< EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 1073741824
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF
sleep 2
sysctl -p

\cp /etc/security/limits.conf /etc/security/limits.conf.bak

cat >>/etc/security/limits.conf<<EOF
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
EOF

\cp /etc/pam.d/login /etc/pam.d/login.bak
sed -i '/rule$/asession required /lib64/security/pam_limits.so' /etc/pam.d/login
sed -i '/pam_limits.so$/asession required pam_limits.so' /etc/pam.d/login

cat >>/etc/profile<<EOF
if [ \$USER = "oracle" ]; then
if [ \$SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi
fi
EOF
sleep 2
source /etc/profile 

cat >>/home/oracle/.bash_profile<<EOF
export ORACLE_BASE=${ORACLE_BASE}
export ORACLE_HOME=${ORACLE_BASE}/product/11.2.0/dbhome_1
export ORACLE_SID=orcl
export ORACLE_UNQNAME=\$ORACLE_SID
export PATH=\$ORACLE_HOME/bin:\$PATH
export NLS_LANG=american_america.AL32UTF8
alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'
EOF

read -p "系统配置完成，请按Enter键继续..." input

su - oracle -c "source /home/oracle/.bash_profile" 
su - oracle -c "cp -r /opt/database/response/ /home/oracle"
sleep 10
su - oracle -c "sed -i 's/oracle.install.option\=/oracle.install.option\=INSTALL_DB_SWONLY/g' /home/oracle/response/db_install.rsp"
su - oracle -c "sed -i 's/ORACLE_HOSTNAME\=/ORACLE_HOSTNAME\=${HOSTNAME}/g' /home/oracle/response/db_install.rsp" 
su - oracle -c "sed -i 's/UNIX_GROUP_NAME\=/UNIX_GROUP_NAME\=oinstall/g' /home/oracle/response/db_install.rsp" 
su - oracle -c "sed -i 's/INVENTORY_LOCATION\=/INVENTORY_LOCATION\=\/data\/u01\/app\/oracle\/inventory/g' /home/oracle/response/db_install.rsp" 
su - oracle -c "sed -i 's/SELECTED_LANGUAGES\=/SELECTED_LANGUAGES\=en,zh_CN/g' /home/oracle/response/db_install.rsp" 
su - oracle -c "sed -i 's/ORACLE_HOME\=/ORACLE_HOME\=\/data\/u01\/app\/oracle\/product\/11.2.0\/dbhome_1/g' /home/oracle/response/db_install.rsp"
su - oracle -c "sed -i 's/ORACLE_BASE\=/ORACLE_BASE\=\/data\/u01\/app\/oracle/g' /home/oracle/response/db_install.rsp" 
su - oracle -c "sed -i 's/oracle.install.db.InstallEdition\=/oracle.install.db.InstallEdition\=EE/g' /home/oracle/response/db_install.rsp"
su - oracle -c "sed -i 's/oracle.install.db.DBA_GROUP\=/oracle.install.db.DBA_GROUP\=dba/g' /home/oracle/response/db_install.rsp"
su - oracle -c "sed -i 's/oracle.install.db.OPER_GROUP\=/oracle.install.db.OPER_GROUP\=dba/g' /home/oracle/response/db_install.rsp"
su - oracle -c "sed -i 's/DECLINE_SECURITY_UPDATES\=/DECLINE_SECURITY_UPDATES\=true/g' /home/oracle/response/db_install.rsp"
su - oracle -c "cd ${O_SOFT_DIR}/database && ./runInstaller -silent -responseFile /home/oracle/response/db_install.rsp -ignorePrereq "

if [[ $? -eq 0 ]];then
	read -p "安装完末尾看到Successfully Setup Software字样，按Enter键继续..." input	
	${ORACLE_BASE}/inventory/orainstRoot.sh
	${ORACLE_BASE}/product/11.2.0/dbhome_1/root.sh
else
	echo -e "\033[31moracle安装失败！\033[0m"
	exit 1
fi

#创建实例
su - oracle -c "sed -i 's/GDBNAME = \"orcl11g.us.oracle.com\"/GDBNAME = \"orcl\"/g' /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/SID = \"orcl11g\"/SID = \"orcl\"/g' /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#SYSPASSWORD = \"password\"/SYSPASSWORD = \"password\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#SYSTEMPASSWORD = \"password\"/SYSTEMPASSWORD = \"password\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#SYSMANPASSWORD = \"password\"/SYSMANPASSWORD = \"password\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#DBSNMPPASSWORD = \"password\"/DBSNMPPASSWORD = \"password\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#DATAFILEDESTINATION =/DATAFILEDESTINATION =\"\/data\/u01\/app\/oracle\/oradata\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#RECOVERYAREADESTINATION\=/RECOVERYAREADESTINATION\=\"\/data\/u01\/app\/oracle\/fast_recovery_area\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "sed -i 's/#CHARACTERSET = \"US7ASCII\"/CHARACTERSET = \"AL32UTF8\"/g'  /home/oracle/response/dbca.rsp"
su - oracle -c "dbca -silent -responseFile /home/oracle/response/dbca.rsp"
if [[ $? -eq 0 ]];then
	echo -e "\033[32morcl实例创建完毕\033[0m"
	su - oracle -c "lsnrctl start"
else 
	echo -e "\033[31morcl实例创建失败！\033[0m"
	exit 1
fi
sleep 5
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/g' /etc/selinux/config
sleep 2
netstat -tnlp|grep 1521
ps -ef|grep oracle

echo -e "\033[32m
	 恭喜您，Oracle数据库安装成功！
	 实例名是：orcl
	 oracle账户密码是：${O_PWD}
	 请切换至Oracle用户登录Oracle数据库：sqlplus / as sysdba \033[0m"
































