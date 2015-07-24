function Recovery () {
YMD=$1
Time=$2

if [[ -! -f $DataPath/binlog.dat ]]; then
    echo ""
    echo "You must run init first !"
    exit 1
fi
_Date=`cat $DataPath/binlog.dat | grep "^$YMD" | awk -F"|" '{print $1}'`
date +%s --date="$_Date"
}
