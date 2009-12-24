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

if [ -z "$1" ]; then
	# Execute without sleeping between each project
	run-parts `dirname $0`/projects-conf
else
	# Validate
	echo $1 | grep -q '^[0-9]\+$' || fatal_error "Invalid sleep interval given: $1 (numeric number of seconds expected)"

	# Execute
	retval=0
	for conf in $(run-parts --test $(dirname $0)/projects-conf); do $conf || retval=1; sleep $1; done
	exit $retval
fi
