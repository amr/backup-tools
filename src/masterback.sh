#!/bin/sh
$Suffix=$Prj_name.`date +%F`

# Files
echo $Prj_dirs | ./files.sh $Back_dir/$Prj_name.Files 2>/dev/null

# MySQL
env Prj_mysql_dbs="$Prj_mysql_dbs" Prj_mysql_user="$Prj_mysql_user" Prj_mysql_pass="$Prj_mysql_pass" Prj_name="$Prj_name" Back_dir="$Back_dir" ./mysql.sh

# Compressing Results
cd $Back_dir && tar -czf $Suffix.tar.gz $Prj_name* && rm -rf `cat tempfile` tempfile 

# Push
rsync -avzr -e ssh $Suffix.tar.gz "$Back_user"@"$Back_server":"$Remote_dir"
exit 0
