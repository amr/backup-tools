#!/bin/sh
$Suffix=$Prj_name.`date +%F`

# Create log file for the Project 
touch $Prj_name.log

# Files
echo $Prj_dirs | ./files.sh $Back_dir/$Prj_name.Files 2>/dev/null

# Monitor Files Status
if [ $? == 0 ]; then 
	echo " Your files have been backed up correctly " > $Prj_name.log
else 
	echo " something is wrong please check your Files configuration" > $prj_name.log
fi

# MySQL
env Prj_mysql_dbs="$Prj_mysql_dbs" Prj_mysql_user="$Prj_mysql_user" Prj_mysql_pass="$Prj_mysql_pass" Prj_name="$Prj_name" Back_dir="$Back_dir" ./mysql.sh

# Monitor DataBases Status
if [ $? == 0 ]; then 
	echo " your DataBase have been Backed up correctly " >> $Prj_name.log
else 
	echo " something is wrong please check your DataBase configuration" >> $prj_name.log
fi

# Compressing Results
cd $Back_dir && tar -czf $Suffix.tar.gz $Prj_name* && rm -rf `cat tempfile` tempfile 

# Check Backup size 
echo "your backup size is `ls -sh | sort -rn | head -1 | cut -d " " -f1`" >> $Prj_name.log

# Push
rsync -avzr -e ssh $Suffix.tar.gz "$Back_user"@"$Back_server":"$Remote_dir"

# Monitor Pushing files
if [ $? == 0 ]; then 
	echo " Your Backup have been sent correctly to $Back_server@$Remote_dir " >> $Prj_name.log
else 
	echo " Your Backup haven't reach the $Back_server Please contact the remote admin" >> $Prj_name.log
fi

# Sending log to Administrators
mail -s "$Prj_name.Backup log" $Admins < $Prj_name.log

exit 0
