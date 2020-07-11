#/bin/bash
. /var/lib/pgsql/.bash_profile
export LOCAL_IP=`ifconfig |grep inet |grep netmask |head -1 |awk '{print $2}' `
export PRIMARY_IP=`$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep primary |awk '{print $3}' `
export NUM_NODE=`$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep $LOCAL_IP |awk '{print $1}' `

if [ -f $PGDATA/postmaster.pid ]
then
 $PGBIN/pg_ctl stop -D $PGDATA
 sleep 10
fi
$SCRIPT/reinstate.sh
exit 0
