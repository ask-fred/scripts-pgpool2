#/bin/bash
. /var/lib/pgsql/.bash_profile
#ps -edf |grep automation.sh |grep -v grep
#if [ ! "$?" -eq 0 ]
#then
 export LOCAL_IP=`/usr/sbin/ifconfig |grep inet |grep netmask |head -1 |awk '{print $2}' ` #on récupèer l'IP locale
 $PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" # on fait un premier test car dans certains cas ca écoue et ca passe au 2eme
 sleep 5
 $PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" # si celui là échoue l'erreur est permanente et le problème plus serieux 
 if [ "$?" -eq 0 ] # si la commande précédente n'a pas échouée il n'y a pas de soucis
 then
  export PRIMARY_IP=`$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep primary|awk '{print $3}' ` #on repère la machine primaire dans le cas d'un reboot de primaire la crontab reste mais ne doit pas fonctionner en double
  if [ "$LOCAL_IP" == "$PRIMARY_IP" ] # si on est sur la primaire on exécute les commandes sinon non
  then
   for Machine in `pcp_watchdog_info -h $DELEGATE_IP -p 9898 -U $USER -w |grep SHUTDOWN |awk '{print $4}' ` # on vérifie si un pgpool a été arrêté
   do
    ssh $USER@$Machine ps -edf |grep 'pgpool.conf' |grep -v grep
    if [ ! "$?" -eq 0 ]
    then
     ssh -T $USER@$Machine rm /tmp/.s.PGSQL.9999 /tmp/.s.PGSQL.9898 # dans le cas d'un reboot sans arrêt de pgpool
     ssh -T $USER@$Machine pgpool -f /etc/pgpool-II/pgpool.conf # dans ce cas on le redémarre 
    else
     echo 'probleme avec le pool' > /tmp/pbpool
    fi
   done
   for Machine in `pcp_watchdog_info -h $DELEGATE_IP -p 9898 -U $USER -w |grep DEAD |awk '{print $2}' ` # on vérifie si un pgpool s'est crashé 
   do
    ssh -T $USER@$Machine rm /tmp/.s.PGSQL.9999 /tmp/.s.PGSQL.9898 # dans le cas d'un reboot sans arrêt de pgpool
    ssh -T $USER@$Machine pgpool -f /etc/pgpool-II/pgpool.conf # dans ce cas on le redémarre
   done
   for Machine in `$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep down |awk '{print $3}' ` # on vérifie l'état du pool de bases de données postgres et si une base est down
   do
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
   pcp_watchdog_info -h $DELEGATE_IP -p 9898 -U $USER -w |grep SHUTDOWN 
   if [ ! "$?" -eq 0 ]
   then 
    pcp_watchdog_info -h $DELEGATE_IP -p 9898 -U $USER -w |grep DEAD
    if [ ! "$?" -eq 0 ]
    then
     echo primaire est sur $PRIMARY_IP
     export PGPOOL_MAITRE=`pcp_watchdog_info -h $DELEGATE_IP -p 9898 -U $USER -w |grep MASTER |awk '{print $3}' `
     export IP_MAITRE=`nslookup $PGPOOL_MAITRE |grep '10.172.236.' |awk '{print $2}' `
     echo pool maitre est sur $IP_MAITRE
     if [ "$IP_MAITRE" == "$PRIMARY_IP" ]
     then
      pgpool -m f stop
     fi
    fi
   for Machine in `$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep quarant |awk '{print $3}' `
   do
    ssh -T $USER@$Machine crontab < $SCRIPT/crontab.standby # on assigne une crontab de standby à la nouvelle machine
     export NUM_NODE=`$PGBIN/psql -U $USER --host $DELEGATE_IP --port=9999 --dbname $BASE -c "show pool_nodes" |grep $Machine|awk '{print $1}' ` # on récupère le numero du node à réinstancier
     ssh -f $USER@$Machine -n "$SCRIPT/follow_master2.sh" # on reinstancie la base
     sleep 10 # on attend un peu pour la rattacher au pool
     ssh -T $USER@$Machine -n "pcp_attach_node -h $DELEGATE_IP  -p 9898 -U $USER -w -n $NUM_NODE" # on rattache la base au pool pgpool
   done
    fi
  else 
   echo je ne suis pas la primaire
  fi
 else
  echo probleme permanent de spool
 fi
 $SCRIPT/verif_bases.sh
#fi
