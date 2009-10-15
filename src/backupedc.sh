#!/bin/bash
###############################################
# EDC Files Backup Script 
# Author : Ahmad Saif <ahmed.saif@egyptdc.com>
################################################

#############
## Variables
#############
basedir="/home/backup"			# Main backup directory [ Destination ]

backupname="projectname"		# Backup file name [ Project name ]

backupdir="/var/www/"			# Directory to backup [ Source ]

#For how long do you want to keep the backups 
# days, weeks, months,etc keep="10 days"
keep="10 days"

# Archiver to use (bzip2 or gzip) prefare to be gzip
archiver="gzip"
#extend the files names with time stamp and other things 
suffix=`date +%F`
olddir=`date --date "$keep ago" +%F`

### notify admin
admin="ahmed.saif@egyptdc.com" # if more than one admin seperate e-mails with (,) 

#########################################################################
#########################################################################
## The main programe you don't need to edit under this line 
#########################################################################
#########################################################################
# Create lock file to prevent multi run 
lockfile="$basedir/backup.lock"
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
echo "Creating the BASE DIRECTORY $basedir"
mkdir -p "$basedir"
fi

#check for The work directory and create it 
if [ ! -d "$basedir/work" ]; then
echo "Creating $basedir/work..."
mkdir "$basedir/work"
fi

# check for The local backup directory and create it 
if [ ! -d "$basedir/local" ]; then
echo "Creating $basedir/local..."
mkdir "$basedir/local"
fi

# Status 
if [ ! -d "$lockfile" ]; then
touch "$lockfile"
else echo "Backup is already running" && exit 1
fi
################
## start copying
################ 

# use nice to be nice with the server :-)
echo "Copying files to work directory ..."
nice -n 19 cp -Rf "$backupdir" "$basedir/work"

# move to the work file and start Archiving nicley 
cd "$basedir/work"
echo "Tarring files..."
nice -n 19 tar -cf $backupname-$suffix.tar *
archext=tar.$archext
echo "Compressing files with $archiver..."
nice -n 19 $archiver -9f $backupname-$suffix.tar

######################################
## Move the tars to the storage folder 
######################################
echo "Moving Files to the Final destination "
mv $backupname-$suffix.$archext $basedir/local

## Delete the old stuff!
if [ -e "$basedir/local/$backupname-$olddir.$archext" ]; then
	echo "Deleting old data..."
	rm -rf "$basedir/local/$backupname-$olddir.$archext"
fi
## cleanup the temp files and exit
rm -rf $basedir/work
echo "Done!"
### check for status and relase the lock file 
if [ $? == 0 ]; then 
rm -rf $lockfile
echo "Backup for $backupname Done correctly at $suffix" | mutt -s "Backup Done !" $admin
else echo "Backup for $backupname Failed at $suffix" | mutt -s "!!Backup Failed!!" $admin
fi
