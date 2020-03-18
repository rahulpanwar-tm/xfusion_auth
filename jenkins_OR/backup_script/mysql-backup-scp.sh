sshpass -p ttpl@123 ssh -t ttpl@192.168.1.34 'mkdir /home/ttpl/jenkins_backup_script'
sshpass -p "ttpl@123"  scp /home/ttpl/jenkins/mysql-backup.sh /home/ttpl/jenkins/mysql-import.sh  ttpl@192.168.1.34:/home/ttpl/jenkins_backup_script/
sshpass -p ttpl@123 ssh -t ttpl@192.168.1.34 'chmod -R 777 /home/ttpl/jenkins_backup_script/mysql-backup.sh'
sshpass -p ttpl@123 ssh -t ttpl@192.168.1.34 'chmod -R 777 /home/ttpl/jenkins_backup_script/mysql-import.sh'
