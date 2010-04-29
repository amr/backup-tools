#!/bin/bash
#####################################################################
## encrypt: is part of backup tools 
##         used to encrypt the backup items with a password or a key
##         using Gnu Privacy Guard (gpg). 
##
## Requirements: gpg tools installed on your server 
##
## Author: Ahmad Saif <ahmed.saif@egyptdc.com>
##################################################################
###
# Load configuration files
	# Goto backup-tools root directory
if [ -n "$MAKE_PROJECT_BACKUP" ]; then
        # We are being run using `make-project-backup.sh`
         ROOT_DIR=`dirname "$0"`
else
        # We are being run directly
       ROOT_DIR=`dirname "$0"`/..
fi;
cd $ROOT_DIR
	# Read form the defualts
. projects-conf/defaults

###
# log error 
fatal_error () {
		echo "[ERROR] $1" >&2
		exit 1;
}

###
# Validate
test -f "$1" || fatal_error "$1 : is not a regular file"

# encrypt
encrypt () {
		if [ "$ENCRYPTION_TYPE" == "1" ]; then
				gpg -e -r $KEY_NAME $1 && rm -rf $1
			else
				echo $ENCRYPTION_PHRASE | gpg --passphrase-fd 0 ----cipher-algo $ALGORITHM -c < $1 > $1.gpg && rm -rf $1
		fi
}
encrypt $1
