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
#
BACKUP_ID="$PROJECT_NAME.`date +%F.%s`"

###
# Log
#
LOG="$BACKUP_ID.log"

# Print fatal error and exit
function fatal_error() {
	echo "[ERROR] $1" >&2
	echo "[ERROR] $1" >> $LOG
	mail
	exit 1;
}

# Print informational message
function info() {
	echo "[INFO] $1"
	echo "[INFO] $1" >> $LOG
}

# Validate run environment
function validate() {
	REQUIRED_VARS=(PROJECT_NAME PROJECT_DIRECTORIES PROJECT_MYSQL_DATABASES MYSQL_USER MYSQL_PASSWORD LOCAL_BACKUP_DIRECTORY REMOTE_BACKUP_HOST REMOTE_BACKUP_USER REMOTE BACKUP_DIRECTORY)
	for var in ${REQUIRED_VARS[@]}; do
		test -n ${!$var} || fatal_error "$var is empty"
	done;

	# Project directories
	for dir in "$PROJECT_DIRECTORIES"; do
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
echo "$PROJECT_DIRECTORIES" | ./files.sh "$LOCAL_BACKUP_DIRECTORY/$PROJECT_NAME.files" 2>/dev/null
if [ $? == 0 ]; then 
	log "Your files have been backed up correctly"
else 
	fatal_error "Something is wrong please check your Files configuration"
fi

###
# Backup MySQL
env PROJECT_MYSQL_DATABASES="$PROJECT_MYSQL_DATABASES" MYSQL_USER="$MYSQL_USER" MYSQL_PASSWORD="$MYSQL_PASSWORD" PROJECT_NAME="$PROJECT_NAME" LOCAL_BACKUP_DIRECTORY="$LOCAL_BACKUP_DIRECTORY" ./mysql.sh
if [ $? == 0 ]; then 
	log "Your DataBase have been Backed up correctly"
else 
	fatal_error "Something is wrong please check your DataBase configuration"
fi

###
# Compressing Results
#
cd $LOCAL_BACKUP_DIRECTORY && tar -czf $BACKUP_ID.tar.gz $PROJECT_NAME* && rm -rf `cat tempfile` tempfile 

###
# Report backup size
log "Your backup size is `ls -sh | sort -rn | head -1 | cut -d " " -f1`"

###
# Push to remote server
rsync -avzr -e ssh "$BACKUP_ID.tar.gz" "$REMOTE_BACKUP_USER"@"$REMOTE_BACKUP_HOST":"$REMOTE_BACKUP_DIRECTORY"

# Monitor Pushing files
if [ $? == 0 ]; then 
	log "Your Backup have been sent correctly to the backup server ($REMOTE_BACKUP_HOST) "
else 
	fatal_error "Your backup didn't reach the backup server. Please contact the backup administrator"
fi

# Send report
mail

exit 0
