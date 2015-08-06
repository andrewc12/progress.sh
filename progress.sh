#!/bin/bash
#CMD="tail -n1 .progress | cut -d' ' -f1"
#Updates a display version of the variables
#The original script just reduced the accuracy of the actual variables
#test: -c 'date +"%s"' -t $(($(date +"%s") + 100))
#test negitave target: ./progress.sh -c 'echo $((0 - $(date +"%s")))' -t $((0 - $(date +"%s") - 100))


#http://www.linuxjournal.com/content/floating-point-math-bash
# Floating point number functions.

#####################################################################
# Default scale used by float functions.

#float_scale=2
float_scale=10


#####################################################################
# Evaluate a floating point number expression.

function float_eval()
{
    local stat=0
    local result=0.0
    if [[ $# -gt 0 ]]; then
        result=$(echo "scale=$float_scale; $*" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}


#####################################################################
# Evaluate a floating point number conditional expression.

function float_cond()
{
    local cond=0
    if [[ $# -gt 0 ]]; then
        cond=$(echo "$*" | bc -q 2>/dev/null)
        if [[ -z "$cond" ]]; then cond=0; fi
        if [[ "$cond" != 0  &&  "$cond" != 1 ]]; then cond=0; fi
    fi
    local stat=$((cond == 0))
    return $stat
}
#####################################################################




function displaynumpertime {
  #$(echo "scale=0; $C * 60 * 60 / 1" | bc -l)
  local RETURN=0
  local C=$1
#  local D=$((C*60*60*24))
  local D=$(echo "scale=0; $C * 60 * 60 * 24 / 1" | bc -l)
#  local H=$((C*60*60))
  local H=$(echo "scale=0; $C * 60 * 60 / 1" | bc -l)
#  local M=$((C*60))
  local M=$(echo "scale=0; $C * 60 / 1" | bc -l)
#  local S=$((C))
  local S=$(echo "scale=0; $C * 1 / 1" | bc -l)
  [[ $D -ge 1 ]] && RETURN=$(printf '%.2f/day ' $(float_eval "$C * 60 * 60 * 24 / 1"))
  [[ $H -ge 1 ]] && RETURN=$(printf '%.2f/hour ' $(float_eval "$C * 60 * 60 / 1"))
  [[ $M -ge 1 ]] && RETURN=$(printf '%.2f/minute ' $(float_eval "$C * 60 / 1"))
  [[ $S -gt 0 ]] && RETURN=$(printf '%.2f/second ' $(float_eval "$C * 1 / 1"))
  echo $RETURN
}
function displaytime {
  local T=$1
  local floatbackup=$float_scale
  float_scale=0
  local D=$(float_eval "$T/60/60/24")
  local H=$(float_eval "$T/60/60%24")
  local M=$(float_eval "$T/60%60")
  local S=$(float_eval "$T%60*1/1")
  [[ $D > 0 ]] && printf '%d days ' $D
  [[ $H > 0 ]] && printf '%d hours ' $H
  [[ $M > 0 ]] && printf '%d minutes ' $M
  [[ $D > 0 || $H > 0 || $M > 0 ]] && printf 'and '
  printf '%d seconds\n' $S
  local float_scale=$floatbackup
}








#http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
#output_file=""
#verbose=0
#finish=0
sleep=1

while getopts "c:t:s:" opt; do
    case "$opt" in
    c)  commandtoexec=$OPTARG
        ;;
    t)  finish=$OPTARG
        ;;
    s)  sleep=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

[ "$1" = "--" ] && shift

#echo "verbose=$verbose, output_file='$output_file', Leftovers: $@"


























#####CLEAN START
currentprog=$(eval $commandtoexec)
totalinc=0
ETA="???"
while [ true ]; do
  sleep $sleep
#start counter
previousprog=$currentprog
currentprog=$(eval $commandtoexec)
counter=$(($counter + 1))
#end counter
currentinc=$(float_eval "$currentprog - $previousprog")
totalinc=$(float_eval "$totalinc + $currentinc")
echo "currentinc $currentinc totalinc $totalinc"



currentincpertime=$(float_eval "$currentinc / $sleep")
avgincpertime=$(float_eval "$totalinc / $sleep / $counter")
eta=$(float_eval "($finish - $currentprog) /$avgincpertime")
echo "currentprog $currentprog currentincpertime $currentincpertime avgincpertime $avgincpertime eta $eta"



  if [[ $finish ]]; then
cat << EOF
--------------------
Current=$currentincpertime/sec
Avg=$avgincpertime/sec
Progress $currentprog/$finish
Eta=$(displaytime $eta)
EOF
  else
cat << EOF
--------------------
Current=$currentincpertime/sec
Avg=$avgincpertime/sec
Progress $currentprog
EOF
  fi
done
#####CLEAN END
exit 0












#http://www.linuxjournal.com/content/floating-point-math-bash

#new counter engine

finish=finish
currentinc =0
totalinc =0

#waring currentprog jumps from zero to exec
#which screws up the avg math
#so we do it once manualy
currentprog=exec
counter=0
sleep

start loop
#start counter
previousprog= currentprog
currentprog=exec
counter++
#end counter

#we use currentinc because it starts from 0
currentinc = currentprog - previousprog
totalinc = totalinc + currentinc

currentincpertime=currentinc/sleeptime
avgincpertime=totalinc/sleeptime/counter
eta=finish - currentprog /avgincpertime

sleep
end loop


