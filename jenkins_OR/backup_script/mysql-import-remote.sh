#!/bin/sh
#!/usr/bin/env bash
# sshpass -p "ttpl@123"  ssh ttpl@192.168.1.34  'gzip -d /home/ttpl/jenkins_backup_script/$(ls -tr|tail -1)/rp-$(ls -tr|tail -1).sql.gz'
# $1 $2 	$3 					$4 		$5 		$6 			$7 	$8 		$9
# rp rp_tp /home/ttpl/jenkins/ ttpl@123 ttpl 192.168.1.34 root Ttpl@123 3306
echo $1 $2 $3 $4 $5 $6 $7 $8 $9
commcand="bash $3mysql-import.sh $1 $2 $6 $7 $8 $3 $9"
echo $commcand
sshpass -p $4  ssh $5@$6 $commcand