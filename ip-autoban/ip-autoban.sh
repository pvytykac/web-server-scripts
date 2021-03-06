#!/bin/bash
DIR=$(dirname "$0")

# include the log lib
. $DIR/lib/log.sh

# ban function
function banIP {
  local IP="$1"
  local ATTEMPTS="$2"

  # check that IP is defined
  if [ -z $IP ]; then
    error "$IP: ip not provided"
    return 1
  fi

  # check that ATTEMPTS is a number
  if [ ! "$ATTEMPTS" -eq "$ATTEMPTS" ]; then
    error "$IP: $ATTEMPTS is not a number"
    return 1
  fi

  # firewall rule template
  local RULE="rule family='ipv4' source address='$IP' reject"
  local RULE_FILTER=$(echo "$RULE" | sed "s/'/\"/g")
  local EXISTS=$(firewall-cmd --list-rich-rules | grep "$RULE_FILTER" | wc -l)

  # if the rule is already specified for the IP log the message and dont add anything
  if [ "$EXISTS" -gt "0" ]; then
    trace "$IP: already banned"
    return 0
  # otherwise add the rule and log the message
  else
    info "$IP: banning after $ATTEMPTS unsuccessfull login attempts"
    local resp=$(firewall-cmd --permanent --add-rich-rule="$RULE" 2>&1)
    local status=$?

    trace "attempt to ban '$ip' finished with status code '$status' and response '$resp'"
    if [ "$status" -eq "0" ]; then
      ((BANNED++))
    fi

    return "$status"
  fi
}

BANNED="0" # counter of banned ips
RESULT="0" # exit code

info  "starting"

limit="$1"

if [ -z "$limit" ]; then
  limit="5"
fi

# parse all the unsuccessfull login attempts from ssh logs
# if more then $LIMIT login attempts failed from the same IP ban it
for line in $(egrep "Invalid user.+from" /var/log/secure/secure | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort | uniq -c | sed "s/^[ ]*\([0-9]*\)[ ]*\(.*\)$/\1:\2/")
do
  cnt=$(echo "$line" | awk 'BEGIN { FS = ":"}; { RS = "\n" }; { print $1 }')
  ip=$(echo "$line" | awk 'BEGIN { FS = ":"}; { RS = "\n" }; { print $2 }')

  if [ "$cnt" -gt "$limit" ]; then
    banIP $ip $cnt
    if [ "$?" -ne "0" ]; then
      error "error encountered while processing the ip address '$ip' with '$cnt' unsuccessfull login attempts"
    fi
  fi
done

# if needed reload the firewalld for the changes to take effect
if [ "$BANNED" -gt "0" ]; then
  info "$BANNED ips banned this run -> reloading the firewall service"
  resp=$(firewall-cmd --reload 2>&1)
  status=$?

  trace "firewalld --reload call finished with status code '$status' and response '$resp'"
  if [ "$status" -eq "0" ]; then
    info "firewalld service was reloaded successfully"
  else
    error "firewalld service could not be reloaded"
    RESULT="1"
  fi
else
  info "no ips banned this run -> reload of firewall service is not needed"
fi

info "done"
exit "$RESULT"
