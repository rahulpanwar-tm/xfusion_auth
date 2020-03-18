cd $6
VAR=$(ls -tr|tail -1)
## declare an array variable
declare -a arr=("$1" "$2")

delete_ary_elmt() {
  local word=$1      # the element to search for & delete
  local aryref="$2[@]" # a necessary step since '${!$2[@]}' is a syntax error
  local arycopy=("${!aryref}") # create a copy of the input array
  local status=1
  for (( i = ${#arycopy[@]} - 1; i >= 0; i-- )); do # iterate over indices backwards
    elmt=${arycopy[$i]}
    [[ $elmt == $word ]] && unset "$2[$i]" && status=0 # unset matching elmts in orig. ary
  done
  return $status # return 0 if something was deleted; 1 if not
}

delete_ary_elmt "no_database" arr


## now loop through the above array
for i in "${arr[@]}"
do
   echo "$i"
   # or do whatever with individual element of the array
gzip -d $6/$VAR/$i-$VAR.sql.gz
mysql -u $4 --host $3 --port $7 -p$5 $i < $6/$VAR/$i-$VAR.sql
done


# rp rp_tp 192.168.1.34 root Ttpl@123 /home/ttpl/jenkins/ 3306
# 1		2		3		4		5		6					7