#!/bin/bash

# redirect output streams
LOG_FILE=/var/log/bruteforcers/bruteforcers
exec 1<&-
exec 2<&-
exec 1>>"$LOG_FILE.log"
exec 2>>"$LOG_FILE.err"

function log {
  MSG="$1" # message to be logged
  LOG="$2" # stream to append the message to

  # if LOG was not specified default to &1
  if [ -z $STR ]; then 
    LOG="&1"
  fi 

  # if a message was provided log it
  if [ ! -z "$MSG" ]; then
    eval "echo \"$(date -u +'%Y-%m-%d %H:%M:%S').$(date -u +%N | cut -c 1-3)   $MSG\" >$LOG"
  fi
}

# ban function
function banIP {
  IP="$1"
  ATTEMPTS="$2"

  # check that IP is defined
  if [ -z $IP ]; then
    log "$IP: ip not provided" "&2"
    exit 1
  fi

  # check that ATTEMPTS is a number
  if [ ! "$ATTEMPTS" -eq "$ATTEMPTS" ]; then
    log "$IP: $ATTEMPTS is not a number" "&2"
  fi

  # firewall rule template
  RULE="rule family='ipv4' source address='$IP' reject"
  RULE_FILTER=$(echo "$RULE" | sed "s/'/\"/g")
  EXISTS=$(firewall-cmd --list-rich-rules | grep "$RULE_FILTER" | wc -l)

  # if the rule is already specified for the IP log the message and dont add anything
  if [ "$EXISTS" -gt "0" ]; then 
    log "$IP: already banned"
  # otherwise add the rule and log the message
  else
    log "$IP: banning after $ATTEMPTS unsuccessfull login attempts"
    firewall-cmd --permanent --add-rich-rule="$RULE" > /dev/null 2>&2
  fi
}

log "starting"

# parse all the unsuccessfull login attempts from ssh logs
# if more then $LIMIT login attempts failed from the same IP ban it
for line in $(egrep "Invalid user.+from" /var/log/secure | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort | uniq -c | sed "s/^[ ]*\([0-9]*\)[ ]*\(.*\)$/\1:\2/")
do
  cnt=$(echo "$line" | awk 'BEGIN { FS = ":"}; { RS = "\n" }; { print $1 }')
  ip=$(echo "$line" | awk 'BEGIN { FS = ":"}; { RS = "\n" }; { print $2 }')

  if [ "$cnt" -gt "5" ]; then
    banIP $ip $cnt
  fi
done

# reload the firewalld for the changes to take effect
firewall-cmd --reload > /dev/null 2>&2

log "finished"
