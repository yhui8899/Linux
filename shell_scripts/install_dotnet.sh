#!/bin/bash
#2020年1月4日13:28:57
#author by xiaofeige
#################################
# 			        #		
# install DotNet core 2.2.301	#
# 			      	#
# install Config Supervisor	#
# 				#
# install Config Rsync		#
# 				#
#################################
#DNT ENV
DNT_PACK1="epel-release libunwind libicu libgdiplus autoconf automake libtool freetype-devel fontconfig wget"
DNT_PACK2="libXft-devel libjpeg-turbo-devel libpng-devel giflib-devel libtiff-devel libexif-devel glib2-devel cairo-devel"
DNT_SOFT="dotnet-sdk-2.2.301-linux-x64.tar.gz"
DNT_URL="https://download.visualstudio.microsoft.com/download/pr/3224f4c4-8333-4b78-b357-144f7d575ce5/ce8cb4b466bba08d7554fe0900ddc9dd/"
INSTALL_DIR="/application/"

#SUPER ENV
SUPER_DIR="/etc/supervisor/"
DATA_DIR="/data/wwwroot/"

#NGINX ENV
YUM_PACK="gcc gcc-c++ pcre pcre-devel openssl openssl-devel wget"
NG_URL="http://nginx.org/download/"
NG_VER="1.17.7"
NG_SOFT="nginx-${NG_VER}.tar.gz"



# install dotnet core
set -e
function install_dotnet(){
if [[ -f /usr/bin/dotnet ]];then
	echo -e "\033[32mdotnet core already Exsis\033[0m"
	exit 0
fi
yum install ${DNT_PACK1} ${DNT_PACK2} -y

ln -s /usr/lib64/libgdiplus.so.0.0.0 /usr/lib64/gdiplus.dll

if [[ ! -f ${DNT_SOFT} ]];then
	wget -c ${DNT_URL}$DNT_SOFT
fi
mkdir -p ${INSTALL_DIR}dotnet-sdk-2.2.301
	tar -xf ${DNT_SOFT} -C ${INSTALL_DIR}dotnet-sdk-2.2.301/
if [ $? -ne 0 ];then
	echo "\033[31mPlease Check software package\033[0m"
	exit 1
fi
	ln -s ${INSTALL_DIR}dotnet-sdk-2.2.301 ${INSTALL_DIR}dotnet-sdk
	sleep 2
	ln -s ${INSTALL_DIR}dotnet-sdk/dotnet /usr/bin/
	sleep 3
	DOTNET_VER=`dotnet --version`
	dotnet --version >>/dev/null 2>&1
if [ $? -ne 0 ];then
	echo -e "\033[31mDotNet core install Faied!\033[0m"
	exit 1
else
	echo -e "\033[32mDotNet install Successful,Version:${DOTNET_VER}\033[0m"
fi
}

