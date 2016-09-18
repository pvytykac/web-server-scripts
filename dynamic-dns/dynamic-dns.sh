#!/bin/bash
DIR=$(dirname "$0")
. $DIR/lib/log.sh

url="$1"
if [ -z "$url" ]; then
  error "the freedns update url was not specified"
  exit 1
fi

prev="<none>"
cur=$(dig +short myip.opendns.com @resolver1.opendns.com)
tmp_file="/tmp/dynamic-dns.tmp"
is_same="0"

debug "current ip address is '$cur'"
if [ -f "$tmp_file" ]; then
  prev=$(cat "$tmp_file")
  is_same=$(grep -c "$cur" "$tmp_file")
  debug "temp file exists, the previous ip is '$prev', previous ip same as current = '$is_same' (1 - true, 0 - false)"
else
  debug "no previous ip stored in the temp file"
fi

if [ "$is_same" -eq "0" ]; then
  info "updating the ip address on freedns server from '$prev' to '$cur' using the url '$url'"
  resp=$(curl -sk "$url")
  status=$?

  if [ "$status" -eq "0" ]; then
    info "the ip address was successfully updated to '$cur', http response: '$resp'"
    printf "%s" "$cur" > "$tmp_file"

    if [ "$?" -eq "0" ]; then
      info "the new ip address was successfully saved to temp file '$tmp_file'"
    else
      warn "the ip was updated on freedns server, but an error occurred during the attempt to save the new ip to the temp file"
    fi
  else
    error "an error occurred during the attempt to update the ip address to '$cur', http response: '$resp'"
  fi

  exit "$status"
else
  info "the current ip '$cur' is identical to the previous one, no need to update"
fi

exit 0
