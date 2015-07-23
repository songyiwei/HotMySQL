function ExecSQL () {
_SQL=$1
_DBName=$2
mysql -h"$DBIP" -P"$DBPort" -u"$DBUser" -p"$DBPasswd" $_DBName -e "$_SQL"
if [[ $? != 0 ]]; then
    echo "Fail"
fi
unset _SQL
unset _DBName
}

function DumpSQL () {
_DBName=$2
_Path=$1
mysqldump -h"$DBIP" -P"$DBPort" -u"$DBUser" -p"$DBPasswd" $_DBName > $_Path
if [[ $? != 0 ]]; then
    echo "Fail"
fi
unset _DBName
unset _Path
}
