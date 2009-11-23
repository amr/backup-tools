#!/bin/sh
# Part of backup-tools
#
# Creates a single compressed archive of files, reading paths from stdin.
#

xargs tar -czf $1.tar.gz 2>/dev/null && echo $1.tar.gz && exit 0