# install Supervisor
function install_supervisor(){
yum install python-setuptools -y
easy_install supervisor
mkdir ${SUPER_DIR}
echo_supervisord_conf > ${SUPER_DIR}supervisord.conf

cat >${SUPER_DIR}supervisord.conf <<EOF
[unix_http_server]
file=/usr/local/supervisor/supervisor.sock   ; the path to the socket file


[inet_http_server]         ; inet (TCP) server disabled by default
port=0.0.0.0:9001          ; ip_address:port specifier, *:port for all iface
username=aiagain           ; default is no username (open server)
password=aiagain123        ; default is no password (open server)

[supervisord]
logfile=/usr/local/supervisor/supervisord.log  ; main log file; default \$CWD/supervisord.log
logfile_maxbytes=50MB        ; max main logfile bytes b4 rotation; default 50MB
logfile_backups=10           ; # of main logfile backups; 0 means none, default 10
loglevel=info                ; log level; default info; others: debug,warn,trace
pidfile=/usr/local/supervisor/supervisord.pid ; supervisord pidfile; default supervisord.pid
nodaemon=false               ; start in foreground if true; default false
minfds=1024                  ; min. avail startup file descriptors; default 1024
minprocs=200                 ; min. avail process descriptors;default 200


[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface


[supervisorctl]
serverurl=unix:///usr/local/supervisor/supervisor.sock ; use a unix:// URL  for a unix socket

[include]
files = ${SUPER_DIR}conf.d/*.conf
EOF

mkdir -p ${SUPER_DIR}conf.d
mkdir -p /usr/local/supervisor
mkdir -p ${DATA_DIR}dotnet.demo/
mkdir -p /data/logs/outlogs/
mkdir -p /data/dotnet
cd /data/dotnet
dotnet new MVC -o MvcDemoApp
cd MvcDemoApp

cat > Program.cs<< EOF
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace MvcDemoApp
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateWebHostBuilder(args).Build().Run();
        }

        public static IWebHostBuilder CreateWebHostBuilder(string[] args) =>
            WebHost.CreateDefaultBuilder(args)
                .UseUrls("https://0.0.0.0:5001")
                .UseStartup<Startup>();
    }
}
EOF

dotnet publish --configuration Release
\cp -pa /data/dotnet/MvcDemoApp/bin/Release/netcoreapp2.2/publish/* ${DATA_DIR}dotnet.demo/

cat > ${SUPER_DIR}conf.d/dotnet.demo.conf<<EOF
[program:dotnet.demo]
command=/usr/bin/dotnet MvcDemoApp.dll
directory=${DATA_DIR}dotnet.demo/
autorestart=true
stderr_logfile=/data/logs/outlogs/dotnet.demo.err.log
stdout_logfile=/data/logs/outlogs/dotnet.demo.out.log
environment=ASPNETCORE_ENVIRONMENT=Production
user=root
stopsignal=INT
EOF

supervisord -c ${SUPER_DIR}supervisord.conf

if [ $? -ne 0 ];then
	echo -e "\033[31mSupervisord start Failed\033[0m"
	exit 1
else
	echo -e "\033[32mSupervisord start Successful!\033[0m"
	netstat -tnlp|grep -w 9001
fi

cat >/usr/lib/systemd/system/supervisord.service<<EOF
# dservice for systemd (CentOS 7.0+)
# by ET-CS (https://github.com/ET-CS)
[Unit]
Description=Supervisor daemon

[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c ${SUPER_DIR}supervisord.conf
ExecStop=/usr/bin/supervisorctl shutdown
ExecReload=/usr/bin/supervisorctl reload
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF
systemctl enable supervisord
systemctl is-enabled supervisord
supervisorctl reload
sleep 5

Check_IP=`ip addr|grep global|awk '{print $2}'|cut -f 1 -d /`

netstat -tnlp|grep -w "5001"
if [ $? -eq 0 ];then
	echo -e "\033[32mSupervisor project start Successful! 可打开浏览器访问：https://${Check_IP}:5001\033[0m"
else
	echo -e "\033[31mSupervisor project start Failed\033[0m"
	exit 1
fi

}

# install nginx
function install_nginx(){
	SCRIPT_DIR=$(cd $(dirname $0)&& pwd)
	cd ${SCRIPT_DIR}
if [[ -d ${INSTALL_DIR}nginx ]];then
	echo -e "\033[33myour already install nginx\033[0m"
	exit 0
elif [[ ! -f ${NG_SOFT} ]];then
	wget -c ${NG_URL}${NG_SOFT}
fi
	yum install ${YUM_PACK} -y
	tar -xf ${NG_SOFT}
if [ $? -ne 0 ];then
	echo -e "\033[33mPlease Check nginx package\033[0m"
	exit 1
fi
	cd nginx-${NG_VER}
	./configure --prefix=${INSTALL_DIR}nginx --with-http_ssl_module --with-http_stub_status_module --with-stream
	make && make install
if [ $? -eq 0 ];then
	echo -e "\033[32mnginx install Successful!\033[0m"
else
	echo -e "\033[31mnginx make or make install failed\033[0m"
fi
	${INSTALL_DIR}nginx/sbin/nginx
if [ $? -ne 0 ];then
        echo -e "\033[31mnginx start failed!\033[0m"
	exit 1
else
	netstat -tnlp|grep -w 80
	
fi
}


# install Rsync

function install_rsync(){
yum install rsync -y
cat >/etc/rsyncd.conf<<EOF
uid = root
gid = root
port = 8738
auth users = jenkins
secrets file = /etc/rsync.password

[apollo.demo.com]
path = ${DATA_DIR}apollo.demo.com
read only = no

[api.apollo.demo.com]
path = ${DATA_DIR}api.apollo.demo.com
read only = no

[im.apollo.demo.com]
path = ${DATA_DIR}im.apollo.demo.com
read only = no

[mpmq.apollo.demo.com]
path = ${DATA_DIR}mpmq.apollo.demo.com
read only = no

[kf.apollo.demo.com]
path = ${DATA_DIR}kf.apollo.demo.com
read only = no
EOF

#create Project directory
mkdir -p ${DATA_DIR}{apollo.demo.com,api.apollo.demo.com,mpmq.apollo.demo.com,kf.apollo.demo.com,im.apollo.demo.com}
#Create password file
cat >/etc/rsync.password<<EOF
jenkins:123456
EOF
chmod 600 /etc/rsync.password
systemctl start rsyncd
netstat -tnlp|grep -w 8738
}

read -p "
----------------------------

1) install DotNet Core
	
2) install Supervisor

3) install nginx

4) install Rsync

5) install ALL

----------------------------
Please Choose Software Install ": input
case $input in
	1) 
	 install_dotnet
	 ;;
	2)
	 install_supervisor
	 ;;
	3)
	 install_nginx
	 ;;
	4)
	 install_rsync
	 ;;
	5)
	 install_dotnet
	 install_supervisor
	 install_nginx
	 install_rsync
	 ;;
	*)
	echo
	 echo -e "\033[33mUsage:{$0|1|2|3|4|5|help}\033[0m"
	 ;;
esac

exit