#/bin/bash
. /var/lib/pgsql/.bash_profile
ps -edf |grep reinstate |grep -v grep
if [ ! "$?" -eq 0 ]
then
 $PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "show pool_nodes"
 sleep 5
 $PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "show pool_nodes"
 if [ ! "$?" -eq 0 ] # Si le pool rencontre un problème permanent il ne faut pas tenter de réinstancier
 then
  echo erreur permanente du pool
 else
  export PRIMARY_IP=`$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "show pool_nodes" |grep primary |awk '{print $3}' `
  export LOCAL_IP=`ifconfig |grep inet |grep netmask |head -1 |awk '{print $2}' `
  export NUM_NODE=`$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "show pool_nodes" |grep $LOCAL_IP |awk '{print $1}' `
  ps -edf |grep 'pgsql-10' |grep -v grep
  if [ "$?" -eq 0 ]
  then
   $PGBIN/pg_ctl stop -D $PGDATA
   cp $PGDATA/*.conf /app/db/postgres/config
   rm -rf $PGDATA/*

   $PGBIN/pg_basebackup -h $PRIMARY_IP -U postgres -w -D $PGDATA/ -R
   rm $PGDATA/pg_wal/00*
   $PGBIN/pg_ctl start -D $PGDATA
   pcp_attach_node -h $LOCAL_IP -p 9898 -U postgres -w -n $NUM_NODE &
  else
   cp $PGDATA/*.conf /app/db/postgres/config
   rm -rf $PGDATA/*

   $PGBIN/pg_basebackup -h $PRIMARY_IP -U postgres -w -D $PGDATA/ -R
   rm $PGDATA/pg_wal/00*
   $PGBIN/pg_ctl start -D $PGDATA
   pcp_attach_node -h $LOCAL_IP -p 9898 -U postgres -w -n $NUM_NODE &
  fi
 fi
fi
echo fin du script 
