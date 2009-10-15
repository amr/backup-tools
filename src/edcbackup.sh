#!/bin/bash
###########
## this is the global backup script it call's both scripts 
## The File Backup script .. and Mysql Backup Script 
###########
filepath=/home/ahmadsaif/backupedc.sh			# the File backup script path
sqlpath=			# the mysql backup script path

## call file backup 
sh $filepath
## call sql bakup
sh $sqlpath
