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
ENCRYPTION_TYPE="KEY"
KEY_NAME="ahmad"
ENCRYPTION_PHRASE="iabtingan"
ALGORITHM="AES256"
fatal_error () {
		echo "[ERROR] $1" >&2
		exit 1;
}

# Validate
test -f "$1" || fatal_error "$1 : is not a regular file"

# encrypt
encrypt () {
		if [ "$ENCRYPTION_TYPE" == "KEY" ]; then 
				gpg -e -r $KEY_NAME $1
			else
				echo $ENCRYPTION_PHRASE | gpg --passphrase-fd 0 --cipher-algo $ALGORITHM -c < $1 > $1.gpg
		fi
}
encrypt $1
