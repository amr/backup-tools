#!/bin/sh
$Suffix=$Prj_name.`date +%F`

# Files
echo $Prj_dirs | files.sh $Back_dir/$Suffix 2>/dev/null

# MySQL
env Prj_mysql_dbs="$Prj_mysql_dbs" Prj_mysql_user="$Prj_mysql_user" Prj_mysql_pass="$Prj_mysql_pass" Suffix="$Suffix" Back_dir="$Back_dir" mysql.sh

# Push
for i in $(cat tempfile);
rsync -avzr -e ssh $i "$Back_user"@"$Back_server":"$Remote_dir"
exit 0
