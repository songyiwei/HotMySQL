#!/bin/bash

Param1=$1

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

GetDate

BinPath="$(cd `dirname $0`;pwd)"
TmpPath="$(cd `dirname $0`;pwd)/tmp"
DataPath="$(cd `dirname $0`;pwd)/data"
OutputPath="$(cd `dirname $0`;pwd)/output"
LogPath="$(cd `dirname $0`;pwd)/logs"

case $Param1 in
"init")
    Init
    ;;
"backup")
    Backup
    ;;
#"recovery")
#    Recovery
#    ;;
"auto")
    Backup auto
    ;;
#*)
#    Help
#    ;;
esac
