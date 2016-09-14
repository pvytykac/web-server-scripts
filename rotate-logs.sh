#!/bin/bash

LOG_DIR="/var/log/$1" # path to log folder relative to /var/log
FILES="$2"            # comma separated list of files to rotate
LIMIT="$3"            # max size of the log file in bytes

# logging
LOG_FILE=/var/log/log-rotate/log-rotate
exec 1<&-
exec 2<&-
exec 1<>$LOG_FILE.log
exec 2<>$LOG_FILE.err

# default log file size 1 MB
if [ -z $LIMIT ]; then
  LIMIT="1048576"
fi

# nothing to do if the log folder does not exist yet
if [ ! -d "$LOG_DIR" ]; then
  exit 0
fi

# rotate the logs
for file in $(echo "$FILES" | awk 'BEGIN { RS = "," }; { print }'); do
  if [ -f "$LOG_DIR/$file" ]; then
    SIZE=$(wc -c <"$LOG_DIR/$file")
  else
    SIZE="0"
  fi

  if [ "$SIZE" -gt "$LIMIT" ]; then
    echo "'$LOG_DIR': rotating log file '$file' after it reached size of $SIZE bytes"
    mv -f "$LOG_DIR/$file" "$LOG_DIR/$file.2"
  fi
done
