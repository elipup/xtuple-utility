#!/bin/bash

LOG_FILE=$(pwd)/install-$DATE.log
CHOICE_FILE=$(pwd)/choice-$DATE.log
EC_LOG_FILE=$(pwd)/ecomm_details-$DATE.log

log_exec() {
   "$@" | tee -a $LOG_FILE 2>&1
   RET=${PIPESTATUS[0]}
   return $RET
}

log() {
    echo "$( timestamp ) xtuple >> $@"
    echo "$( timestamp ) xtuple >> $@" >> $LOG_FILE
}

log_ec() {
    echo "$( timestamp ) xtuple >> $@"
    echo "$( timestamp ) xtuple >> $@" >> $EC_LOG_FILE
}

log_choice() {
    echo -n "$1 " >> $CHOICE_FILE
    "$@"
}

log_arg() {
	echo "$@" >> $CHOICE_FILE
}

timestamp() {
  date +"%T"
}

datetime() {
  date +"%D %T"
}

log "Logging initialized. Current session will be logged to $LOG_FILE"
