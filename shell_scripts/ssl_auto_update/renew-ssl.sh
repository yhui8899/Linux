#!/bin/bash

# Source function library.
. /etc/init.d/functions

LogFile="/tmp/haproxycheck.log"
LogDate=`date '+%Y-%m-%d %H:%M'`
SslDir="/usr/local/haproxy/ssl"


/home/yunwei/.acme.sh/acme.sh --cron --home "/home/yunwei/.acme.sh" > /tmp/acme.log
CertSu=`grep "Cert success" /tmp/acme.log |wc -l`

if [[ $CertSu -eq 0 ]]; then
        echo "$LogDate Cert Don't Update" >> $LogFile
else
	cat $SslDir/qltshop/cert.pem $SslDir/qltshop/key.pem |tee $SslDir/qltshop/qltshopkey.pem > /dev/null 2>&1
        echo "$LogDate Cert Update Success" >> $LogFile
        CheckNginx=`sudo /etc/init.d/haproxy check > /dev/null 2>&1`
        if [[ $? -eq 0 ]]; then
                sudo /etc/init.d/haproxy restart
                echo "$LogDate Haproxy Restart" >> $LogFile
        else
                echo "$LogDate Haproxy Config Error" >> $LogFile
        fi

	#update 6.32 cert
	scp -P 43999 $SslDir/qltshop/qltshopkey.pem yunwei@192.168.6.32:$SslDir/qltshop/qltshopkey.pem >/dev/null 2>&1
	ssh -p 43999 yunwei@192.168.6.32 "sudo /etc/init.d/haproxy restart"
	echo "$LogDate 6.32-Haproxy-Ssl Update" >> $LogFile

fi
