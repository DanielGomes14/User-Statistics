#-----Variaveis globais-----
file="/var/log/wtmp"
a="last"
userstatsarray=()
indexuserstats=0
varsort="sort" 
argumentsarray=("$@")
flag=0
#-------Funçoes------------------
function usage (){
    echo "Options Error! "
    echo " Script Usage:"
    echo '       OPTION            Description                                                                              '
    echo '      -s "date":      Only shows sessions after "date". Put a correct date format!'
    echo '      -e "date":      Only shows sessions before "date"'
    echo '      -u "regex":    If the  regular expression matches the sessions, those will be displayed '
    echo '      -g "user group":Only shows sessions which belong to the users group "group"'
    echo '      -f "file":      Shows sessions only "file" '
    echo ' Sorting : '
    echo "          -r:             Sort all data in reverse order"
    echo "          You can not use more than 1 option from these:"
    echo ' '
    echo "          -n:             Sort by number of sessions"
    echo "          -t:             Sort by total logged time"
    echo "          -a:             Sort by maximum logged time"
    echo "          -i:             Sort by minimum logged time"
   
}


function getusers(){
column='$1'
findcolumn="| awk '{print $column}'"
optionsarr="${a} $findcolumn | sort |uniq"
userarr=($(eval $optionsarr))
}


