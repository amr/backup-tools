#!/bin/bash
###############################################
# EDC Files Backup Script 
# Author : Ahmad Saif <ahmed.saif@egyptdc.com>
################################################
. files.conf	#read the config
LOG="$basedir/backup.log"	#log file
ERR="$basedir/backup_error.log" #erro log file
suffix=`date +%F`		#extend the files names with time stamp and other things 
#redirect output and errores 
touch $LOG	    		# create log file
exec 6>&1           		# Link file descriptor #6 with stdout.
                    		# Saves stdout.
exec > $LOG         		# stdout replaced with file $LOGFILE.
touch $ERR	    		# create error log file
exec 7>&2           		# Link file descriptor #7 with stderr.
                    		# Saves stderr.
exec 2> $ERR        		# stderr replaced with file $LOGERR.
lockfile="$basedir/backup.lock"	# Create lock file to prevent multi run 
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
if [ ! -d "$basedir" ]; then
	echo "Creating the BASE DIRECTORY $basedir"
	mkdir -p "$basedir"
fi
# check for The local backup directory and create it 
if [ ! -d "$basedir/local" ]; then
        echo "Creating $basedir/local..."
        mkdir "$basedir/local"
fi
#################
##Check Status
#################
#checking if today backup exist 
todayback=$basedir/local/$backupname-$suffix.$archext
if [ -s $todayback ]; then
	echo "Backup for today `date +%F` have been done .. will exit" && exit 1
else 
	echo "Nothing have been backedup yet, procceding to backup"
fi
#checking for already running process 
if [ ! -e "$lockfile" ]; then
	touch "$lockfile"
else 
	echo "Backup is already running" && exit 1
fi
#check for The work directory and create it 
if [ ! -d "$basedir/work" ]; then
	echo "Creating $basedir/work..." 
	mkdir "$basedir/work"
fi
#redirect output and errores 
touch $LOG                      # create log file
exec 6>&1                       # Link file descriptor #6 with stdout.
                                # Saves stdout.
exec > $LOG                     # stdout replaced with file $LOGFILE.
touch $ERR                      # create error log file
exec 7>&2                       # Link file descriptor #7 with stderr.
                                # Saves stderr.
exec 2> $ERR                    # stderr replaced with file $LOGERR.
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

########################################################
## Move the tars to the storage folder && linking latest  
########################################################
## Moving Files
echo "Moving Files to the Final destination .."
mv $backupname-$suffix.$archext $basedir/local
####Linking####
##check for the latest directroy
if [ ! -d $basedir/latest ]; then
	echo "Creating latest directory .."
	mkdir -p $basedir/latest
fi
##link the files
ln -sf "$basedir/local/$backupname-$suffix.$archext" "$basedir/latest/$backupname-$suffix.$archext"
##################
## Rotating Files 
##################
#rotating backups
ls "$basedir/local" | sort -rn | sed -e ''1,"$keep"d'' | xargs -i rm -rf {}
#rotating links
ls "$basedir/latest" | sort -rn | sed -e ''1,"$keep"d'' | xargs -i rm -rf {}
######################
## Clean up temp files
######################
echo "Cleaning up the temprory files .."
rm -rf $basedir/work
#Clean up IO redirection
exec 1>&6 6>&-      # Restore stdout and close file descriptor #6.
exec 1>&7 7>&-      # Restore stdout and close file descriptor #7.

###Check for status and relase the lock file
if [ $? == 0 ]; then
	rm -rf $lockfile
	mail -s "Backup Done!" $admin < "$LOG"
else
	mail -s "!!Backup Failed!!" $admin < "$ERR"
fi
