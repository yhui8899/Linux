#!/bin/sh
#Automatic Backup Linux System Files
#Define Variable
SOURCE_DIR=(
    $*
)
TARGET_DIR=/data/backup/
YEAR=`date +%Y`
MONTH=`date +%m`
DAY=`date +%d`
WEEK=`date +%u`
FILES=system_backup.tgz
CODE=$?
if
    [ -z "$*" ];then
    echo -e "Please Enter Your Backup Files or Directories\n--------------------------------------------\nExample $0 /boot /etc ......"
    exit
fi
#Determine Whether the Target Directory Exists
if
    [ ! -d $TARGET_DIR/$YEAR/$MONTH/$DAY ];then
    mkdir -p $TARGET_DIR/$YEAR/$MONTH/$DAY
    echo "This $TARGET_DIR is Created Successfully !"
fi
#EXEC Full_Backup Function Command
Full_Backup()
{
if
    [ "$WEEK" -eq "7" ];then
    rm -rf $TARGET_DIR/snapshot
    cd $TARGET_DIR/$YEAR/$MONTH/$DAY ;tar -g $TARGET_DIR/snapshot -czvf $FILES `echo ${SOURCE_DIR[@]}`
    [ "$CODE" == "0" ]&&echo -e  "--------------------------------------------\nThese Full_Backup System Files Backup Successfully !"
fi
}
#Perform incremental BACKUP Function Command
Add_Backup()
{
   cd $TARGET_DIR/$YEAR/$MONTH/$DAY ;
if
    [ -f $TARGET_DIR/$YEAR/$MONTH/$DAY/$FILES ];then
    read -p "These $FILES Already Exists, overwrite confirmation yes or no ? : " SURE
    if [ $SURE == "no" -o $SURE == "n" ];then
    sleep 1 ;exit 0
    fi
#Add_Backup Files System
    if
        [ $WEEK -ne "7" ];then
        cd $TARGET_DIR/$YEAR/$MONTH/$DAY ;tar -g $TARGET_DIR/snapshot -czvf $$_$FILES `echo ${SOURCE_DIR[@]}`
        [ "$CODE" == "0" ]&&echo -e  "-----------------------------------------\nThese Add_Backup System Files Backup Successfully !"
   fi
else
   if
      [ $WEEK -ne "7" ];then
      cd $TARGET_DIR/$YEAR/$MONTH/$DAY ;tar -g $TARGET_DIR/snapshot -czvf $FILES `echo ${SOURCE_DIR[@]}`
      [ "$CODE" == "0" ]&&echo -e  "-------------------------------------------\nThese Add_Backup System Files Backup Successfully !"
   fi
fi
}
Full_Backup;Add_Backup