function gettime(){
        tottime=0
        maxtime=0
        session=0
        firsthour=${timearr[0]};
        firsthour=$(echo ${firsthour:1:2}| awk  '{sub(/^0*/,"");}1')
        firsthour=$(echo ${firstminute}| tr --delete +)
        firstminute=${timearr[0]}
        firstminute=$(echo ${firstminute:4:2}| awk  '{sub(/^0*/,"");}1') 
        firstminute=$(echo ${firstminute}| tr --delete :)
        mintime=0
        let "mintime= firstminute + 60*firsthour"
        for time in ${timearr[@]}
        do
            lenghttime=${#time}
            if [[ lenghttime -eq 7 ]]
            then
                let "session = 0"
                min=${time:4:2}
                hour=${time:1:2}
                hour=$(echo $hour | awk  '{sub(/^0*/,"");}1') 
                min=$(echo $min | awk  '{sub(/^0*/,"");}1')
                let "session = min + 60*hour"   #tempo da sessao em causa
                let "tottime += min + 60*hour"  #tempo total
                if [[ session -gt maxtime ]]
                then
                    let "maxtime = session"                    
                fi
                if [[ session -lt mintime ]]
                then
                    let "mintime = session"
                fi
          #considerando os dias entre [1,9]...
            elif [[ lenghttime -eq 9 ]]
            then
                let "session = 0"
                day=${time:1:1}
                min=${time:6:2}
                hour=${time:3:2}
                day=$(echo $hour | awk  '{sub(/^0*/,"");}1') 
                hour=$(echo $hour | awk  '{sub(/^0*/,"");}1')
                min=$(echo $min | awk  '{sub(/^0*/,"");}1')
                let "session = min + 60*hour + day*24*60 "   #tempo da sessao em causa
                let "tottime += min + 60*hour + day*24*60"  #tempo total
                if [[ session -gt maxtime ]]
                then
                    let "maxtime = session"                    
                fi
                if [[ session -lt mintime ]]
                then
                    let "mintime = session"
                fi
        #caso haja uma sessao de tempo cujos numero de dias esteja entre [10,100[
            elif [[ lenghttime -eq 10 ]]
            then
                let "session = 0"
                day=${time:1:2}
                min=${time:7:2}
                hour=${time:4:2}
                day=$(echo $hour | awk  '{sub(/^0*/,"");}1') 
                hour=$(echo $hour | awk  '{sub(/^0*/,"");}1') 
                min=$(echo $min | awk  '{sub(/^0*/,"");}1')
                let "session = min + 60*hour + day*24*60 "   #tempo da sessao em causa
                let "tottime += min + 60*hour + day*24*60"  #tempo total
                if [[ session -gt maxtime ]]
                then
                    let "maxtime = session"                    
                fi
                if [[ session -lt mintime ]]
                then
                    let "mintime = session"
                fi    

            fi
      
        done
}


function processdata(){
    getusers
        for element in ${userarr[@]}
        do
                if [[ $element != "reboot" && $element != "wtmp" && $element != "shutdown" ]] 
            then

                numbersessions=$(last -f ${file} |grep -o $element | wc -l) 
                timearr=($(last -f ${file} | grep $element | awk '{if (( $10 !~ /in/ && $10 !~ /running/ )) { print $10 }}'  | tr " " " " ))
                for arg in ${argumentsarray[@]}
                do
                  if [ $arg == "-s" ] || [ $arg == "-e" ] 
                  then
                        
                        timerr=$($a -f ${file} | grep $element | grep -v 'no' | awk '{if (( $10 !~ /in/ && $10 !~ /running/ )) { print $10 }}'  | tr " " " ")
                        timearr=($timerr)
                        numbersessions=$($a -f ${file} |grep -o $element | wc -l)
                        break
                  fi      
                done
                gettime
    printsuserstats=$(echo $element $numbersessions $tottime $maxtime $mintime)
              #adicionar ao array....
    userstatsarray[$indexuserstats]=$printsuserstats
    indexuserstats=$((indexuserstats+1))
            fi
        done    
        if [[ ${#userstatsarray[@]} -eq 0 ]]; then
            echo "Something went wrong.No Data Found!"
            exit 1
        fi
}

function verifyflag(){
    if [[  $flag -eq 1 ]]; then
         echo  "Error!You can't use option 'n' with option 't','a' ou 'i'"
            exit 1
        fi

}

#-----------Processamento de Opçoes-------------------
while getopts 'e:g:s:u:f:rntai' OPTION; do 
  case "$OPTION" in
    g)
        g="$OPTARG"
        if  ! getent group $g >/dev/null 2>&1 ; then
              echo "Not possible to perform option '-g'  because there's no group associated with $g"
              exit 1
        
        else
        groupname=$(getent group $g |awk -F: '{print $1}') #get name of the group of $optarg
        usersarray=($(last -f ${file}| grep -v 'reboot\|wtmp' | awk '{print $1}' | sort | uniq)) #get all users
        arrayusersgroup=""
            for i in ${usersarray[@]}
              do
                if  id -ng $i >/dev/null 2>&1; then
                    groupuser=$(id -ng $i)         #check the group of each user , probably better ways to do than a for loop...
                if [[ $groupuser == $groupname && ${#arrayusersgroup} != 0 ]] ; then
                  arrayusersgroup+="\|" #regex to be able to do "grep" to multiple words at a time,however we dont want it on the last index, thats the reason of the if condition
                  arrayusersgroup+=$i
                elif [[ $groupuser == $groupname && ${#arrayusersgroup} == 0 ]] ; then
                  arrayusersgroup+=$i 
                fi
                  
                fi
              done
        a="${a} | grep '${arrayusersgroup}'"
        fi
        ;;
    s)
        if ! date -d "$OPTARG" "+%Y-%m-%d" >/dev/null 2>&1; then
          echo "Please insert a correct date format"
              exit 1;
        fi
        horas=${OPTARG:6}
        if [[ $horas == *":"* ]]; then
     
            total=$(date -d "$OPTARG" +"%Y-%m-%d%H:%M")
            a="${a} -s $total"
        else

            total=$(date -d "$OPTARG" +"%Y-%m-%d")
            a="${a} -s $total"
        fi
        ;;
	  e)
  
         if ! date -d "$OPTARG" "+%Y-%m-%d " >/dev/null 2>&1; then
          echo "Please insert a correct date format"
              exit 1;
        fi
        horas=${OPTARG:6}
        if [[ $horas == *":"* ]]; then
            total=$(date -d "$OPTARG" +"%Y-%m-%d%H:%M")
            a="${a} -t $total"
        else
            total=$(date -d "$OPTARG" +"%Y-%m-%d")
            a="${a} -t $total"
        fi

        ;;
    u)
        # se contiver apenas numeros nao e valido, utilizadores nao podem ter como nome apenas numeros
        if [[ -n ${OPTARG//[0-9]} ]] ; then
          u="$OPTARG"  
          a="${a} | grep '$u'"
        else 
          echo "Invalid! Make sure you didn't introduce only numbers!"
          exit 1
        fi  
        ;;
    f)
        if [[ ! -f $OPTARG ]]; then
          echo "The file introduced  does not not exist!"
          exit 1
        else
          f="$OPTARG"
          file=${f}
          a="${a} -f ${file}"
        fi
        ;;
    r)
        varsort=" ${varsort} -r" 
        ;;
    n)
        verifyflag
				varsort=" ${varsort} -n -k2"
        flag=1
        ;;
    t)
        verifyflag
        varsort=" ${varsort} -n -k3"
        flag=1
        ;;
    a)
         verifyflag
        varsort=" ${varsort} -n -k4"
        flag=1
        ;;
    i)
        verifyflag
        varsort="  ${varsort} -n -k5"
        flag=1
        ;;
    \?)
         usage
         exit 0
      ;;
    :)
      echo "Option -$OPTARG requires an argument to be executed!." >&2
      exit 1
      ;;
  esac
done

shift "$(($OPTIND -1))" 
processdata
#printf "Tamanho do array: %s\n" ${#userstatsarray[@]}
printf  "%-8s\n" "${userstatsarray[@]}" | ${varsort}

