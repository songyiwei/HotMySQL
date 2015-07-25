function Recovery () {
_YMD=$1
_Time=$2

if [[ -! -f $DataPath/binlog.dat ]]; then
    echo ""
    echo "You must run init first !"
    exit 1
fi

date +%s --date="$_YMD $_Time" 1>/dev/null
if [[ $? != 0 ]]; then
    echo ""
    echo "Data format is wrong !"
    exit 1
fi

_Date=`cat $DataPath/binlog.dat | grep "^$_YMD" | tail -n 1 | awk -F"|" '{print $1}'`
_Row=`cat $DataPath/binlog.dat | grep -n "^$_YMD" | tail -n 1`
_BakSecondCount=`date +%s --date="$_Date"`

_InputSecondCount=`date +%s --date="$_YMD $_Time"`
_InputDate=`date +%y%m%d%H%M%S --date="@$_InputSecondCount"`

if [[ $_BakSecondCount > $_InputSecondCount ]]; then
    if [[ $_Row != 1 ]]; then
        _Row=$(($_Row-1))
    else
        echo ""
        echo "Recovery fail ! Cannot find full of backup before $_YMD $_Time !"
        exit 1
    fi
fi
_FullBakName=`sed -n ${_Row}p |  awk -F"|" '{print $2}'`
if [[ $_BakSecondCount == $_InputSecondCount ]]; then
    _BinLogName=""
else
    _BinLogName=`sed -n ${_Row}p |  awk -F"|" '{print $3}'`
fi

#需要判断中间的binlog是一个还是两个
#未完成

#if binlog count is 1
mysqlbinlog --stop-datetime="$_YMD $_Time" /var/log/mysql/$_BinLogName > $TmpPath/${DBName}_binlog.sql
if [[ $? != 0 ]]; then
    echo ""
    echo "Export binlog before $_YMD $_Time faild !"
    exit 1
fi

_Result=`ExecSQL "create database ${DBName}_tmp"`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | create tmp database  ${DBName}_tmp Faild !" | tee $LogPath/recovery
    exit 1
fi
unset _Result

_Result=`ExecSQL "source $_FullBakName" ${DBName}_tmp`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | source full backup to tmp database  ${DBName}_tmp Faild !" | tee $LogPath/recovery
    exit 1
fi
unset _Result

_Result=`ExecSQL "source $TmpPath/${DBName}_binlog.sql" ${DBName}_tmp`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | source binlog to tmp database  ${DBName}_tmp Faild !" | tee $LogPath/recovery
    exit 1
fi
unset _Result

_Result=`DumpSQL "$OutputPath/${DBName}_recovery_$_InputDate.sql" ${DBName}_tmp`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | Dump tmp database  ${DBName}_tmp Faild !" | tee $LogPath/recovery
    exit 1
else
    echo ""
    echo "$NowDate | Recovery to $_YMD $_Time is OK ! $OutputPath/${DBName}_recovery_$_InputDate.sql" | tee $LogPath/recovery
fi
unset _Result

unset _YMD _Time _Date _Row _BakSecondCount _InputSecondCount _InputDate _FullBakName _BinLogName

ExecSQL "drop database ${DBName}_tmp"& 1>/dev/null 2>&1
}
