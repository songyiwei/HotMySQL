function Backup () {
Mode=$1

#if tmp database is not exist then exit with status 1
_IsExist=`ExecSQL "show databases like '${DBName}_binlog'" ${DBName}_binlog`
if [[ $_IsExist == "Fail" ]]; then
    echo ""
    echo "$NowDate | tmp database ${DBName}_binlog is not exist !" | tee $LogPath/backup
    exit 1
fi
unset _IsExist

MasterStat=`ExecSQL "show master status \G"`
if [[ $MasterStat != "Fail" ]]; then
    #get binlog name
    NowLogName=`echo ${MasterStat##*\*} | awk '{print $2}'`
    #get position
    NowPos=`echo ${MasterStat##*\*} | awk '{print $4}'`
fi

if [[ ! -n $NowPos && ! -n $NowLogName ]]; then  
    echo ""
    echo "$NowDate | Get binlog status Faild !" | tee $LogPath/backup
    exit 1
fi

#to determine whether export
if [[ -f $DataPath/Position ]]; then
    LastPos=`cat $DataPath/Position`
else
    LastPos=""
fi        

if [[ $Mode == "auto" ]]; then
    _Result=`ExecSQL "flush logs"`
    if [[ $_Result == "Fail" ]]; then
        echo ""
        echo "$NowDate | Flush logs Faild !" | tee $LogPath/backup
        exit 1
    fi
    unset _Result
    if [[ -n $LastPos ]]; then
        mysqlbinlog --start-position=$LastPos /var/log/mysql/$NowLogName > $TmpPath/${DBName}_binlog_$NowDate.sql
        if [[ $? != 0 ]]; then
            _IsWrong=1
        fi
    else
        mysqlbinlog /var/log/mysql/$NowLogName > $TmpPath/${DBName}_binlog_$NowDate.sql
        if [[ $? != 0 ]]; then
            _IsWrong=1
        fi
    fi
    rm -rf $DataPath/Position
else
    if [[ -n $LastPos ]]; then
        mysqlbinlog --start-position=$LastPos --stop-position=$NowPos /var/log/mysql/$NowLogName > $TmpPath/${DBName}_binlog_$NowDate.sql
        if [[ $? != 0 ]]; then
            _IsWrong=1
        fi
    else
        mysqlbinlog --stop-position=$NowPos /var/log/mysql/$NowLogName > $TmpPath/${DBName}_binlog_$NowDate.sql
        if [[ $? != 0 ]]; then
            _IsWrong=1
        fi
    fi
    
fi

if [[ $_IsWrong == 1 ]]; then
    echo ""
    echo "$NowDate | Export binlog faild !" | tee $LogPath/backup
    exit 1
fi

#recovery binlog.sql to tmp database
_Result=`ExecSQL "source $TmpPath/${DBName}_binlog_$NowDate.sql" ${DBName}_binlog`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | Recovery tmp database ${DBName}_binlog faild !" | tee $LogPath/backup
    exit 1
else
    echo $NowPos > $DataPath/Position
fi
unset _Result

#backup tmp database to output
_Result=`DumpSQL "$OutputPath/${DBName}_$NowDate.sql" ${DBName}_binlog`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "$NowDate | Dump database ${DBName}_binlog faild !" | tee $LogPath/backup
    exit 1
else
    echo ""
    echo "$NowDate | Backup is OK ! $OutputPath/${DBName}_$NowDate.sql" | tee $LogPath/backup
fi
unset _Result
unset _IsWrong
}
