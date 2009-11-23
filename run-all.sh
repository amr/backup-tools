#!/bin/sh
# Part of backup-tools
#
# Executes the backup procedure for all projects configured under
# projects-conf/ directory.
#

run-parts `dirname $0`/projects-conf
