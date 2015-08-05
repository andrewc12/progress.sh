#!/bin/bash
#CMD="tail -n1 .progress | cut -d' ' -f1"
#Updates a display version of the variables
#The original script just reduced the accuracy of the actual variables
#test: 'date +"%s"' $(($(date +"%s") + 100))
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
ETA="???"
while [ true ]; do
  sleep $SLEEP
  STARTTIME=$(date +%s)
  LATER=$(eval $CMD)
  ENDTIME=$(date +%s)
  EXECTIME=$(($ENDTIME - $STARTTIME))
#TODO: this assumes that the sleep time is the only thing causing delays 
  RECS=$(echo "($LATER - $NOW) /  ($SLEEP + $EXECTIME)" | bc -l)
  NOW=$LATER
  let COUNT=$COUNT+1
  AVGTOTAL=$(echo "$AVGTOTAL + $RECS" | bc -l)
  AVG=$(echo "$AVGTOTAL/$COUNT" | bc -l)
  if [ $TOTAL -gt 0 ]; then
    PERCENT=$(echo "$LATER / $TOTAL * 100" | bc -l)
    if [ "$AVG" != "0" ]; then
      ETA=$(echo "scale=2; mins= ($TOTAL - $LATER)/ $AVG /60; if ( mins > 1440 ) { print mins/1440; print \" days\" } else {if ( mins > 60 ) { print mins/60; print \" hrs\" } else {print mins;print \" mins\"}}" | bc -l)
      ETA=$(displaytime $(echo "scale=0;($TOTAL - $LATER)/ $AVG"| bc -l))
    fi
    makedvars
    DAVG=$(displaynumpertime "$AVG")
    echo -e "Current=$DRECS/sec\tTotalAvg=$DAVG\tTotal=$DLATER/$DTOTAL $DPERCENT%\t$ETA left\tExecution=$EXECTIME sec"
  else
    makedvars
    DAVG=$(displaynumpertime "$AVG")
    echo -e "Current=$DRECS/sec\tTotalAvg=$DAVG\tTotal=$DLATER\tExecution=$EXECTIME sec"
  fi
done
exit 0







