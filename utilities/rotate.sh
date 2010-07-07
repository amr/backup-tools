#!/bin/bash
# Part of backup-tools
#
# Rotates backup items - to be used on the remote backup server
#
# Usage: ./rotate.sh /path/to/backup/root PROJECTNAME [days, weeks or months to keep Example: 10 days]
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


## Calculate Date to get Keep Value 

DATE_TO_SECONDS () {
    date --utc --date "$1" +%s
}

DAY_IN_SECONDS=86400

KEEP_DATE (){
    
    DATE_1=$(DATE_TO_SECONDS $1)
    DATE_2=$(DATE_TO_SECONDS $2)
    DIFF_SECONDS=$((DATE_2-DATE_1))
    
    if ((DIFF_SECONDS < 0)); then
	 DEL_MINUS="-1"
    else 
	 DEL_MINUS="1"
    fi
    
    KEEP=$((DIFF_SECONDS/DAY_IN_SECONDS*DEL_MINUS))
}

# Keep
if [ -n "$3" ]; then

	KEEP_DATE "`date +%F`" ""`date -d "$3 ago" +%F`""
fi

# Project name
if [ -n "$2" ]; then
	PROJECT_NAME="$2"
fi

# Validate
test -d "$1" || fatal_error "Invalid directory: $1"

# Rotate!
cd $1; find $PROJECT_NAME -type d | head -n 1 | while read dir; do rotate $dir; done;
