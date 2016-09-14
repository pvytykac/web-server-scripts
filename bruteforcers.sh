#!/bin/bash

# redirect output streams
LOG_FILE=/var/log/bruteforcers/bruteforcers
exec 1<&-
exec 2<&-
exec 1<>"$LOG_FILE.log"
exec 2<>"$LOG_FILE.err"

# ban function
function banIP {
  IP="$1"
  ATTEMPTS="$2"

  # check that IP is defined
  if [ -z ${IP+x} ]; then
    echo "'$IP': ip not provided" >&2
    exit 1
  fi

  # check that ATTEMPTS is a number
  if [ ! "$ATTEMPTS" -eq "$ATTEMPTS" ]; then
    echo "'$IP': $ATTEMPTS is not a number" >&2
  fi

  # firewall rule template
  RULE="rule family='ipv4' source address='$IP' reject"
  RULE_FILTER=$(echo "$RULE" | sed "s/'/\"/g")
  EXISTS=$(firewall-cmd --list-rich-rules | grep "$RULE_FILTER" | wc -l)

  # if the rule is already specified for the IP log the message and dont add anything
  if [ "$EXISTS" -gt "0" ]; then 
    echo "'$IP': already banned"
  # otherwise add the rule and log the message
  else
    echo "'$IP': banning after $ATTEMPTS unsuccessfull login attempts"
    firewall-cmd --permanent --add-rich-rule="$RULE"
  fi
}

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
firewall-cmd --reload
