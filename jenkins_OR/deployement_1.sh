#!/bin/sh
#!/usr/bin/env bash

 # MESSAGE="hello"
 # IPADDRESS="192.168.1.122"
 # USERID="developer"
 # PASSWORD="admin@123"
 # PORT="3306"
 # echo "$MESSAGE"


#echo "What is your name?"
#read PERSON
#echo "Hello, $PERSON"
#declare -a Array50
#Array50=( "key1" "key2" "key3" "key4" "key5" "key6" "key7" "key8" "key9" "key10" )

echo "Deployement started for $APPLICATION under $ORGANIZATION"

#declare -a Array1
if [ "${array_pro[1]}" == "xfusion_performance_data" ]
then
for filename in $jenkins_path/xfusion_performance_data_node_*.sql; do
Array1=("${Array1[@]}" "$(basename "$filename")")
done
else
for filename in $jenkins_path/*.sql; do
Array1=("${Array1[@]}" "$(basename "$filename")")
done
fi

#echo "$items"

#array654=(/home/ttpl/shell_scripting/*.sql)

#echo ($array654)

#files=(/home/ttpl/shell_scripting/*.sql; ) for file in "${files[@]}" do filename="${file##*/}" filenameWithoutExtension="${filename%.*}" echo "$filenameWithoutExtension" done



#echo ${Array1[@]}
#echo ${Array50[@]}
#declare -p arr

#read -e -p "Enter your search string: " name
#echo "name: [$name]"
#declare -a arr
#arr=( $(awk /"$name"'/{print NR}' x ) )

#echo ${arr[0]}
#echo ${arr[*]}

#for filename in list  do
#   echo "$filename"

#done

#Array1=("${Array1[@]}" "$(basename "$filename")")
#list="11 22 33"
#x="batch_06102018.txt"

#for item in $list
#do
#    if [ "$x" == "$item" ]; then
#        echo "In the list"
#        exit
#    fi
#done

#patt=$1
#if [ -z "$patt" ] ; then echo "need an argument" ; exit 1 ; fi
#A=( $(awk '/^\[/ {p = 0};
#           /^\['"$patt"'\]/ {p=1; next}
#           p && !/^ *$/ ;' < servers )  )

#for x in "${A[@]}" ; do 
#    echo doing something with "$x" 
#done



#Array1=( "key1" "key2" "key3" "key4" "key5" "key6" "key7" "key8" "key9" "key10" )
#Array2=( "key1" "key2" "key3" "key4" "key5" "key6" )
#Array2=($(mysql -u$USERID --port $PORT  -p$PASSWORD -c -h $IPADDRESS   -Bse "use deployement_status; call deployement_status.database_deployement_version_get_all('Exicom','Xfusion_Platform');"))
#echo ${Array2[@]}

verisoning_table=($(mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -Bse "SELECT count(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME ='$versioning_table' and TABLE_SCHEMA='$versioning_db'  ;"))


echo "$verisoning_table"

#if [ "$verisoning_table" -le 0 ]
#then

#  mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -e "DROP TABLE IF EXISTS $versioning_db.$versioning_table;CREATE TABLE IF NOT EXISTS $versioning_db.$versioning_table (id int(11) NOT NULL AUTO_INCREMENT,project_name varchar(50) DEFAULT NULL,model_name varchar(50) DEFAULT NULL,script_name varchar(50) DEFAULT NULL,installation_date int(11) DEFAULT NULL,script_date int(11) DEFAULT NULL,PRIMARY KEY (id)) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"
#  echo "$verisoning_table"

# fi


#Array2=($(mysql -u$GLOB_USERID --port $GLOB_PORT  -p$GLOB_PASSWORD -c -h $GLOB_IPADDRESS   -Bse "use versioning; call versioning.database_deployement_version_get_all('$ORGANIZATION','$APPLICATION','$PROD_IPADDRESS');"))

Array2=($(mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -Bse "select trim(script_name) from $versioning_db.$versioning_table  where project_name='$ORGANIZATION' and model_name='$APPLICATION' order by script_date;"))

#mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -e "select * from $versioning_db.$versioning_table where project_name='$ORGANIZATION' and model_name='$APPLICATION' order by script_date;"





Array3=()
for i in "${Array1[@]}"; do
    skip=
    for j in "${Array2[@]}"; do
        [[ $i == $j ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || Array3+=("$i")
done
declare -a  Array3

echo "Array 1 " ${Array1[@]}
echo "Array 2 " ${Array2[@]}
echo "Array 3(diffrence) " ${Array3[@]}


echo "Diffrence in both array"

## now loop through the above array
for i in "${Array3[@]}"
do
   echo "$i"
   # or do whatever with individual element of the array
done


#runing code
#results=($(mysql -udeveloper -padmin@123 -c -h 192.168.1.122 -Bse "show databases;"))
#cnt=${#results[@]}                                                           
#echo $cnt
#for (( i=0 ; i<cnt ; i++ ))                                                    
#do echo "Record No. $i: ${results[$i]}"                                      
#done

echo "print diffrent version "



for i in "${Array3[@]}"
do
   #echo  "mysql -udeveloper -padmin@123 -c -h 192.168.1.122 -Bse $i" 
   mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -e "source $jenkins_path/$i;"
  
   if [ "$verisoning_table" -le 0 ]
then

  mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -e "DROP TABLE IF EXISTS $versioning_db.$versioning_table;CREATE TABLE IF NOT EXISTS $versioning_db.$versioning_table (id int(11) NOT NULL AUTO_INCREMENT,project_name varchar(50) DEFAULT NULL,model_name varchar(50) DEFAULT NULL,script_name varchar(50) DEFAULT NULL,installation_date int(11) DEFAULT NULL,script_date int(11) DEFAULT NULL,PRIMARY KEY (id)) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;"
  echo "$verisoning_table"

fi
   mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -e "INSERT INTO $versioning_db.$versioning_table (project_name,model_name, script_name, installation_date, script_date) VALUES ('$ORGANIZATION','$APPLICATION','$i',UNIX_TIMESTAMP(NOW()),unix_timestamp(substring(substring('$i' FROM -14),1,10)));"
   verisoning_table=($(mysql -u$PRO_USERID --port $PRO_PORT  -p$PRO_PASSWORD -c -h $PROD_IPADDRESS -Bse "SELECT count(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME ='$versioning_table' and TABLE_SCHEMA='$versioning_db'  ;"))
  # mysql -u$GLOB_USERID --port $GLOB_PORT  -p$GLOB_PASSWORD -c -h $GLOB_IPADDRESS -e "use versioning; call database_deployement_version_insert('$ORGANIZATION','$APPLICATION','$i');"
   # or do whatever with individual element of the array
done


echo "$MESSAGE"












