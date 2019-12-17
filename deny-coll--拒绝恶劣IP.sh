#!/bin/bash

Y_Time=`date +%y%m%d`
Cur=`date +%H%M%S`
Becur=`date -d "1 minute ago" +%H%M%S`

Badip=`tail -n10000 /var/log/haproxy.log |grep "/shop/list.do?shopId=" |awk -v a="$Becur" -v b="$Cur" -F [' ':] '{t=$4$5$6; if (t>=a && t<=b) print $10}' | sort | uniq -c | sort -rn |awk '$1 > 50 {print $2}' |grep -Ev "192.168|119.147.184.19|14.23.123.122"`

BadRegip=`tail -n10000 /var/log/haproxy.log |grep "/reward/register" |awk -v a="$Becur" -v b="$Cur" -F [' ':] '{t=$4$5$6; if (t>=a && t<=b) print $10}' | sort | uniq -c | sort -rn |awk '$1 > 29 {print $2}' |grep -Ev "192.168|119.147.184.19|14.23.123.122"`

#Badip=`tail -n10000 /var/log/haproxy.log |egrep -v "\.(gif|jpg|jpeg|png|css|js)" |awk -v a="$Becur" -v b="$Cur" -F [' ':] '{t=$4$5$6; if (t>=a && t<=b) print $10}' | sort | uniq -c | sort -rn |awk '$1 > 50 {print $2}' |grep -Ev "192.168|119.147.184.19|14.23.123.122"`

if [ ! -z "$Badip" ];then
   for ip in $Badip;
   do
          if test -z "`/sbin/iptables -nL | grep $ip`";then
                  echo $Y_Time $Cur $ip >> /tmp/deny_ip.log
                  /sbin/iptables -I INPUT -s $ip -j DROP
          fi    
   done

fi

if [ ! -z "$BadRegip" ];then
   for regip in $BadRegip;
   do
          if test -z "`/sbin/iptables -nL | grep $regip`";then
                  echo $Y_Time $Cur $regip >> /tmp/deny_ip.log
                  /sbin/iptables -I INPUT -s $regip -j DROP
          fi
   done

fi
