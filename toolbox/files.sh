#!/bin/sh
##############
#Tarring files
##############
xargs tar -czf $1.tar.gz 2>/dev/null && echo $1.tar.gz && exit 0
