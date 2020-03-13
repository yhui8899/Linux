#!/bin/bash

#mysql 全备，1天执行一次

port='3306'

back_src_dir="/var/lib/mysql/"

back_dir="/backup/"

pos_dir="${back_dir}/pos"

db_dir="${back_dir}/db"

DATE=`date +%Y%m%d`

user='root'

pass='xxx'

bak_db='jumpserver'   #如果有多个库，可以使用空格分隔

mysql_bin='/usr/bin'

socket="/var/lib/mysql/mysql.sock"

if [ -d $pos_dir ]; then

       echo "backup dir exists"

   else

       mkdir -p $pos_dir

fi

#进行全备份

${mysql_bin}/mysql -u${user} -p${pass} --socket=${socket} -e "flush tables with read lock"

${mysql_bin}/mysql -u${user} -p${pass} --socket=${socket} -e "show master status\G" | awk '{print $2}'| sed -n '2,3p' > ${pos_dir}/old_position

\cp -pa ${pos_dir}/old_postition ${pos_dir}/bak_postition

for db in $bak_db

do

DumpFile="$db-$DATE.sql"

  if [ $db != "" ]

     then

        ${mysql_bin}/mysqldump -R -q --master-data=2 -u${user} -p${pass} ${db} > ${db_dir}/$DumpFile

        #把当前的binlog和position信息存入position文件

        #cat ${back_dir}/$DumpFile |grep 'MASTER_LOG_FILE'|awk -F"'" '{print $2}' > ${pos_dir}/$db.position

        #cat ${back_dir}/$DumpFile |grep 'MASTER_LOG_FILE'|awk -F"=" '{print $3}' |awk -F";" '{print $1}' >> ${pos_dir}/$db.position

  fi

   

done

${mysql_bin}/mysql -u${user} -p${pass} --socket=${socket} -e "unlock tables"

find ${db_dir} -name "*.sql" -type f -mtime +10 -exec rm -rf {} \;

 

==============================================

+

+ 添加到crontab，星期天运行全备， 1-6运行增量备份

+

==============================================

crontab -e

 

 

00 02 * * * /usr/local/sbin/mysqlall.sh

 

 

#如果数据库很大， 可以执行星期天全量，1-6 增量备份

===========增备 下面保存为mysqlincr.sh======================

+

+

==================================================

 

 

#!/bin/bash

#mysql 增备，1-6每天执行一次

 

 

port='3306'

back_src_dir="/var/lib/mysql/"

back_dir="/backup/"

pos_dir="${back_dir}/pos"

incr_dir="${back_dir}/incr"

DATE=`date +%Y%m%d`

user='root'

pass='xxxx'

bak_db='jumpserver' #多个数据库，使用空格分隔

mysql_bin='/usr/bin'

socket="/var/lib/mysql/mysql.sock"

 

 

if [ -d $pos_dir ]; then

       echo "backup dir exists"

   else

       mkdir -p $pos_dir

fi

 

 

#获取上次备份完成时的binlog和position

start_binlog=`sed -n '1p' ${pos_dir}/old_position`

start_pos=`sed -n '2p' ${pos_dir}/old_position`

 

 

#锁定表，刷新log，进行增量备份

${mysql_bin}/mysql -u${user} -p${pass} --socket=${socket} -e "flush tables with read lock"

 

 

#获取目前的binlog和position

${mysql_bin}/mysql -u${user} -p${pass} --socket=${socket} -e "show master status\G" | awk '{print $2}'| sed -n '2,3p' > ${pos_dir}/now_position

stop_binlog=`sed -n '1p' ${pos_dir}/now_position`

stop_pos=`sed -n '2p' ${pos_dir}/now_position`

 

 

 

 

#如果在同一个binlog中

if [ "${start_binlog}" == "${stop_binlog}" ]; then

${mysql_bin}/mysqlbinlog --start-position=${start_pos} --stop-position=${stop_pos} ${back_src_dir}/${start_binlog} >> ${incr_dir}/Incr_back-$DATE.sql

 

 

#跨binlog备份

else

startline=`awk "/${start_binlog}/{print NR}" ${back_src_dir}/mysql-bin.index`

stopline=`wc -l ${back_src_dir}/mysql-bin.index |awk '{print $1}'`

for i in $(seq ${startline} ${stopline})

do

binlog=`sed -n "$i"p ${back_src_dir}/mysql-bin.index |sed 's/.*\///g'`

case "${binlog}" in

"${start_binlog}")

${mysql_bin}/mysqlbinlog --start-position=${start_pos} ${back_src_dir}/${binlog} >> ${incr_dir}/Incr_back-$DATE.sql

;;

"${stop_binlog}")

${mysql_bin}/mysqlbinlog --stop-position=${stop_pos} ${back_src_dir}/${binlog} >> ${incr_dir}/Incr_back-$DATE.sql

;;

*)

${mysql_bin}/mysqlbinlog ${back_src_dir}/${binlog} >> ${incr_dir}/Incr_back-$DATE.sql

;; 

esac

done

fi

 

 

#解除表锁定，并保存目前的binlog和position信息到position文件。

${mysql_bin}/mysql -u${user} -p${pass} --socket=${socket} -e "unlock tables"

\cp -pa ${pos_dir}/now_position ${pos_dir}/old_position

 

 

find ${incr_dir} -name "*.sql" -type f -mtime +7 -exec rm -rf {} \;