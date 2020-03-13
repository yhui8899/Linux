#!/bin/bash
#2019年4月12日16:31:21
#Author:xiaofeige

#HTTPD_VER=`httpd -v|awk 'NR<2{print $3}'|cut -f 2 -d /`
#SVN_VER=`svnserve --version|awk 'NR<2{print $3}'`
SVN_CK=`ls /var/www/svn/sungeek|wc -l`
IPADDR=`ip addr|grep global|awk '{print $2}'|cut -f 1 -d /`
SVNADMIN=download
SVNADMIN_URL=http://sourceforge.net/projects/ifsvnadmin/files/svnadmin-1.6.2.zip/download
SVN_DIR=/var/www/svn

yum install httpd -y
yum install mod_dav_svn subversion -y

httpd -version
if [[ $? -ne 0 ]];then
	echo -e "\033[31mhttpd安装失败!\033[0m"
	exit 1
fi

sleep 5
svnserve --version
SVN_VER=`svnserve --version|awk 'NR<2{print $3}'`
if [[ $? -eq 0 ]];then
        echo -e "\033[32mSVN版本:${SVN_VER}\033[0m"
else
	echo -e "\033[31mSVN安装失败!\033[0m"
	exit
fi

sleep 5
SVN_M=`ls /etc/httpd/modules/ |grep svn|wc -l`
if [[ $SVN_M -ne 2 ]];then

	echo -e "\033[31m找不到:mod_authz_svn.so和mod_dav_svn.so文件\033[0m"
	exit 1
fi

cat >>/etc/httpd/conf.d/subversion.conf<<EOF
LoadModule dav_svn_module modules/mod_dav_svn.so
LoadModule authz_svn_module modules/mod_authz_svn.so

<Location /svn>
DAV svn
SVNParentPath $SVN_DIR   
AuthType Basic              
AuthName "Authorization SVN"   
AuthUserFile $SVN_DIR/passwd     
AuthzSVNAccessFile $SVN_DIR/authz  
Require valid-user            
</Location>
EOF

if [[ $? -ne 0 ]];then
	echo -e "\033[31msubversion.conf配置文件写入失败!\033[0m"
	exit 1
fi

mkdir $SVN_DIR
svnadmin create $SVN_DIR/sungeek

if [ $SVN_CK = "" ];then
	echo -e "\033[31mSVN仓库创建不成功\033[0m"
	exit 1
fi

touch $SVN_DIR/passwd
touch $SVN_DIR/authz
chown -R apache.apache $SVN_DIR

yum install php -y

#下载if.svnadmin软件包
yum install unzip -y

if [[ ! -f $SVNADMIN ]];then
	wget -c $SVNADMIN_URL
fi
	
unzip $SVNADMIN
if [[ $? -ne 0 ]];then
	 echo -e "\033[31m${SVNADMIN}解压失败，请查看文件是否存在\033[0m"
	 exit
fi


\cp -r iF.SVNAdmin-stable-1.6.2 /var/www/html/svnadmin
cd /var/www/html
chown -R apache.apache svnadmin
cd /var/www/html/svnadmin
chmod -R 777 data

sed -i 's/OPTIONS="-r \/var\/svn"/OPTIONS="-r \/var\/www\/svn"/g' /etc/sysconfig/svnserve

netstat -tnlp|grep 80
if [[ $? -eq 0 ]];then
	echo -e "\033[31m80端口已被占用,请关闭后重试!\033[0m"
	exit
fi

systemctl start httpd.service
systemctl enable httpd.service
systemctl restart httpd.service
if [[ $? -eq 0 ]];then
	echo -e "\033[32m恭喜您，iF.SVNAdmin安装成功\033[0m"
	echo -e "\033[32m您可以使用浏览器打开：http://${IPADDR}/svnadmin进行初始化配置\033[0m"
	echo -e "\033[32m授权文件:$SVN_DIR/authz\033[0m"
	echo -e "\033[32m授权文件:$SVN_DIR/passwd\033[0m"
else
	echo -e "\033[31mhttpd启动失败!\033[0m"
	exit 1
fi




















	
