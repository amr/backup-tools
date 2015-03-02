#!/bin/bash
# Part of backup-tools
#
# Makes a backup copy of a MySQL database
#

# Prepare mysql args
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

MYSQL_CMD="mysql $MYSQL_OPTS"
MYSQLDUMP_CMD="mysqldump $MYSQLDUMP_OPTS $MYSQL_OPTS"

# Execute mysqldump on given databases
for db in $PROJECT_MYSQL_DATABASES;
	do
	  mkdir -p $TMP_DIRECTORY/$PROJECT_NAME.DB-$db
	  DUMP_TABLES=$(echo "SHOW TABLES" | $MYSQL_CMD $db | sed 1d | while read table
	    do
	      echo "SYSTEM $MYSQLDUMP_CMD $db $table > $TMP_DIRECTORY/$PROJECT_NAME.DB-$db/$table.sql;"
      done)

    STMTS="
    FLUSH TABLES WITH READ LOCK;
    SYSTEM echo \"SHOW MASTER STATUS\G\" | $MYSQL_CMD > $TMP_DIRECTORY/$PROJECT_NAME.DB-$db/00-master-status.txt;
    $DUMP_TABLES;
    UNLOCK TABLES;"

    echo $STMTS | $MYSQL_CMD

    for table in $TMP_DIRECTORY/$PROJECT_NAME.DB-$db/*.sql
      do bzip2 $table
    done

    echo $TMP_DIRECTORY/$PROJECT_NAME.DB-$db
done
