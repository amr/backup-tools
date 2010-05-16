#!/bin/bash
# Part of backup-tools
#
# Makes a backup of a given project
#
# Usage:
#
#    ./make-project-backup.sh projects-conf/<project-name>
#
# Usage 2:
#
#    source projects-conf/<project-name>; ./make-project-backup.sh
#
# Avoid loops
test -z "$MAKE_PROJECT_BACKUP" || return;
MAKE_PROJECT_BACKUP="1"

# Read given project configuration, if any.
test -a "$1" && source "$1"

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
	echo -ne "From: \"Backup Tools\" <noreply@`hostname`>\r\nSubject: $1: $PROJECT_NAME backup report for `date +%F`\r\n\r\n" | cat - $LOG | /usr/sbin/sendmail $PROJECT_OWNERS
}

# Validate run environment
function validate() {
	REQUIRED_VARS=(PROJECT_NAME PROJECT_PATHS PROJECT_MYSQL_DATABASES LOCAL_BACKUP_DIRECTORY REMOTE_BACKUP_HOST REMOTE_BACKUP_USER REMOTE_BACKUP_DIRECTORY)
	for var in ${REQUIRED_VARS[@]}; do
		value=$(eval echo $`echo $var`)
		test -n "$value" || fatal_error "$var is empty"
	done

	# MySQL
	if [[ "$PROJECT_MYSQL_DATABASES" != "none" && -z "$MYSQL_USER" ]]; then
		fatal_error "MYSQL_USER is empty"
	fi

	# Project paths
	test "$PROJECT_PATHS" != "none" && for path in $PROJECT_PATHS; do
		test -a "$path" || fatal_error "Invalid file or directory specified in PROJECT_PATHS: $path"
	done

	# Local backup directory
	test -d "$LOCAL_BACKUP_DIRECTORY" || fatal_error "Invalid directory specified for LOCAL_BACKUP_DIRECTORY: $LOCAL_BACKUP_DIRECTORY"
}

# Encryption
encrypt () {
	case $ENCRYPT in
		files)
			info "Encrypting $PROJECT_NAME.files"
			$(toolbox/encrypt.sh $FILES)
		;;
		databases)
			info "Encrypting $PROJECT_NAME.databases" 
			$(toolbox/encrypt.sh $DATABASES)
		;;
		both)
			info "Encrypting $PROJECT_NAME databases & files"
			$(toolbox/encrypt.sh $FILES)
			$(toolbox/encrypt.sh $DATABASES)
		;;
		none)
			info "Encryption is not enabled, continuing without encrypting"
		;;
	esac
}

###
# Validation
validate

####
# Unique ID for today's backup
BACKUP_ID="$PROJECT_NAME.`date +%F.%s`"
info "Backup ID: $BACKUP_ID"

###
# Log
LOG="logs/$BACKUP_ID.log"
touch $LOG
LOG=$(readlink -f $LOG)

###
# Create the tmp directory
TMP_DIRECTORY="$LOCAL_BACKUP_DIRECTORY/tmp/$BACKUP_ID"
mkdir -p "$TMP_DIRECTORY"
cat > "$LOCAL_BACKUP_DIRECTORY/tmp/README.txt" <<EOF
This directory is used by backup-tools temporarily while preparing the files and databases. It automatically creates it and is normally empty unless backup-tools was interrupted manually or failed for other reasons, in which case manual cleanup is required. It is safe to delete all the contents of this directory including this file.
EOF

###
# Backup files
if [ "$PROJECT_PATHS" != "none" ]; then
	FILES=$(echo "$PROJECT_PATHS" | toolbox/files.sh "$TMP_DIRECTORY/$PROJECT_NAME.files")
	if [ $? == 0 ]; then 
		info "Successfully prepared files"
	else
		fatal_error "Could not backup your files. Please check your project configuration"
	fi
else
	FILES=""
	info "No files or directories are set to be backed up"
fi

