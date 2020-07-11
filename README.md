Ensemble de scripts pour automatiser le fonctionnement des bases postgres avec une primaire et une ou plusieurs hot standby
Ce système se repose sur de la réplication inhérente à postgresql et pgpool-II

Il faut placer le failover.sh et le followmaster.sh sous /etc/pgpool-II
et configurer la commande dans le pgpool.conf.

Les scripts se basent sur des variables d'environnements suivantes :
BASE=postgres
l'endroit où on trouve les scripts : SCRIPT=/var/lib/pgsql/script
le user avec lequel les scripts vont se connecter aux bases : USER=postgres
l'IP virtuelle utilisée par pgpool-II : DELEGATE_IP=10.172.236.140
la racine de la base de donnée : PGDATA=/app/db/postgres/data
l'emplacement des binaires postgres : PGBIN=/usr/pgsql-10/bin/
l'endroit où on trouve le pcpassfile pour les connexions : PCPPASSFILE=/var/lib/pgsql/.pcppass
l'endroit où onn trouve le pgpass pour les connexions distantes sans password : PGPASSFILE=/var/lib/pgsql/.pgpass

NB : l'utilisation de pgpool impose une contrainte, les requêtes commencant par un SELECT mais comportant des INSERT UPDATE ou DELETE
doivent commencer par un commentaire /*NO LOAD BALANCE*/ ainsi elles s'exécutent automatiquement sur la primaire.

Pour le fonctionnement des hot standby je vous conseille de paramétrer hot_standby_feedback à on

Pour le fonctionnement du système pgpool, paramétrez un nombre conséquent de connexions dans postgres et pgpool 
avec un nombre réservé de connexions admin et en mettant l'utilisateur pgpool superuser.
Si l'application remplit le pool de connexion postgres, pgpool ne pourra pas se connecter pour vérifier et risque de provoquer
des bascules intempestives.
J'en ai fais l'experience, mais comme mes scripts resynchronisait à chaque fois les bases il y a eu 28 failovers en une apres midi
sans que les utilisateurs ne s'aperçoivent de rien.
