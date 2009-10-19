#!/bin/bash
###############################################
# EDC Files Backup Script 
# Author : Ahmad Saif <ahmed.saif@egyptdc.com>
#
# TODO:
#  * Use `mail` instead of `mutt`
#  * Rotate using timestamps comparison. Brainstorm:
#     ls | while read entry; do date=`echo $entry | cut -d'-' -f2-4 | cut -d'.' -f1`; date --date "$date" +%s | sort -n; done | head -n1 | awk '{ print strftime("%F", $0); }'
################################################

#############
## Variables
#############
basedir="/home/ahmadsaif/backup"			# Main backup directory [ Destination ]

backupname="projectname"		# Backup file name [ Project name ]

backupdir="/home/ahmadsaif/workspace"			# Directory to backup [ Source ]

#For how long do you want to keep the backups 
# days, weeks, months,etc keep="10 days"
keep="10 days"

# Archiver to use (bzip2 or gzip) prefare to be gzip
archiver="gzip"
#extend the files names with time stamp and other things 
suffix=`date +%F`
olddir=`date --date "$keep ago" +%F`
oldthing=$(cd "$basedir/local/" && ls | while read entry; do difdate=`echo $entry | cut -d'-' -f2-4 | cut -d'.' -f1`; date --date "$difdate" +%s | sort -n; done | head -n1 | awk '{ print strftime("%F", $0); }')
### notify admin
admin="somebody@egyptdc.com" # if more than one admin seperate e-mails with (,) 

#########################################################################
#########################################################################
## The main programe you don't need to edit under this line 
#########################################################################
#########################################################################
# Create lock file to prevent multi run 
lockfile="$basedir/backup.lock"
#create log file .. 
logfile="$basedir/backup.log"
# Create the extension for the archiver based on the Archiving type
if [ "$archiver" == "bzip2" ]; then
archext="bz2"
elif [ "$archiver" == "gzip" ]; then
archext="gz"
fi

###################################
## checking for working directories 
###################################

#check if the $basedir exists and create it.
if [ ! -e "$basedir" ]; then
echo "Creating the BASE DIRECTORY $basedir" >> $logfile
mkdir -p "$basedir"
fi

#check for The work directory and create it 
if [ ! -d "$basedir/work" ]; then
echo "Creating $basedir/work..." >> $logfile
mkdir "$basedir/work"
fi

# check for The local backup directory and create it 
if [ ! -d "$basedir/local" ]; then
echo "Creating $basedir/local..." >> $logfile
mkdir "$basedir/local"
fi

# Status 
if [ ! -d "$lockfile" ]; then
touch "$lockfile"
else echo "Backup is already running" && exit 1 >> $logfile
fi
################
## start copying
################ 

# use nice to be nice with the server :-)
echo "Copying files to work directory ..." >> $logfile
nice -n 19 cp -Rf "$backupdir" "$basedir/work"

# move to the work file and start Archiving nicley 
cd "$basedir/work"
echo "Tarring files..." >> $logfile
nice -n 19 tar -cf $backupname-$suffix.tar *
archext=tar.$archext
echo "Compressing files with $archiver..." >> $logfile
nice -n 19 $archiver -9f $backupname-$suffix.tar

######################################
## Move the tars to the storage folder 
######################################

echo "Moving Files to the Final destination " >> $logfile
mv $backupname-$suffix.$archext $basedir/local

## Delete the old stuff!
if [ -e "$basedir/local/$backupname-$oldthing.$archext" ]; then
	echo "Deleting old data..." >> $logfile
	rm -rf "$basedir/local/$backupname-$oldthing.$archext"
	echo "Deleting old links" >> $logfile
	rm -rf "$basedir/latest/$backupname-$suffix.$archext"
fi
## cleanup the temp files and exit
rm -rf $basedir/work
echo "Done!" >> $logfile
## Link the latest backup file
if [ ! -d $basedir/latest ]; then 
	echo "creating latest directory" >> $logfile
	mkdir -p $basedir/latest
fi
echo "Linking files" >> $logfile
## checking for previous created links 
if [ ! -d "$basedir/latest/$backupname-$suffix.$archext" ]; then 
	echo " Link is alreday existes some thing is wrong !!" >> $logfile
	echo " make sure that the old link is deleted" >> $logfile
else
ln -s "$basedir/local/$backupname-$suffix.$archext" "$basedir/latest/$backupname-$suffix.$archext"
fi
### check for status and relase the lock file 
if [ $? == 0 ]; then 
rm -rf $lockfile
echo "Backup for $backupname Done correctly at $suffix" | mutt -s "Backup Done !" $admin
else echo "Backup for $backupname Failed at $suffix" | mutt -s "!!Backup Failed!!" $admin
fi
