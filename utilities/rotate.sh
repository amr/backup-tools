#!/bin/bash
# Part of backup-tools
#
# Rotates backup items - to be used on the remote backup server
#
# Usage: ./rotate.sh /path/to/backup/root PROJECTNAME [days to keep]
#

# Default backup days to keep 
KEEP="30"

# Print fatal error and exit
function fatal_error() {
	echo "[ERROR] $1" >&2
	exit 1;
}

# Rotate entries in a given dir
rotate () {
        ls $1 | sort -rn | uniq | sed -e ''1,"$KEEP"d'' | while read backup; do test -n "$backup" && rm -rf $dir/$backup || return 1; done;
	return 0
}

# Keep
if [ -n "$3" ]; then
	KEEP="$3"
fi

# Project name
if [ -n "$2" ]; then
	PROJECT_NAME="$2"
fi

# Validate
test -d "$1" || fatal_error "Invalid directory: $1"
echo $KEEP | grep -q '^[0-9]\+$' || fatal_error "Invalid backup days to keep (numeric value expected): $KEEP"

# Rotate!
cd $1; find $PROJECT_NAME -type d | head -n 1 | while read dir; do rotate $dir; done;
