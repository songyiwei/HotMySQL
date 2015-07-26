#!/bin/bash

Param1=$1
Param2=$2
Param3=$3

if [[ $UID != 0 ]]; then
    echo ""
    echo "Need run as root !"
    exit 1
fi

cd `dirname $0`
if [[ -f config/mysql.cf ]]; then
    . config/mysql.cf
else
    echo ""
    echo "Cannot find config/mysql.cf !"
    exit 1
fi
. lib/sql.sh
. lib/getdate.sh
. lib/init.sh
. lib/backup.sh
. lib/recovery.sh

GetDate

BinPath="$(cd `dirname $0`;pwd)"
TmpPath="$(cd `dirname $0`;pwd)/tmp"
DataPath="$(cd `dirname $0`;pwd)/data"
OutputPath="$(cd `dirname $0`;pwd)/output"
LogPath="$(cd `dirname $0`;pwd)/logs"
DBDataPath=`cat $DBCnf | grep "^datadir" | awk '{print $3}'`
DBRunUser=`cat $DBCnf | grep "^user" | awk '{print $3}'`

case $Param1 in
"init")
    Init
    Backup
    ;;
"backup")
    Backup
    ;;
"recovery")
    Recovery $Param2 $Param3
    ;;
"auto")
    Backup auto
    ;;
#*)
#    Help
#    ;;
esac
