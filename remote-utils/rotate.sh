#!/bin/bash
# Part of backup-tools
#
# Rotates backup items - to be used on the remote backup server
#
# Usage: ./rotate.sh /path/to/backup/root
#

# Backup entries to keep
KEEP="30"

# Print fatal error and exit
function fatal_error() {
	echo "[ERROR] $1" >&2
	exit 1;
}

# Rotate entries in a given dir
rotate () {
        ls $1 | sort -rn | cut -d '.' -f1,2 | uniq | sed -e ''1,"$KEEP"d'' | while read backup; do test -n "$backup" && rm -rf $dir/$backup* || return 1; done;
	return 0
}

# Validate
test -d "$1" || fatal_error "Invalid directory: $1"

# Rotate!
cd $1; find . -maxdepth 1 -type d | sed 1d | while read dir; do rotate $dir; done;
