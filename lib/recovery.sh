function Recovery () {
YMD=$1
Time=$2

if [[ -! -f $DataPath/binlog.dat ]]; then
    echo ""
    echo "You must run init first !"
    exit 1
fi

date +%s --date="$YMD $Time" 1>/dev/null
if [[ $? != 0 ]]; then
    echo ""
    echo "Data format is wrong !"
    exit 1
fi

Date=`cat $DataPath/binlog.dat | grep "^$YMD" | tail -n 1 | awk -F"|" '{print $1}'`
Row=`cat $DataPath/binlog.dat | grep -n "^$YMD" | tail -n 1`
BakSecondCount=`date +%s --date="$Date"`

InputSecondCount=`date +%s --date="$YMD $Time"`
InputDate=`date +%y%m%d%H%M%S --date="@$InputSecondCount"`

if [[ $BakSecondCount > $InputSecondCount ]]; then
    if [[ $Row != 1 ]]; then
        Row=$(($Row-1))
    else
        echo ""
        echo "Recovery fail ! Cannot find full of backup before $YMD $Time !"
        exit 1
    fi
fi
FullBakName=`sed -n ${Row}p |  awk -F"|" '{print $2}'`
if [[ $BakSecondCount == $InputSecondCount ]]; then
    BinlogName=""
else
    BinlogName=`sed -n ${Row}p |  awk -F"|" '{print $3}'`
fi

NextRow=$(($Row+1))
NextBinlog=`sed -n ${NextRow}p |  awk -F"|" '{print $3}'`

BinlogPrefixion=`echo ${BinlogName%.*}`
BinlogNum=`echo $BinlogName | awk -F"." '{print $NF}'`
NextBinlogNum=`echo $NextBinlog | awk -F"." '{print $NF}'`
if [[ -n $NextBinlog ]]; then
    _Diff=$((${NextBinlogNum}-${BinlogNum}))
else
    _Diff=1
fi

for (( i=1;i<=$_Diff;i++ ))
do
    mysqlbinlog --stop-datetime="$YMD $Time" /var/log/mysql/${BinlogPrefixion}.`echo $_Diff | awk '{printf ("%010d\n",$1)}'` >> $TmpPath/${DBName}_binlog.sql
    if [[ $? != 0 ]]; then
        echo ""
        echo "Export binlog before $YMD $Time faild !"
        exit 1
    fi
done

_Result=`ExecSQL "create database ${DBName}_tmp"`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | create tmp database  ${DBName}_tmp Faild !" | tee $LogPath/recovery
    exit 1
fi
unset _Result

_Result=`ExecSQL "source $FullBakName" ${DBName}_tmp`
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

_Result=`DumpSQL "$OutputPath/${DBName}_recovery_$InputDate.sql" ${DBName}_tmp`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | Dump tmp database  ${DBName}_tmp Faild !" | tee $LogPath/recovery
    exit 1
else
    rm -rf $TmpPath/${DBName}_binlog.sql
    echo ""
    echo "$NowDate | Recovery to $YMD $Time is OK ! $OutputPath/${DBName}_recovery_$InputDate.sql" | tee $LogPath/recovery
fi
unset _Result
unset _Diff

ExecSQL "drop database ${DBName}_tmp"& 1>/dev/null 2>&1
}
