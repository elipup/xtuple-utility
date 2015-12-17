#!/usr/bin/env bash

install_mongo() {
    sudo apt-get install -y mongodb-org
}

mongo_prompt() {
    if [ -z $MONGO_ADMIN_PASS ]; then
        MONGO_ADMIN_PASS=$(whiptail --backtitle "$( window_title )" --passwordbox "Mongo Admin Password" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            return $RET
        else
            export MONGO_ADMIN_PASS
        fi
    fi
    
    set_ecommerce_info
}

configure_mongo() {
    mongo_prompt
    
    log_exec sudo mongo admin --eval='db.createUser({ user: "admin", pwd: "'${MONGO_ADMIN_PASS}'", roles: [{ role: "userAdminAnyDatabase", db: "admin" }] })'
    log_exec sudo mongo admin --eval='db.getSiblingDB("'${DEVELOPMENT_DB_NAME}'").createUser({ user: "'${DEVELOPMENT_DB_USER}'", pwd: "'${DEVELOPMENT_DB_PASS}'", roles: [ "dbOwner"] })'
    log_exec sudo mongo admin --eval='db.getSiblingDB("'${STAGE_DB_NAME}'").createUser({ user: "'${STAGE_DB_USER}'", pwd: "'${STAGE_DB_PASS}'", roles: [ "dbOwner"] })'
    log_exec sudo mongo admin --eval='db.getSiblingDB("'${PRODUCTION_DB_NAME}'").createUser({ user: "'${PRODUCTION_DB_USER}'", pwd: "'${PRODUCTION_DB_PASS}'", roles: [ "dbOwner"] })'

    log_exec sudo cp /etc/mongod.conf /etc/mongod.conf.original

    log_exec sudo cp ~/xdruple-server/conf/mongod.conf.yaml /etc/mongod.conf
    log_exec sudo service mongod restart
}