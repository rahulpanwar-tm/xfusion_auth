#!/bin/sh
#!/usr/bin/env bash
ORGANIZATION=$1
APPLICATION=$2
PROD_IPADDRESS=$3
PRO_USERID=$4
PRO_PASSWORD=$5
PRO_PORT=$6

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

. ./deployement_1.sh


# bash jenkins_1.sh 'Exicom' 'Xfusion_auth' '192.168.1.75' 'root' 'Ttpl@123' '3307'
# bash jenkins_1.sh project_name module_name pro_ip pro_user pro_pass pro_port