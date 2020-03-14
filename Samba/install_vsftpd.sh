#!/bin/bash
#2018年10月19日09:20:59
#auto_install_vsftpd
#by xiaofeige 2018
#######################
FTP_DIR="/etc/vsftpd"
FTP_YUM="yum install -y"
FTP_USR="ftpuser"
FTP_DB="vsftpd_login"
FTP_VIR=$*
FTP_VIR_CONF="vsftpd_user_conf"
FTP_LIST="/data/sh/list.txt"
rpm -qa|grep vsftpd >>/dev/null

if [ $? -ne 0 ];then
$FTP_YUM vsftpd*
else
	systemctl restart vsftpd
fi
 

#安装配置虚拟用户

$FTP_YUM   pam*  libdb-utils  libdb*  --skip-broken >>/dev/null

mkdir  -p ${FTP_DIR}/${FTP_VIR_CONF}/

touch ${FTP_DIR}/${FTP_USR}s.txt

if [ $FTP_VIR == "list" ];then
	if [ ! -f $FTP_LIST ];then
		echo -e "\033[033m${FTP_LIST}文件不存在!\033[0m"
		exit
	fi

	if [ ! -s $FTP_LIST ];then
		echo -e "\033[033m${FTP_LIST}文件为空!\033[0m"
		exit
	fi

	
for U in `cat $FTP_LIST`

do
cat $FTP_DIR/$FTP_VIR_CONF/$U >>/dev/null
if [ ! $? -eq "0" ];then

cat>>${FTP_DIR}/${FTP_USR}s.txt<<EOF
$U
${U}_pwd123
EOF
mkdir -p /home/${FTP_USR}/$U
cat >${FTP_DIR}/${FTP_VIR_CONF}/$U<<EOF
local_root=/home/${FTP_USR}/$U
write_enable=YES
anon_world_readable_only=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF
mkdir -p /home/${FTP_USR}/$U

else
	echo -e "\033[033m${U}用户已存在!\033[0m"
	sleep 2
fi

done



#==================================================================

else


for i in $FTP_VIR
do
cat ${FTP_DIR}/${FTP_USR}s.txt |grep $i >>/dev/null

if [ $? -ne 0 ];then
cat>>${FTP_DIR}/${FTP_USR}s.txt<<EOF
$i
${i}_pwd123
EOF

cat >${FTP_DIR}/${FTP_VIR_CONF}/$i<<EOF
local_root=/home/${FTP_USR}/$i
write_enable=YES
anon_world_readable_only=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF

else 
	echo -e "\033[032m${i}用户已存在！\033[0m"
	exit
fi

mkdir -p /home/${FTP_USR}/$i
done

fi



db_load  -T  -t  hash  -f  ${FTP_DIR}/${FTP_USR}s.txt  ${FTP_DIR}/${FTP_DB}.db

	chmod 755 ${FTP_DIR}/${FTP_DB}.db

cat >/etc/pam.d/vsftpd<<EOF
auth      required        pam_userdb.so   db=${FTP_DIR}/${FTP_DB}
account   required        pam_userdb.so   db=${FTP_DIR}/${FTP_DB}
EOF


cat /etc/passwd |grep ${FTP_USR} >>/dev/null
if [ $? -ne 0 ];then
useradd    -s   /sbin/nologin    ${FTP_USR}
fi

cp ${FTP_DIR}/vsftpd.conf ${FTP_DIR}/vsftpd.conf.bak

cat ${FTP_DIR}/vsftpd.conf |grep "guest_" >>/dev/null

if [ $? -ne 0 ];then
cat >${FTP_DIR}/vsftpd.conf<<EOF
#global config Vsftpd 2018
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=NO
listen_ipv6=YES
userlist_enable=YES
tcp_wrappers=YES
#config virtual user FTP
pam_service_name=vsftpd
guest_enable=YES
guest_username=${FTP_USR}
user_config_dir=${FTP_DIR}/${FTP_VIR_CONF}
virtual_use_local_privs=YES
EOF
fi

chown -R ${FTP_USR}:${FTP_USR} /home/${FTP_USR}

setenforce 0
systemctl stop firewalld.service

netstat -tnlp |grep 21
if [ $? -ne 0 ];then
	systemctl start vsftpd
else
	systemctl restart vsftpd
fi

ps -ef|grep vsftpd
netstat -tnlp |grep 21
if [ $? -eq 0 ];then
	echo -e "\033[032m恭喜！vsftp安装成功！\033[0m"
else
	echo -e "\033[032mvsftp安装不成功！\033[0m"
fi




