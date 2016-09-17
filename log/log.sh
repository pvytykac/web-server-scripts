# logs a message ($1) at a trace level ($2 - default info)
# supported log levels:
#   stdout -> TRACE,DEBUG,INFO,WARN
#   stdere -> ERROR
function log {
  local msg="$1"                              # message to be logged
  local lvl="$2"                              # log level to log the message at
  local ts=$(date -u +"%Y-%m-%d %H:%M:%S.%N") # UTC0 timestamp
  local out="&1"                              # output stream
  local levels="TRACE:DEBUG:INFO:WARN:ERROR"  # supported levels

  # on empty message
  if [ -z "$msg" ]; then
    return 1
  fi

  # default to INFO if log level was not specified or an unsupported level was specified
  if [ -z "$lvl" ] || { [ $(echo "$levels" | grep -ic "$lvl:") -eq "0" ] && [ $(echo "$levels" | grep -ic ":$lvl") -eq "0" ]; }; then
    lvl="INFO"
  fi

  # if ERROR level was specified change the output stream to stderr
  if [ "$lvl" == "ERROR" ]; then
    out="&2"
  fi

  # allways log the level as uppercase string
  lvl=$(echo "$lvl" | awk '{ print toupper($0)}')

  # log the message and return the result of eval call
  eval "printf \"%s\t%s\t%s\n\" \"${ts:0:23}\" \"$lvl\" \"$msg\" >$out"
  return $?
}

# convenience functions below

function trace {
  log "$1" "TRACE"
}

function debug {
  log "$1" "DEBUG"
}

function info {
  log "$1" "INFO"
}

function warn {
 log "$1" "WARN"
}

function error {
  log "$1" "ERROR"
}

# test cases

#trace "this is a trace message"
#echo "status: $?"

#debug "this is a debug message"
#echo "status: $?"

#info "this is an info message"
#echo "status: $?"

#warn "this is a warn message"
#echo "status: $?"

#error "this is an error message"
#echo "status: $?"

#log "this is a message with unknown log level, it should default to info" "ABCDEFGH"
#echo "status: $?"

#log "this is a trace message with lowercase level specified, should be logged at TRACE level" "trace"
#echo "status: $?"

#info
#echo "status of a call to info without parameters should be 1: $?"
