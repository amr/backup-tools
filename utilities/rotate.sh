#!/bin/bash
# Part of backup-tools
#
# Rotates backup items - to be used on the remote backup server
#
# Usage: ./rotate.sh /path/to/backup/root PROJECTNAME [days to keep, you can also use w for week and m for months,
# 						       NOTE: Maximum values for w and m is 4. if you want more,
#						       you can always use any number of days]
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

# Time Stamp
WEEK="7"
MONTH="30"

# Keep
if [ -n "$3" ]; then
	KEEP="$3"
	case $KEEP in
		1w)
			KEEP="$WEEK"	
		;;
		2w)
			KEEP="`echo $WEEK *2 | bc`"
		;;
		3w)
			KEEP="`echo $WEEK *3 | bc`"
		;;
		4w)
			KEEP="`echo $WEEK *4 | bc`"
		;;
		1m)
			KEEP="$MONTH"
		;;
		2m)
			KEEP="`echo $MONTH *2 | bc`"
		;;
		3m)
			KEEP="`echo $MONTH *3 | bc`"
		;;
		4m)
			KEEP="`echo $MONTH *4 | bc`"
		;;
	esac
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
