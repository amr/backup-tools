#!/bin/sh
###############
# Dumping the db
###############

# Test for credentials
# TODO: Check for existence of databases
#`mysql -u"$Prj_mysql_user" -p"$Proj_mysql_pass" -Bse 'status'` || exit 1

for db in $PROJECT_MYSQL_DATABASES;
	do mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $db | gzip > $LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz && echo $LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz >> tempfile;
done
