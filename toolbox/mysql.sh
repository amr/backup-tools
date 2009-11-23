#!/bin/sh
# Part of backup-tools
#
# Makes a backup copy of a MySQL database
#

for db in $PROJECT_MYSQL_DATABASES;
	do mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $db | gzip > $LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz && echo $LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz;
done
