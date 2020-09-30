Ensemble de scripts pour automatiser le fonctionnement des bases postgres avec une primaire et une ou plusieurs hot standby
Ce système se repose sur de la réplication inhérente à postgresql et pgpool-II

Prérequis :
-il faut avoir pgpool et postgresql d'installé
-il faut que le user 'postgres' par exemple puisse faire du ssh sans autentification sur l'ensemble des machines y compris de chaque machine sur elle même par exemple executer sur chaque machine :
  ssh-keygen -t rsa
  ssh-copy-id -i ~/.ssh/id_rsa.pub bbs-scppgp-p001
  ssh-copy-id -i ~/.ssh/id_rsa.pub bbs-scppgp-p002
  ssh-copy-id -i ~/.ssh/id_rsa.pub bbs-scppgp-p003
  ssh-copy-id -i ~/.ssh/id_rsa.pub bbs-scpbdd-p001
  ssh-copy-id -i ~/.ssh/id_rsa.pub bbs-scpbdd-p002
et vérifiez ssh postgres@bbs-scpbdd-p002 ls
-il faut que le user 'postgres' par exemple soit sudoer pour certaines commandes, exemple de la fin d'un visudo :
 postgres ALL=NOPASSWD: /sbin/ip
 postgres ALL=NOPASSWD: /sbin/arping
 postgres ALL=NOPASSWD: /bin/pgpool
-il faut qu'un bit s soit placé sur certains binaires :
 -rwsr-sr-x. 1 root root       23744 22 mai    2017 arping
 -rwsr-sr-x. 1 root root      466560  6 mars   2018 ip
 
Mise en place : 
Il faut placer le failover.sh et le followmaster.sh sous /etc/pgpool-II
et configurer la commande dans le pgpool.conf : failover_command = '/etc/pgpool-II/failover.sh %d %P %H %R'

Les scripts se basent sur des variables d'environnements suivantes :
BASE=postgres
l'endroit où on trouve les scripts : SCRIPT=/var/lib/pgsql/script
le user avec lequel les scripts vont se connecter aux bases : USER=postgres
l'IP virtuelle utilisée par pgpool-II : DELEGATE_IP=10.172.236.140
la racine de la base de donnée : PGDATA=/app/db/postgres/data
l'emplacement des binaires postgres : PGBIN=/usr/pgsql-10/bin/
l'endroit où on trouve le pcpassfile en droits 600 pour les connexions : PCPPASSFILE=/var/lib/pgsql/.pcppass
l'endroit où onn trouve le pgpass en droits 600 pour les connexions distantes sans password : PGPASSFILE=/var/lib/pgsql/.pgpass

Placez les scripts dans le $SCRIPT en droits 750, faites des tests de bascule de pools et de bases, adaptez au besoin.
Normalement la crontab d'automation bascule en même temps que la base primaire

NB : l'utilisation de pgpool impose une contrainte, les requêtes commencant par un SELECT mais comportant des INSERT UPDATE ou DELETE
doivent commencer par un commentaire /\* NO LOAD BALANCE \*/ ainsi elles s'exécutent automatiquement sur la primaire.

Pour le fonctionnement des hot standby je vous conseille de paramétrer hot_standby_feedback à on
Ca évite que le vacuum efface des enregistrements dont les standbys ont encore besoin pour certaines transactions

Pour le fonctionnement du système pgpool, paramétrez un nombre conséquent de connexions dans postgres et pgpool 
avec un nombre réservé de connexions admin et en mettant l'utilisateur pgpool superuser.
Si l'application remplit le pool de connexion postgres, pgpool ne pourra pas se connecter pour vérifier et risque de provoquer
des bascules intempestives.
J'en ai fais l'experience, mais comme mes scripts resynchronisait à chaque fois les bases il y a eu 28 failovers en une apres midi
sans que les utilisateurs ne s'aperçoivent de rien.
