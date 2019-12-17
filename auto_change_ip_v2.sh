#!/bin/bash
#2017年7月3日20:35:15
#auto change server ip address.
#####################
ETH_CONF="/etc/sysconfig/network-scripts/ifcfg-eth0"
BACK_DIR=/data/backup/`date +%Y%m%d%H%M`
NETMASK="255.255.255.0"

judge_ip(){
#judge ip address
while true
do
	read -p "Please Enter server IP address:" IPADDR
	echo $IPADDR|grep -E "\<([0-9]{1,3}\.){3}[0-9]{1,3}\>"	
	if [ $? -eq 0 ];then
		IP=(`echo $IPADDR|sed 's/\./ /g'`)
		IP1=`echo ${IP[0]}`
		IP2=`echo ${IP[1]}`
		IP3=`echo ${IP[2]}`
		IP4=`echo ${IP[3]}`
		if [ $IP1 -gt 0 -a $IP1 -le 255 -a $IP2 -gt 0 -a $IP2 -le 255 -a $IP3 -gt 0 -a $IP3 -le 255 -a $IP4 -gt 0 -a $IP4 -le 255 ];then
			 break;	
		fi
	fi
done
}

change_ip(){
if [ ! -d $BACK_DIR ];then
	mkdir -p $BACK_DIR
fi
cp $ETH_CONF $BACK_DIR
##config ip address
grep -i "dhcp"  	$ETH_CONF
if [ $? -eq 0 ];then
	sed -i 's/dhcp/static/g;s/ONBOOT=no/ONBOOT=yes/g' $ETH_CONF
	judge_ip
	cat>>$ETH_CONF<<EOF
IPADDR=$IPADDR
NETMASK=$NETMASK
GATEWAY=`echo $IPADDR|awk -F. '{print $1"."$2"."$3".1"}'`
EOF

else
	read -p "The IP is Static ipaddress,Please ensure change server IP address,yes or no?" INPUT
	if [ $INPUT == "yes" -o $INPUT == "Y" ];then
		judge_ip
		sed -i "s/IPADDR=.*/IPADDR=$IPADDR/g" $ETH_CONF
	else
		exit 0
	fi
fi
service network restart
}

change_hosts(){
	#change server host name 2017
	judge_ip
	NAME=`echo $IPADDR|sed 's/\./\-/g'`
	hostname BJ-IDC-${NAME}.jfedu.net
	echo "BJ-IDC-${NAME}.jfedu.net" >/etc/hostname
	grep "BJ-IDC-${NAME}.jfedu.net" /etc/hosts
	if [ $? -ne 0 ];then
		echo "$IPADDR BJ-IDC-${NAME}.jfedu.net" >>/etc/hosts
	fi
}

PS3="Please you want to exec menu: "
select  i  in  change_ip  change_hosts  quit
do
	case $i in

		change_ip)
		change_ip
		;;
		change_hosts)
		change_hosts
		;;
		quit)
		exit 0
		;;
	esac
done
