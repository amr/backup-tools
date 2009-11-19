#! /bin/sh
$Suffix=$Prj_name.`date +%F`
echo $Prj_name | files.sh $Back_dir/$Suffix
sh mysql.sh
`rsync -avzr -e "ssh -i "Rsync_key"" "$1" "$Back_user"@"$Back_server":"$Remote_dir"`
exit 0
