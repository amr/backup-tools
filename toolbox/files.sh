#!/bin/sh
# Part of backup-tools
#
# Creates a single compressed archive of files, reading paths from stdin.
#

xargs tar --hard-reference -hczf $1.tar.gz && echo $1.tar.gz && exit 0
