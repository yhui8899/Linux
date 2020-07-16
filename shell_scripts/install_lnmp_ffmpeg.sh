#!/bin/bash
# auto_install_nginx_php_ffmpeg
# 2020年7月10日15:00:09
# author by xiaofeige
########################################

function install_nginx(){
if [[ `netstat -tnlp|grep 80` != '' ]] && [[ `ps -ef|grep -v grep|grep nginx|wc -l` != 0 ]];then
    echo -e "\033[33mnginx already Exist!\033[0m"
    exit
elif [[ `netstat -tnlp|grep -w 80` != '' ]];then
    echo -e "\033[33m80 port already Exist\033[0m"
    exit
fi

read -p "please enter nginx version:" ngx_version
ngx_package=nginx-${ngx_version}.tar.gz
ngx_url=http://nginx.org/download/nginx-${ngx_version}.tar.gz
ngx_dir=/usr/local/nginx

yum install gcc gcc-c++ pcre pcre-devel bzip2 zlip zlib-devel openssl openssl-devel wget -y
if [[ ! -f ${ngx_package} ]];then
    wget ${ngx_url}
fi

tar -xf ${ngx_package}
cd nginx-${ngx_version}
./configure --prefix=${ngx_dir} --with-http_ssl_module --with-stream --with-http_stub_status_module
if [ $? -ne 0 ];then
	echo "please check ${ngx_package}"
	exit 1
fi
make && make install
mkdir -p ${ngx_dir}/conf/vhost
cat >${ngx_dir}/conf/nginx.conf<<EOF
worker_processes     8;
worker_cpu_affinity 00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;
error_log  /usr/local/nginx/logs/nginx_error.log  info;
worker_rlimit_nofile 65535;
worker_priority -20;

pid        /usr/local/nginx/logs/nginx.pid;

events
    {
        use epoll;
        worker_connections 65535;
        multi_accept on;
    }

http
    {
        include       mime.types;
        default_type  application/octet-stream;

        server_names_hash_bucket_size 128;
        client_header_buffer_size 32k;
        large_client_header_buffers 4 32k;
        client_max_body_size 110m;
        fastcgi_intercept_errors on;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_buffer_size 64k;
        fastcgi_buffers 4 64k;
        fastcgi_busy_buffers_size 128k;
        fastcgi_temp_file_write_size 256k;

        sendfile   on;
        tcp_nopush on;

        keepalive_timeout 60;

        tcp_nodelay on;
        open_file_cache max=102400 inactive=20s;
        open_file_cache_valid 30s;
        open_file_cache_min_uses 1;
        #Gzip Compression
        gzip on;
        gzip_buffers 16 8k;
        gzip_comp_level 6;
        gzip_http_version 1.0;
        gzip_min_length 256;
        gzip_proxied any;
        gzip_vary on;
        gzip_types
        text/xml application/xml application/atom+xml application/rss+xml application/xhtml+xml image/svg+xml
        text/javascript application/javascript application/x-javascript
        text/x-json application/json application/x-web-app-manifest+json
        text/css text/plain text/x-component
        font/opentype application/x-font-ttf application/vnd.ms-fontobject
        image/x-icon;
        gzip_disable "MSIE [1-6]\.(?!.*SV1)";



        #limit_conn_zone \$binary_remote_addr zone=perip:10m;
        #If enable limit_conn_zone,add "limit_conn perip 10;" to server section.

        log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                          '\$status \$body_bytes_sent "\$http_referer" '
                          '"\$http_user_agent" "\$http_x_forwarded_for" 客户时间:"\$request_time" 服务器时间:"\$upstream_response_time" ';

        server_tokens off;
        access_log /usr/local/nginx/logs/nginx-access.log;
        include vhost/*.conf;
        }
EOF
cat >${ngx_dir}/conf/vhost/localhost.conf<<EOF
server {
        listen 80;
        server_name localhost;
        index  index.php index.htm index.aspx index.shtml index.html;
        root   html;

        access_log  /usr/local/nginx/logs/localhost_access.log main;
        error_log    /usr/local/nginx/logs/localhost_error.log   error;

       location ~ \.php$ {
           fastcgi_pass 127.0.0.1:9000;
           fastcgi_index index.php;
           fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
           include fastcgi_params;
        }


       location / {
        if (!-e \$request_filename) {
            rewrite ^(.*)$ /index.php?s=/\$1 last;
            break;
        }
        }
       location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|flv|mp4|ico)$ {
              expires 30d;
              access_log off;
        }
       location ~ .*\.(js|css)?$ {
           expires 7d;
           access_log off;
       }
}

EOF
sleep 1
${ngx_dir}/sbin/nginx

if [[ `netstat -tnlp|grep -w 80` != '' ]];then
	echo -e "\033[32mNginx-${ngx_version} Install Successful\033[0m"
        netstat -tnlp|grep -w 80
else
    echo -e "\033[32mNginx start Failed please nginx config file\033[0m"
	exit 1
fi
}

################################################################
function install_mysql(){
#default install database mysql8.0
M_version=8.0.20
M_soft=mysql-${M_version}-linux-glibc2.12-x86_64.tar.xz
M_url=https://cdn.mysql.com//Downloads/MySQL-8.0
M_datadir=/data/mysql
M_basedir=/usr/local/mysql

if [[ `netstat -tnlp|grep -w 3306` != '' ]] && [[ `ps -ef|grep -v grep|grep mysql|wc -l` != 0 ]];then
    echo -e "\033[33mMysql server already Exist!\033[0m"
    exit 0
elif [[ `netstat -tnlp|grep -w 3306` != '' ]];then
    echo -e "\033[33m3306 port already Exist\033[0m"
    exit 0
fi

yum install libaio wget -y
useradd mysql && mkdir -p ${M_datadir} && chown -R mysql.mysql /data/mysql
if [[ ! -d ${M_datadir} ]];then
      mkdir -p ${M_datadir}
elif [[ ! -f ${M_soft} ]];then
      wget ${M_url}/${M_soft}
fi

tar -xf ${M_soft}
mv mysql-8.0.20-linux-glibc2.12-x86_64 ${M_basedir}
\cp ${M_basedir}/support-files/mysql.server  /etc/init.d/mysqld

cat >/etc/my.cnf<<EOF
[mysqld]
datadir=/data/mysql
socket=/tmp/mysql.sock
symbolic-links=0
#fault_authentication_plugin= mysql_native_password
log_error = /data/mysql/mysql.log

!includedir /etc/my.cnf.d
EOF
sleep 2
${M_basedir}/bin/mysqld --initialize --user=mysql --basedir=${M_basedir}/ --datadir=${M_datadir}/
sleep 2
echo 'export PATH=$PATH:/usr/local/mysql/bin' >>/etc/profile
source /etc/profile

chmod +x /etc/init.d/mysqld
chkconfig  --add mysqld
chkconfig  --level 35 mysqld  on

M_init_pass=`grep 'temporary password' /data/mysql/mysql.log |awk '{print $NF}'` 
service mysqld start
if [[ $? -eq 0 ]];then
    echo -e "\033[32mMysql-${M_version} Install Successful\033[0m"
    netstat -tnlp|grep 3306
    echo -e "\033[33mYour Mysql Initialization Password: ${M_init_pass}\033[0m"
else
    echo -e "\033[31mMysql-${M_version} Startup Failed Check config File !\033[0m"
fi
}

###############################################################
function install_ffmpeg(){
#default install ffmpeg-4.3
f_version=4.3
f_soft=ffmpeg-${f_version}.tar.bz2
f_dir=/usr/local/ffmpeg
f_url=https://ffmpeg.org/releases/${f_sort}
f_args="--enable-shared --disable-static --disable-doc --enable-libopencore-amrnb --enable-libopencore-amrwb  --enable-version3 --enable-libmp3lame"
yum_soft1="gcc gcc-c++ automake pcre pcre-devel bzip2 zlip zlib-devel openssl openssl-devel cmake wget"
yum_soft2="ncurses-devel bison libmcrypt-devel mcrypt mhash gd-devel libxml2-devel bzip2-devel libcurl-devel"
yum_soft3="curl-devel libjpeg-devel libpng-devel freetype-devel net-snmp-devel openssl-deve python-devel zlib-devel"
yum_soft4="freetype libxslt* bison autoconf re2c libmcrypt libltdl.so.7"

ffmpeg --help >>/dev/null 2>&1
if [[ $? -eq 0 ]];then
    echo -e "\033[33mffmeg soft already Exist!\033[0m"
    exit
fi
yum install epel-release -y
yum install yasm -y
yum install ${yum_soft1} ${yum_soft2} ${yum_soft3} ${yum_soft4} -y

#安装opencore-amr软件包：
rpm -ivh https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
yum install opencore-amr-devel.x86_64 -y

#安装lame软件包：
if [[ ! -f lame-3.100.tar.gz ]];then
wget https://nchc.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
fi
tar -xf lame-3.100.tar.gz
cd lame-3.100
./configure --prefix=/usr/local
make && make install
cp -a /usr/local/lib/libmp3lame.* /usr/lib64/
sleep 2
cd ../

if [[ ! -f ${f_soft} ]];then
    wget ${f_url}
fi

tar -xf ${f_soft}

cd ffmpeg-${f_version}
./configure --prefix=${f_dir} ${f_args}
if [[ $? -ne 0 ]];then
    echo -e "\033[31m Install Failed Please Check ${f_soft} or Related plugins \033[0m"
    exit 1
fi

make -j`grep 'processor' /proc/cpuinfo|wc -l` && make install
sleep 2
echo '/usr/local/ffmpeg/lib' >/etc/ld.so.conf.d/ffmpeg.conf
ldconfig
ln -sf ${f_dir}/bin/{ffmpeg,ffprobe} /usr/bin/

ffmpeg --help >>/dev/null 2>&1
if [[ $? -eq 0 ]];then
    echo -e "\033[32mffmeg Install Successful!\033[0m"
fi
}
########################################################
function install_php(){
#default install php-7.2.6
p_version=7.2.6
p_soft=php-${p_version}.tar.gz
p_dir=/usr/local/php
p_url="https://www.php.net/distributions/${p_soft}"
p_args1="--with-curl --with-freetype-dir --with-gd --with-gettext --with-iconv-dir --with-kerberos --with-libdir=lib64"
p_args2="--with-libxml-dir --with-mysqli --with-openssl --with-pcre-regex --with-pdo-mysql --with-pdo-sqlite"
p_args3="--with-pear --with-png-dir --with-jpeg-dir --with-xmlrpc --with-xsl --with-zlib --with-bz2 --with-mhash --enable-fpm"
p_args4="--enable-bcmath --enable-libxml --enable-inline-optimization --enable-gd-native-ttf --enable-mbregex"
p_args5="--enable-mbstring --enable-opcache --enable-pcntl --enable-shmop --enable-soap --enable-sockets"
p_args6="--enable-sysvsem --enable-sysvshm --enable-xml --enable-zip --enable-opcache"
yum_pack=(openssl openssl-devel curl curl-devel libjpeg libjpeg-devel libpng libpng-devel freetype \
freetype-devel pcre pcre-devel libxslt libxslt-devel bzip2 bzip2-devel libxml2 libxml2-devel wget )

if [[ -e ${p_dir}/sbin/php-fpm ]];then
    echo -e "\033[33m php-fpm already Exist!\033[0m"
    exit 0
fi

yum install ${yum_pack[@]} -y
if [[ ! -f ${p_soft} ]];then
   wget ${p_url}
fi

tar -xf ${p_soft}
cd php-${p_version}
./configure --prefix=${p_dir} ${p_args1} ${p_args2} ${p_args3} ${p_args4} ${p_args5} ${p_args6}
make -j`grep 'processor' /proc/cpuinfo|wc -l` && make install
if [[ $? -ne 0 ]];then
    echo -e "\033[31m Install Failed Please Check ${p_soft} or Related plugins \033[0m"
    exit 1
fi

cp php.ini-production  /usr/local/php/lib/php.ini
sed -i '/cgi.fix_pathinfo=1/acgi.fix_pathinfo=0' /usr/local/php/lib/php.ini
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp sapi/fpm/php-fpm /usr/local/bin
mv /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
cat >/usr/local/nginx/html/info.php<< EOF
<?php
phpinfo();
?>
EOF
#php扩展opcache模块:
cd ext/opcache/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
if [[ $? -ne 0 ]];then
    echo -e "\033[31mphp扩展opcache模块安装失败！\033[0m"
    exit 1
fi

cat >>/usr/local/php/lib/php.ini<<EOF
zend_extension = /usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/opcache.so
opcache.memory_consumption=64
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.force_restart_timeout=180
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
EOF
cd ../../
/usr/local/php/sbin/php-fpm
if [[ $? -ne 0 ]];then
  echo -e "\033[31mphp-fpm Start Failed Please Check Config File!\033[0m"
else
  echo -e "\033[32mphp-fpm Start Successful!\033[0m"
  netstat -tnlp|grep 9000
fi
}

############################################################################
function install_ffmpeg_php(){
#安装ffmpeg_php扩展插件,要求：PHP版本：7.2.6或5.6

if [[ `ps -ef|grep -v grep|grep php-fpm` == '' ]];then
    echo -e "\033[33mphp-fpm Not Exist or php-fpm Not startup\033[0m"
    exit
fi

yum install ffmpeg-devel git -y
if [[ ! -f ffmpeg-php.tar.gz ]];then
    git clone https://github.com/TownNews/ffmpeg-php.git
else
   tar -xf ffmpeg-php.tar.gz
fi

cp -r /usr/local/ffmpeg/include/* /usr/include/

cd ffmpeg-php/
/usr/local/php/bin/phpize
./configure --with-php-config=/usr/local/php/bin/php-config
make && make install
if [[ $? -ne 0 ]];then
    echo -e "\033[31mffmpeg_php扩展插件安装失败！\033[0m"
    exit 1
else
   ls /usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/ffmpeg.so
fi

cat >/usr/local/php/lib/php.ini<< EOF
[PHP]
[opcache]
zend_extension= /usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/opcache.so
opcache.enable=1
opcache.memory_consumption = 64
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 0
opcache.fast_shutdown = 1
opcache.enable_cli = 1
engine = On
short_open_tag = On
asp_tags = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions = passthru,system,chroot,chgrp,chown,proc_open,proc_get_status,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server
disable_classes =
zend.enable_gc = On
expose_php = On
max_execution_time = 300
max_input_time = 60
memory_limit = 256M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 120M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
default_charset = "UTF-8"
doc_root =
user_dir =
enable_dl = Off
cgi.fix_pathinfo=0
file_uploads = On
upload_max_filesize = 110M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
#extension=fileinfo.so
[CLI Server]
cli_server.color = On
[Date]
date.timezone = PRC
[filter]
[iconv]
[intl]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
[Phar]
[mail function]
SMTP = localhost
smtp_port = 25
mail.add_x_header = On
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "%Y-%m-%d %H:%M:%S"
ibase.dateformat = "%Y-%m-%d"
ibase.timeformat = "%H:%M:%S"
[MySQL]
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[OCI8]
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_strict_mode = 0
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatibility_mode = Off
mssql.secure_connection = Off
[Assertion]
[COM]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[mcrypt]
[dba]
[opcache]
opcache.memory_consumption=192
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=4000
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.enable_cli=1
[curl]
[openssl]
extension=/usr/local/php/lib/php/extensions/no-debug-non-zts-20170718/ffmpeg.so
EOF

pkill php-fpm && /usr/local/php/sbin/php-fpm
if [[ $? -ne 0 ]];then
    echo -e "\033[31mphp-fpm startup failed please Check php config file\033[0m"
else
   netstat -tnlp|grep 9000
   /usr/local/php/bin/php -i |grep ffmpeg
   echo -e "\033[32mffmpeg-php Install Successful\033[0m"
fi

}

read -p "Please Choose Install Software Number
 1 >> Install_Nginx
 
 2 >> Install_Mysql

 3 >> Install_ffmpeg

 4 >> Install_PHP

 5 >> Install_ffmpeg_php 
 
 6 >> Install_ALL

 Input:" input

case $input in 
     1)
     install_nginx
     ;;
     
     2)
     install_mysql
     ;;

     3)
     install_ffmpeg
     ;;

     4)
     install_php
     ;;

     5)
     install_ffmpeg_php
     ;;

     6)
     install_nginx
     install_mysql
     install_ffmpeg
     install_php
     install_ffmpeg_php
     ;;     

     *)
     echo -e "\033[33mYour Enter Invalid!\033[0m"
esac
exit 0
