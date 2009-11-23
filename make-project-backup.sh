#!/bin/bash
# Part of backup-tools
#
# Makes a backup for a given project configuration
#
# Usage:
#
#    ./make-backup.sh projects-conf/<project-name>
#
# Usage 2:
#
#    source projects-conf/<project-name>; ./make-backup.sh
#

# Avoid loops
test -z "$MAKE_PROJECT_BACKUP" || return;
MAKE_PROJECT_BACKUP="1"

# Read given project configuration, if any.
test -a "$1" && cd `dirname "$1"` && source `basename "$1"`

# Print fatal error and exit
function fatal_error() {
	echo "[ERROR] $1" >&2
	# Log file might not be ready yet
	if [ -a "$LOG" ]; then
		echo "[ERROR] $1" >> $LOG
		mail_report "Failed"
	fi;
	exit 1;
}

# Print informational message
function info() {
	echo "[INFO] $1"
	# Log file might not be ready yet
	if [ -a "$LOG" ]; then
		echo "[INFO] $1" >> $LOG
	fi;
}

# Send out the e-mail notification
function mail_report() {
	mail -s "$PROJECT_NAME backup report for `date +%F`: $1" -a "From: Backup Tools <noreply@`hostname`>" $PROJECT_OWNERS < $LOG
}

# Validate run environment
function validate() {
	REQUIRED_VARS=(PROJECT_NAME PROJECT_DIRECTORIES PROJECT_MYSQL_DATABASES MYSQL_USER MYSQL_PASSWORD LOCAL_BACKUP_DIRECTORY REMOTE_BACKUP_HOST REMOTE_BACKUP_USER REMOTE BACKUP_DIRECTORY)
	for var in ${REQUIRED_VARS[@]}; do
		value=$(eval echo $`echo $var`)
		test -n "$value" || fatal_error "$var is empty"
	done;

	# Project directories
	for dir in $PROJECT_DIRECTORIES; do
		test -d "$dir" || fatal_error "Invalid directory specified in PROJECT_DIRECTORIES: $dir"
	done;
}

###
# Validation
validate

###
# Unique ID for today's backup
BACKUP_ID="$PROJECT_NAME.`date +%F.%s`"

###
# Log
LOG="logs/$BACKUP_ID.log"
touch $LOG
LOG=$(readlink -f $LOG)

###
# Backup files
FILES=$(echo "$PROJECT_DIRECTORIES" | toolbox/files.sh "$LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.files")
if [ $? == 0 ]; then 
	info "Successfully prepared files"
else 
	fatal_error "Could not backup your files. Please check your project configuration"
fi

###
# Backup MySQL
DATABASES=$(env PROJECT_MYSQL_DATABASES="$PROJECT_MYSQL_DATABASES" MYSQL_USER="$MYSQL_USER" MYSQL_PASSWORD="$MYSQL_PASSWORD" PROJECT_NAME="$PROJECT_NAME" LOCAL_BACKUP_DIRECTORY="$LOCAL_BACKUP_DIRECTORY" toolbox/mysql.sh)
if [ $? == 0 ]; then 
	info "Successfully prepared database(s)"
else 
	fatal_error "Could not backup your database(s). Please check your project configuration"
fi

###
# Create backup package
cd "$LOCAL_BACKUP_DIRECTORY" && mkdir "$BACKUP_ID" && mv $FILES $DATABASES "$BACKUP_ID/"
if [ $? == 0 ]; then 
	info "A snapshot of your project files + database(s) has been correctly prepared"
else 
	fatal_error "Could not prepare a final snapshot. Please check your project configuration"
fi

###
# Report backup size
info "Total backup size is `du -hs $BACKUP_ID | awk '{ print $1 }'`"

###
# Push to remote server
rsync -avzr -e ssh "$BACKUP_ID" "$REMOTE_BACKUP_USER"@"$REMOTE_BACKUP_HOST":"$REMOTE_BACKUP_DIRECTORY/$PROJECT_NAME/"
if [ $? == 0 ]; then 
	info "A backup of $PROJECT_NAME has been sent correctly to the backup server ($REMOTE_BACKUP_HOST) and stored as: $REMOTE_BACKUP_DIRECTORY/$PROJECT_NAME/$BACKUP_ID"
else 
	fatal_error "Your backup didn't reach the backup server. Please contact the backup administrator immediately"
fi

# Send report
info "Sending backup log to: $PROJECT_OWNERS"
mail_report "Success"

exit 0
