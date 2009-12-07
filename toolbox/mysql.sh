#!/bin/sh
# Part of backup-tools
#
# Makes a backup copy of a MySQL database
#

# Prepare mysqldump args, this is needed to include only non-empty arguments.
MYSQLDUMP_OPTS=""
if [ -z "$MYSQL_USER" ]; then
	MYSQLDUMP_OPTS="$MYSQLDUMP_OPTS -u$MYSQL_USER"
fi;
if [ -z "$MYSQL_PASSWORD" ]; then
	MYSQLDUMP_OPTS="$MYSQLDUMP_OPTS -p$MYSQL_PASSWORD"
fi;

# Execute mysqldump on given databases
for db in $PROJECT_MYSQL_DATABASES;
	do mysqldump $MYSQLDUMP_OPTS $db | gzip > $LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz && echo $LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz;
done
