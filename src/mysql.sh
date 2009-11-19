#!/bin/sh
###############
#Dumping the db
###############
$Suffix=$Prj_name.`date +%F`
mysqldump -u$Prj_msql_user -p$Prj_mysql_pass $Prj_mysql_dbs | `gzip -9` > $Back_dir/$Suffix.sql.gz
exit 0
