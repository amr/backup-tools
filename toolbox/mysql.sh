#!/bin/sh
# Part of backup-tools
#
# Makes a backup copy of a MySQL database
#

# Prepare mysql args, this is needed to include only non-empty arguments.
MYSQL_OPTS=""
if [ -n "$MYSQL_USER" ]; then
	MYSQL_OPTS="$MYSQL_OPTS -u$MYSQL_USER"
fi
if [ -n "$MYSQL_PASSWORD" ]; then
	MYSQL_OPTS="$MYSQL_OPTS -p$MYSQL_PASSWORD"
fi
if [ -n "$MYSQL_HOST" ]; then
	MYSQL_OPTS="$MYSQL_OPTS -h$MYSQL_HOST"
fi

# Check that the MySQL server at given host is alive and that the credentials
# are correct
mysqladmin $MYSQL_OPTS ping 2>&1 > /dev/null || exit 1

# Execute mysqldump on given databases
for db in $PROJECT_MYSQL_DATABASES;
	do mysqldump $MYSQLDUMP_OPTS $db | gzip > $TMP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz && echo $TMP_DIRECTORY/$PROJECT_NAME.DB-$db.sql.gz;
done
