#/bin/bash
. /var/lib/pgsql/.bash_profile

FICHIER_TMP=/tmp/synchro_des_bases

echo '' > $FICHIER_TMP

# Construction du corps du message si besoin

Reference=`$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "/*NO LOAD BALANCE*/ SELECT txid_current_snapshot(); " |grep ':' `
for Machine in `$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "show pool_nodes"|grep up |awk '{print $3}' `
do
Verif=`$PGBIN/psql -U postgres --host $Machine --port=5432 --dbname postgres -c "SELECT txid_current_snapshot(); "|grep ':' `
test $Machine != $Reference && MESSAGE=' synchro ok '$Reference' '$Machine || MESSAGE=' synchro nok '$Reference' '$Verif' '$Machine
echo $MESSAGE >> $FICHIER_TMP
done

echo 'base primaire sur' > /var/lib/pgsql/primaire
$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "show pool_nodes" |grep primary |awk '{print $3}' >> /var/lib/pgsql/primaire
echo 'pool primaire sur' >> /var/lib/pgsql/primaire
pcp_watchdog_info -h 10.172.236.140 -p 9898 -U postgres -w |grep MASTER >> /var/lib/pgsql/primaire

$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "show pool_nodes"|grep down > /tmp/bases_down
for Machine in `$PGBIN/psql -U postgres --host $DELEGATE_IP --port=9999 --dbname postgres -c "show pool_nodes"|grep standby|awk '{print $3}' `
do
scp /tmp/synchro_des_bases postgres@$Machine:/tmp/synchro_des_bases
scp /tmp/bases_down  postgres@$Machine:/tmp/bases_down
scp /var/lib/pgsql/primaire postgres@$Machine:/var/lib/pgsql/primaire
done


