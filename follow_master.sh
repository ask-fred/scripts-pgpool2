#/bin/bash
. /var/lib/pgsql/.bash_profile
date > /tmp/follow_master2.log
$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" >> /tmp/follow_master2.log # on fait un premier test car dans certains cas ca écoue et ca passe au 2eme
sleep 5
$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" >> /tmp/follow_master2.log # si celui là échoue l'erreur est permanente et le problème plus serieux
if [ "$?" -eq 0 ] # si la commande précédente n'a pas échouée il n'y a pas de soucis
then
 for Machine in `psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep standby |awk '{print $3}' `
 do
  echo $Machine message envoyé >> /tmp/follow_master2.log
    ssh $USER@$Machine ls $PGDATA/sauvegarde # on envoie une commande ssh à la machine pour vérifier le flag de sauvegarde
    if [ "$?" -eq 0 ] # si il y a un flag de sauvegarde il est normal que la base soit à l'arrêt on ne fait rien
    then
      echo sauvegarde=OK
    else # si il n'y a pas de flag de sauvegarde on délègue la remise en état  au script local follow_master2.sh de la machine locale
     ssh -T $USER@$Machine crontab < $SCRIPT/crontab.standby # on assigne une crontab de standby à la nouvelle machine
     export NUM_NODE=`$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep $Machine|awk '{print $1}' ` # on récupère le numero du node à réinstancier
     ssh -f $USER@$Machine -n "$SCRIPT/follow_master2.sh" # on reinstancie la base
     sleep 10 # on attend un peu pour la rattacher au pool
     ssh -T $USER@$Machine -n "pcp_attach_node -h $DELEGATE_IP  -p 9898 -U $USER -w -n $NUM_NODE" # on rattache la base au pool pgpool
    fi
 done
else
 echo probleme de pool
fi
exit 0
