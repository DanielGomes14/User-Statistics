
#-----Variaveis globais-----
fileA=""
fileB=""
a=()
b=()
tempFinal=()
final=()
ordenador="sort"
flag=0;
#--------funçoes------------
function usage (){
    echo "Options Error! "
    echo ' OPTION                   Description                   '
    echo ' Sorting : '
    echo "          -r:             Sort all data in reverse order"
    echo "          You can not use more than 1 option from these:"
    echo ' '
    echo "          -n:             Sort by number of sessions"
    echo "          -t:             Sort by total logged time"
    echo "          -a:             Sort by maximum logged time"
    echo "          -i:             Sort by minimum logged time"
   
}
function verifyflag(){
    if [[  $flag -eq 1 ]]; then
            echo "Error!You can't use option 'n' with option 't','a' or 'i'"
            exit 1
        fi
}
mfcalculations () {
    indiceInicial=$1
    registoA=(${a[$indiceInicial]})
    if [[ ${#a[@]} -eq $indiceInicial ]]; then
        return 1
    fi
    if [[ " ${b[*]} " == *" ${registoA[0]} "* ]]; then
        for ((i=0;i<${#b[@]};i++)); do
            registoB=(${b[$i]})
            if [[ ${registoA[0]} == ${registoB[0]} ]]; then
                nome=${registoA[0]}
                nsessoes=$((${registoA[1]} - ${registoB[1]}))
                dtotal=$((${registoA[2]} - ${registoB[2]}))
                dmaxima=$((${registoA[3]} - ${registoB[3]}))
                dminima=$((${registoA[4]} - ${registoB[4]}))
                tempFinal+="$nome $nsessoes $dtotal $dmaxima $dminima "
            elif [[ ! s" ${a[*]} " == *" ${registoB[0]} "* ]] && [[ ! s" ${tempFinal[*]} " == *" ${registoB[0]} "* ]]; then
                tempFinal+="${registoB[@]} "
            fi
        done
    else
        tempFinal+="${registoA[@]} "
    fi

    mfcalculations $[$indiceInicial+1]
}
#---------Tratamento de Opçoes------------------
while getopts 'rntai' OPTION;do
	case "$OPTION" in
		r)
			ordenador="${ordenador} -r"
			;;
		n)
            verifyflag
		  	ordenador="${ordenador} -n -k2"	
            flag=1
			;;	
		t)
            verifyflag
			ordenador="${ordenador} -n -k3"	
            flag=1
			;;
		a)
            verifyflag
            flag=1;
			ordenador="${ordenador} -n -k4"	
			;;
		i)
            verifyflag
			ordenador="${ordenador} -n -k5"	
            flag=1
			;;
		\?)
         usage
         exit 0
      ;;
      		
	esac
done
shift "$(($OPTIND -1))" 
#----------Main----------------
if [[ ! $# -eq 2 ]]; then
    echo ""
    echo "#--------------- Invalid number of arguments ---------------#"
    echo ""
    exit
fi

if [[ $# -eq 2 ]]; then
    if [[ ! -f $1 || ! -f $2 ]]; then 
        echo "No file found!"
        exit
    fi
    fileA=$1
    fileB=$2
fi


while IFS= read line
do
	a+=("$line")
done <"$fileA"

while IFS= read line
do
	b+=("$line")
done <"$fileB"

mfcalculations 0
els=($(echo $tempFinal | tr " " "\n"))

for ((i=0;i<${#els[@]};i++)); do
    if (( $i % 5 == 0 )); then
        final+=("${els[$i]} ${els[$i+1]} ${els[$i+2]} ${els[$i+3]} ${els[$i+4]}")
    fi
done
    printf  "%s\n" "${final[@]}" | ${ordenador}





