#!/bin/sh
#!/usr/bin/env bash
ORGANIZATION=$1
APPLICATION=$2
PROD_IPADDRESS=$3
PRO_USERID=$4
PRO_PASSWORD=$5
PRO_PORT=$6
versioning_db=$7
versioning_table=$8
jenkins_path=$9

#bash jenkins_1.sh 'Exicom' 'xfusion_auth_engine' '192.168.1.104' 'root' 'Ttpl@123' '3307' 'xfusion_config' 'version_status' '/home/ttpl/.jenkins/workspace/xfusion_auth_demo'

# ORGANIZATION="Exicom"
# APPLICATION="Xfusion_Platform"
# IPADDRESS="192.168.1.122"
# USERID="developer"
# PASSWORD="admin@123"
# PORT="3306"
echo "ORGANIZATION		:$ORGANIZATION"
echo "APPLICATION		:$APPLICATION"
echo "PROD_IPADDRESS	:$PROD_IPADDRESS"
echo "PRO_USERID		:$PRO_USERID"
echo "PRO_PASSWORD		:$PRO_PASSWORD"
echo "PRO_PORT			:$PRO_PORT"
echo "versioning_db		:$versioning_db"
echo "versioning_table	:$versioning_table"
echo "jenkins_path		:$jenkins_path"


. ./deployement_1.sh


# bash jenkins_1.sh 'Exicom' 'Xfusion_auth' '192.168.1.75' 'root' 'Ttpl@123' '3307'
# bash jenkins_1.sh project_name module_name pro_ip pro_user pro_pass pro_port