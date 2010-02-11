#!/bin/sh
# Part of backup-tools
#
# Creates a single compressed archive of files, reading paths from stdin.
#

xargs tar -cjf $1.tar.bz2 && echo $1.tar.bz2 && exit 0
