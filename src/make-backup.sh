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

# Read given project configuration, if any.
test -a "$1" && source "$1"

###
# Unique ID for today's backup
BACKUP_ID="$PROJECT_NAME.`date +%F.%s`"

###
# Log
LOG="logs/$BACKUP_ID.log"
touch $LOG
LOG=$(readlink -f $LOG)

# Print fatal error and exit
function fatal_error() {
	echo "[ERROR] $1" >&2
	echo "[ERROR] $1" >> $LOG
	mail_report "Failed"
	exit 1;
}

# Print informational message
function info() {
	echo "[INFO] $1" >> $LOG
	echo "[INFO] $1"
}

# Validate run environment
function validate() {
	REQUIRED_VARS=(PROJECT_NAME PROJECT_DIRECTORIES PROJECT_MYSQL_DATABASES MYSQL_USER MYSQL_PASSWORD LOCAL_BACKUP_DIRECTORY REMOTE_BACKUP_HOST REMOTE_BACKUP_USER REMOTE BACKUP_DIRECTORY)
	for var in ${REQUIRED_VARS[@]}; do
		test -n $`echo $var` || fatal_error "$var is empty"
	done;

	# Project directories
	for dir in $PROJECT_DIRECTORIES; do
		test -d "$dir" || fatal_error "Invalid directory specified in PROJECT_DIRECTORIES: $dir"
	done;
}

# Send out the e-mail notification
function mail_report() {
	mail -s "$PROJECT_NAME backup report for `date +%F`: $1" $PROJECT_OWNERS < $LOG
}

###
# Validation
validate

###
# Backup files
FILES=$(echo "$PROJECT_DIRECTORIES" | toolbox/files.sh "$LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.files")
if [ $? == 0 ]; then 
	info "Your files have been backed up correctly"
else 
	fatal_error "Something is wrong please check your Files configuration"
fi

###
# Backup MySQL
DATABASES=$(env PROJECT_MYSQL_DATABASES="$PROJECT_MYSQL_DATABASES" MYSQL_USER="$MYSQL_USER" MYSQL_PASSWORD="$MYSQL_PASSWORD" PROJECT_NAME="$PROJECT_NAME" LOCAL_BACKUP_DIRECTORY="$LOCAL_BACKUP_DIRECTORY" toolbox/mysql.sh)
if [ $? == 0 ]; then 
	info "Your DataBase have been Backed up correctly"
else 
	fatal_error "Something is wrong please check your DataBase configuration"
fi

###
# Create backup package
cd "$LOCAL_BACKUP_DIRECTORY" && mkdir "$BACKUP_ID" && mv $FILES $DATABASES "$BACKUP_ID/"
if [ $? == 0 ]; then 
	info "Your project has been backed up correctly"
else 
	fatal_error "Something is wrong please contact the backup administrator"
fi

###
# Report backup size
info "Your backup size is `du -hs $BACKUP_ID | awk '{ print $1 }'`"

###
# Push to remote server
#rsync -avzr -e ssh "$BACKUP_ID.tar.gz" "$REMOTE_BACKUP_USER"@"$REMOTE_BACKUP_HOST":"$REMOTE_BACKUP_DIRECTORY"
#if [ $? == 0 ]; then 
#	info "Your Backup have been sent correctly to the backup server ($REMOTE_BACKUP_HOST) "
#else 
#	fatal_error "Your backup didn't reach the backup server. Please contact the backup administrator"
#fi

# Send report
info "Sending backup log to: $PROJECT_OWNERS"
mail_report "Success"

exit 0
