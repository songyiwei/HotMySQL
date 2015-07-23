function Init {

#Check /etc/mysql/my.cnf, if binlog is already used, then backup database and not edit my.cnf.
_IsUsed=`cat $DBCnf | grep -v "#" | grep "log_bin"`
if [[ -n $_IsUsed ]]; then
    echo ""
    echo "Binlog is already used !"
    exit 1
else
    sed -i "s/^#log_bin.*/log_bin = \/var\/log\/mysql\/$DBName-mysql-bin.log\nbinlog_format = MIXED/" $DBCnf
    sed -i "s/expire_logs_days.*/expire_logs_days = 7/" $DBCnf
    sed -i "s/max_binlog_size.*/max_binlog_size = 1024M/" $DBCnf
    sed -i "s/^#binlog_do_db.*/binlog_do_db = $DBName/" $DBCnf
fi

#stop MySQL
/etc/init.d/mysql stop 1>/dev/null
if [[ $? != 0 ]]; then
    echo ""
    echo "Stop service MySQL faild !"
    exit 1
fi

#start MySQL
/etc/init.d/mysql start 1>/dev/null
if [[ $? != 0 ]]; then
    echo ""
    echo "Start service MySQL faild !"
    exit 1
fi

create database tmp database
_Result=`ExecSQL "create database ${DBName}_binlog"`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "Create database ${DBName}_binlog faild !"
    exit 1
fi
unset _Result

#backup database
_Result=`DumpSQL "$TmpPath/${DBName}_$NowDate.sql" $DBName`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "Backup MySQL $DBName faild !"
    exit 1
fi
unset _Result

#recovery tmp database
_Result=`ExecSQL "source $TmpPath/${DBName}_$NowDate.sql" ${DBName}_binlog`
if [[ $_Result == "Fail" ]]; then
    echo ""
    echo "Recovery MySQL ${DBName}_binlog faild !"
    exit 1
else
    rm -rf $TmpPath/${DBName}_$NowDate.sql
fi
unset _Result

#build crontab
echo "$Crontab $BinPath/HotMySQL.sh auto" > $TmpPath/Crontab
crontab $TmpPath/Crontab
rm -rf $TmpPath/Crontab

echo ""
echo "Init MySQL binlog OK !"
unset _IsUsed
}
