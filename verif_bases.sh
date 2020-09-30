#/bin/bash
. $HOME/.bash_profile

FICHIER_TMP=/tmp/synchro_des_bases

echo '' > $FICHIER_TMP

# Construction du corps du message si besoin

Reference=`$PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "/*NO LOAD BALANCE*/ SELECT txid_current_snapshot(); " |grep ':' `
for Machine in `$PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "show pool_nodes"|grep up |awk '{print $3}' `
do
Verif=`$PGBIN/psql -U $USER -h $Machine -p 5432 -d $BASE -c "SELECT txid_current_snapshot(); "|grep ':' `
test $Machine != $Reference && MESSAGE=' synchro ok '$Reference' '$Machine || MESSAGE=' synchro nok '$Reference' '$Verif' '$Machine
echo $MESSAGE >> $FICHIER_TMP
done

echo 'base primaire sur' > $HOME/primaire
$PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "show pool_nodes" |grep primary |awk '{print $3}' >> $HOME/primaire

$PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "show pool_nodes"|grep down > /tmp/bases_down
for Machine in `$PGBIN/psql -U $USER -h $DELEGATE_IP -p 9999 -d $BASE -c "show pool_nodes"|grep standby|awk '{print $3}' `
do
scp /tmp/synchro_des_bases $USER@$Machine:/tmp/synchro_des_bases
scp /tmp/bases_down  $USER@$Machine:/tmp/bases_down
scp $HOME/primaire $USER@$Machine:$HOME/primaire
done
