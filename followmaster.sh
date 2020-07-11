#! /bin/sh -x
new_primary=$1           # %H

pghome=/usr/pgsql-10
log=/var/log/pgpool/followmaster.log

date >> $log
echo $new_primary >> $log
su postgres -c "ssh -f postgres@$new_primary -n "/var/lib/pgsql/script/follow_master.sh > /tmp/follow_master.log""
if [ $? -eq 0 ]
then echo follow_master_NOK >> $log
else echo follow_master_OK >> $log
fi
exit 0;


