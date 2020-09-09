#!/bin/sh
#auto install config bind server
#定义变量
BND_ETC=/var/named/chroot/etc
BND_VAR=/var/named/chroot/var/named
BAK_DIR=/data/backup/dns_`date +%Y%m%d-%H%M`
##Backup named server
if
      [ ! -d  $BAK_DIR ];then
      echo "Please waiting  Backup Named Config ............"
      mkdir   -p  $BAK_DIR 
      cp -a  /var/named/chroot/{etc,var}   $BAK_DIR 
      cp -a  /etc/named.* $BAK_DIR
fi
##Define Shell Install Function 
Install () 
{
  if
     [ ! -e /etc/init.d/named ];then
     yum install bind* -y
else
     echo -------------------------------------------------
     echo "The Named Server is exists ,Please exit ........."
     sleep 1
 fi
}
##Define Shell Init Function 
Init_Config ()
{
       sed  -i -e 's/localhost;/any;/g' -e '/port/s/127.0.0.1/any/g' /etc/named.conf
       echo -------------------------------------------------
       sleep 2 
       echo "The named.conf config Init success !"
}
##Define Shell Add Name Function 
Add_named ()
{
##DNS name
       read -p  "Please  Insert Into Your Add Name ,Example 51cto.com :" NAME
       echo $NAME |grep -E "com|cn|net|org"
       while
        [ "$?" -ne 0 ]
         do
        read -p  "Please  reInsert Into Your Add Name ,Example 51cto.com :" NAME
        echo $NAME |grep -E "com|cn|net|org"
     done
## IP address 
       read -p  "Please  Insert Into Your Name Server IP ADDress:" IP 
       echo $IP |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"
       while 
       [ "$?" -ne "0" ]
        do
        read -p  "Please  reInsert Into Your Name Server IP ADDress:" IP 
       echo $IP |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"
      done
       ARPA_IP=`echo $IP|awk -F. '{print $3"."$2"."$1}'`
       ARPA_IP1=`echo $IP|awk -F. '{print $4}'`
       cd  $BND_ETC 
       grep  "$NAME" named.rfc1912.zones
if

         [ $? -eq 0 ];then
         echo "The $NAME IS exist named.rfc1912.zones conf ,please exit ..."
         exit
else
        read -p  "Please  Insert Into SLAVE Name Server IP ADDress:" SLAVE 
        echo $SLAVE |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"
        while
        [ "$?" -ne "0" ]

        do
			read -p  "Please  Insert Into SLAVE Name Server IP ADDress:" SLAVE 
			echo $SLAVE |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"
        done
			grep  "rev" named.rfc1912.zones
       if
         [ $? -ne 0 ];then
			cat >>named.rfc1912.zones <<EOF

#`date +%Y-%m-%d` Add $NAME CONFIG       
zone "$NAME" IN {
        type master;
        file "$NAME.zone";
        allow-update { none; };
};

zone "$ARPA_IP.in-addr.arpa" IN {
        type master;
        file "$ARPA_IP.rev";
        allow-update { none; };
};

EOF
      else
		cat >>named.rfc1912.zones <<EOF

#`date +%Y-%m-%d` Add $NAME CONFIG
zone "$NAME" IN {
        type master;
        file "$NAME.zone";
        allow-update { none; };
};

EOF
    fi

fi

       [ $? -eq 0 ]&& echo "The $NAME config name.rfc1912.zones success !"
       sleep 3 ;echo "Please waiting config $NAME zone File ............."
       cd  $BND_VAR
       read -p "Please insert Name DNS A HOST ,EXample  www or mail :" HOST
       read -p "Please insert Name DNS A NS IP ADDR ,EXample 192.168.111.130 :" IP_HOST 
       echo $IP_HOST |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"
       ARPA_IP2=`echo $IP_HOST|awk -F. '{print $3"."$2"."$1}'`
       ARPA_IP3=`echo $IP_HOST|awk -F. '{print $4}'`
       while 
       [ "$?" -ne "0" ]
do
       read -p "Please Reinsert Name DNS A IPADDRESS ,EXample 192.168.111.130 :" IP_HOST 
       echo $IP_HOST |egrep -o "([0-9]{1,3}\.){3}[0-9]{1,3}"
done
       cat >$NAME.zone <<EOF
\$TTL    86400
@               IN SOA  localhost.      root.localhost. (
                                        43              ; serial (d. adams)
                                        1H              ; refresh
                                        15M             ; retry
                                        1W              ; expiry
                                        1D )            ; minimum

                IN  NS          $NAME.
EOF
       REV=`ls  *.rev`
       ls  *.rev >>/dev/null
if  
       [ $? -ne 0 ];then 
       cat >>$ARPA_IP.rev <<EOF
\$TTL    86400
@       IN      SOA     localhost.    root.localhost.  (
                                      1997022703 ; Serial
                                      28800      ; Refresh
                                      14400      ; Retry
                                      3600000    ; Expire
                                      86400 )    ; Minimum

            IN  NS  $NAME.
EOF

        echo  "$HOST             IN  A           $IP_HOST" >>$NAME.zone
        echo  "$ARPA_IP3         IN  PTR         $HOST.$NAME." >>$ARPA_IP.rev
        

        [ $? -eq 0 ]&& echo -e "The $NAME config success:\n$HOST       IN  A           $IP_HOST\n$ARPA_IP3         IN  PTR         $HOST.$NAME." 

else   
        sed -i  "9a IN  NS  $NAME." $REV
        echo  "$HOST             IN  A           $IP_HOST" >>$NAME.zone
        echo  "$ARPA_IP3         IN  PTR         $HOST.$NAME." >>$REV
        [ $? -eq 0 ]&& echo -e "The $NAME config success1:\n$HOST       IN  A           $IP_HOST\n$ARPA_IP3         IN  PTR         $HOST.$NAME." 
fi
}
##Define Shell List A Function 
Add_A_List ()
{
if
       cd  $BND_VAR
       REV=`ls  *.rev`
       read -p  "Please  Insert Into Your Add Name ,Example 51cto.com :" NAME
       [ ! -e "$NAME.zone" ];then
       echo "The $NAME.zone File is not exist ,Please ADD $NAME.zone File :"
       Add_named ;
else 
       read -p "Please Enter List Name A NS File ,Example /tmp/name_list.txt: " FILE 
    if
       [ -e $FILE ];then
       for i in  `cat $FILE|awk '{print $2}'|sed "s/$NAME//g"|sed 's/\.$//g'`
       #for i in  `cat $FILE|awk '{print $1}'|sed "s/$NAME//g"|sed 's/\.$//g'`
do
       j=`awk -v I="$i.$NAME" '{if(I==$2)print $1}' $FILE`
       echo ----------------------------------------------------------- 
       echo "The $NAME.zone File is exist ,Please Enter insert NAME HOST ...."
       sleep 1
       ARPA_IP=`echo $j|awk -F. '{print $3"."$2"."$1}'`
       ARPA_IP2=`echo $j|awk -F. '{print $4}'`
       echo  "$i             IN  A           $j" >>$NAME.zone
       echo  "$ARPA_IP2      IN  PTR      $i.$NAME." >>$REV
       [ $? -eq 0 ]&& echo -e "The $NAME config success:\n$i      IN  A           $j\n$ARPA_IP2         IN  PTR         $i.$NAME." 
done
     else
       echo "The $FILE List File IS Not Exist .......,Please exit ..."
     fi
fi
}

##Define Shell Select Menu   
PS3="Please select Menu Name Config: "
select i in "自动安装Bind服务"  "自动初始化Bind配置" "添加解析域名"  "批量添加A记录" 
do
case   $i   in 
       "自动安装Bind服务")
       Install
;;
       "自动初始化Bind配置")
       Init_Config
;;
       "添加解析域名")
       Add_named
;;
       "批量添加A记录")
       Add_A_List
;;
       * )
       echo -----------------------------------------------------
       sleep 1
       echo "Please exec: sh  $0  { Install(1)  or Init_Config(2) or Add_named(3) or Add_config_A(4) }" 
;;
esac
done