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
    log_exec sudo mongo admin --eval='db.getSiblingDB("'${ECOMM_DB_NAME}'").createUser({ user: "'${ECOMM_DB_USER}'", pwd: "'${ECOMM_DB_PASS}'", roles: [ "dbOwner"] })'

    log_exec sudo cp /etc/mongod.conf /etc/mongod.conf.original

    log_exec sudo cp ~/xdruple-server/conf/mongod.conf.yaml /etc/mongod.conf
    log_exec sudo service mongod restart
}

create_mongo_db_auto() {
ECOMM_DB_NAME="xd_${DATABASE}"
ECOMM_DB_USER=xd_admin
ECOMM_DB_PASS=xd_admin
  #  log_exec sudo mongo admin --eval='db.createUser({ user: "xd_admin", pwd: "'xd_admin'", roles: [{ role: "userAdminAnyDatabase", db: "admin" }] })'
    log_exec  sudo mongo ${ECOMM_DB_NAME} --eval='db.dropDatabase()'
    log_exec sudo mongo admin --eval='db.dropUser("${ECOMM_DB_USER}")'
    log_exec sudo mongo admin --eval='db.getSiblingDB("'${ECOMM_DB_NAME}'").createUser({ user: "'${ECOMM_DB_USER}'", pwd: "'${ECOMM_DB_PASS}'", roles: [ "dbOwner"] })'
}