###
# Backup MySQL
if [ "$PROJECT_MYSQL_DATABASES" != "none" ]; then
	DATABASES=$(env PROJECT_MYSQL_DATABASES="$PROJECT_MYSQL_DATABASES" MYSQL_USER="$MYSQL_USER" MYSQL_PASSWORD="$MYSQL_PASSWORD" MYSQL_HOST="$MYSQL_HOST" MYSQLDUMP_OPTS="$MYSQLDUMP_OPTS" PROJECT_NAME="$PROJECT_NAME" TMP_DIRECTORY="$TMP_DIRECTORY" toolbox/mysql.sh)
	if [ $? == 0 ]; then 
		info "Successfully prepared database(s)"
	else
		fatal_error "Could not backup your database(s). Please check your project configuration"
	fi
else
	info "No MySQL databases are set to be backed up"
fi

###
# Encrypt the backup 
encrypt
###

# Create backup package
case  $ENCRYPT in 
	none)
		cd "$LOCAL_BACKUP_DIRECTORY" && mkdir -p "$PROJECT_NAME/$BACKUP_ID" && mv $FILES $DATABASES "$PROJECT_NAME/$BACKUP_ID/"
		if [ $? == 0 ]; then 
			info "A snapshot of your project files + database(s) has been correctly prepared"
		else
			fatal_error "Could not prepare a final snapshot. Please check your project configuration"
		fi
		;;
	files)
		cd "$LOCAL_BACKUP_DIRECTORY" && mkdir -p "$PROJECT_NAME/$BACKUP_ID" && mv $FILES.gpg $DATABASES "$PROJECT_NAME/$BACKUP_ID/"
		if [ $? == 0 ]; then 
			info "A snapshot of your encrypted project files + database(s) has been correctly prepared"
		else
			fatal_error "Could not prepare a final snapshot. Please check your project configuration"
		fi
		;;
	databases)
		cd "$LOCAL_BACKUP_DIRECTORY" && mkdir -p "$PROJECT_NAME/$BACKUP_ID" && mv $FILES $DATABASES.gpg "$PROJECT_NAME/$BACKUP_ID/"
		if [ $? == 0 ]; then 
			info "A snapshot of your project files + encrypted database(s) has been correctly prepared"
		else
			fatal_error "Could not prepare a final snapshot. Please check your project configuration"
		fi
		;;
	both)
		cd "$LOCAL_BACKUP_DIRECTORY" && mkdir -p "$PROJECT_NAME/$BACKUP_ID" && mv $FILES.gpg $DATABASES.gpg "$PROJECT_NAME/$BACKUP_ID/"
		if [ $? == 0 ]; then 
			info "A snapshot of your encrypted project files + encrypted database(s) has been correctly prepared"
		else
			fatal_error "Could not prepare a final snapshot. Please check your project configuration"
		fi
		;;
esac

###
# Clean up tmp directory
rmdir "$TMP_DIRECTORY" || fatal_error "Could not perform clean up actions. Please contact the backup administrator immediately"

###
# Report backup size
info "Total backup size is `du -hs $PROJECT_NAME/$BACKUP_ID | awk '{ print $1 }'`"

###
# Push to remote server
info "Starting to transfer the backup snapshot to the remote backup server"
rsync -av -e "$REMOTE_BACKUP_SHELL" "$PROJECT_NAME/$BACKUP_ID" "$REMOTE_BACKUP_USER"@"$REMOTE_BACKUP_HOST":"$REMOTE_BACKUP_DIRECTORY/$PROJECT_NAME/"
if [ $? == 0 ]; then 
	info "A backup of $PROJECT_NAME has been sent correctly to the backup server ($REMOTE_BACKUP_HOST) and stored as: $REMOTE_BACKUP_DIRECTORY/$PROJECT_NAME/$BACKUP_ID"
else 
	fatal_error "Your backup didn't reach the backup server. Please contact the backup administrator immediately"
fi

# Send report
info "Sending backup log to: $PROJECT_OWNERS"
mail_report "Success"

exit 0
