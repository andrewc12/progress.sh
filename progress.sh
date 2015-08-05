#!/bin/bash
#CMD="tail -n1 .progress | cut -d' ' -f1"
#Updates a display version of the variables
#The original script just reduced the accuracy of the actual variables
#test: 'date +"%s"' $(($(date +"%s") + 100))


#http://www.linuxjournal.com/content/floating-point-math-bash
# Floating point number functions.

#####################################################################
# Default scale used by float functions.

float_scale=2


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
  local D=$(echo "scale=0; $C * 60 * 60 *24 / 1" | bc -l)
#  local H=$((C*60*60))
  local H=$(echo "scale=0; $C * 60 * 60 / 1" | bc -l)
#  local M=$((C*60))
  local M=$(echo "scale=0; $C * 60 / 1" | bc -l)
#  local S=$((C))
  local S=$(echo "scale=0; $C * 1 / 1" | bc -l)
  [[ $D -ge 1 ]] && RETURN=$(printf '%d/day ' $D)
  [[ $H -ge 1 ]] && RETURN=$(printf '%d/hour ' $H)
  [[ $M -ge 1 ]] && RETURN=$(printf '%d/minute ' $M)
  [[ $S -gt 1 ]] && RETURN=$(printf '%d/second ' $S)
  echo $RETURN
}
function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [[ $D > 0 ]] && printf '%d days ' $D
  [[ $H > 0 ]] && printf '%d hours ' $H
  [[ $M > 0 ]] && printf '%d minutes ' $M
  [[ $D > 0 || $H > 0 || $M > 0 ]] && printf 'and '
  printf '%d seconds\n' $S
}
function makedvars()
{
  DRECS=$(echo "scale=2; $RECS / 1" | bc -l)
  DAVG=$(echo "scale=2; $AVG * 60 * 60 / 1" | bc -l)
  DLATER=$(echo "scale=0; $LATER / 1" | bc -l)
  DTOTAL=$(echo "scale=0; $TOTAL / 1" | bc -l)
  DPERCENT=$(echo "scale=2; $PERCENT / 1" | bc -l)
}
if [ -n "$1" ]; then
  CMD=$1
  if [ -n "$2" ]; then
    TOTAL=$2
    finish=$TOTAL
    if [ ! $TOTAL -gt 0 ]; then
      echo "ARG2 should be an integer > 0."
      exit 1;
    fi
  else
    TOTAL=0
  fi
else 
  echo "ARG1 should be a command that generates an integer!"
  echo "ARG2 (optional) should be the end integer."
  exit 1;
fi

SLEEP=1
NOW=$(eval $CMD)
if [ $NOW -eq $NOW 2> /dev/null ]; then
  if [ ! $NOW -ge 0 ]; then
    echo "Running of '$CMD' produced output that is not greater than or equal to 0.";
    exit 1;
  fi
else 
    echo "Running of '$CMD' produced output that is not an integer.";
    exit 1;
fi
COUNT=0
AVGTOTAL=0
#####CLEAN START
totalinc=0
#####CLEAN END
ETA="???"
while [ true ]; do
  sleep $SLEEP
  LATER=$(eval $CMD)
#TODO: this assumes that the sleep time is the only thing causing delays 
  RECS=$(echo "($LATER - $NOW) /  $SLEEP " | bc -l)
#####CLEAN START
currentinc=$(float_eval "$LATER - $NOW")
totalinc=$(float_eval "$totalinc + $currentinc")
echo "currentinc $currentinc totalinc $totalinc"
#####CLEAN END

  NOW=$LATER
  let COUNT=$COUNT+1

#####CLEAN START
    currentprog=$LATER
currentincpertime=$(float_eval "$currentinc / $SLEEP")
avgincpertime=$(float_eval "$totalinc / $SLEEP / $COUNT")
eta=$(float_eval "$finish - $currentprog /$avgincpertime")
echo "currentprog $currentprog currentincpertime $currentincpertime avgincpertime $avgincpertime eta $eta"
#####CLEAN END

  AVGTOTAL=$(echo "$AVGTOTAL + $RECS" | bc -l)
  AVG=$(echo "$AVGTOTAL/$COUNT" | bc -l)
  if [ $TOTAL -gt 0 ]; then
    PERCENT=$(echo "$LATER / $TOTAL * 100" | bc -l)
    if [ "$AVG" != "0" ]; then
      ETA=$(echo "scale=2; mins= ($TOTAL - $LATER)/ $AVG /60; if ( mins > 1440 ) { print mins/1440; print \" days\" } else {if ( mins > 60 ) { print mins/60; print \" hrs\" } else {print mins;print \" mins\"}}" | bc -l)
      ETA=$(displaytime $(echo "scale=0;($TOTAL - $LATER)/ $AVG"| bc -l))
    fi
#####CLEAN START
    makedvars
#####CLEAN END
    DAVG=$(displaynumpertime "$AVG")
#    echo -e "Current=$DRECS/sec\tTotalAvg=$DAVG\tTotal=$DLATER/$DTOTAL $DPERCENT%\t$ETA left\tExecution=$EXECTIME sec"
cat << EOF
--------------------
Current=$DRECS/sec
TotalAvg=$DAVG
Total=$DLATER/$DTOTAL $DPERCENT%
$ETA left
EOF
  else
#####CLEAN START
    makedvars
#####CLEAN END
    DAVG=$(displaynumpertime "$AVG")
    echo -e "Current=$DRECS/sec\tTotalAvg=$DAVG\tTotal=$DLATER"
  fi
done
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


