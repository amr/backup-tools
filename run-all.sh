#!/bin/bash
# Part of backup-tools
#
# Executes the backup procedure for all projects configured under
# projects-conf/ directory, optionally sleeping for a given time between each
# project and the next one.
#
# Usage: ./run-all.sh <sleep-interval>
#

# Print fatal error and exit
function fatal_error() {
	echo "[ERROR] $1" >&2
	exit 1;
}

# Validate
if [ -n "$1" ]; then
	echo $1 | grep -q '^[0-9]\+$' || fatal_error "Invalid sleep interval given: $1 (numeric number of seconds expected)"
fi

# Execute
retval=0
for file in $(dirname $0)/projects-conf/*; do
	if [ -x $file ]; then
		$file || retval=1
		test -n "$1" && sleep $1
	fi	
done
exit $retval
