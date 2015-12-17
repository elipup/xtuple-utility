#!/bin/bash

install_postfix() {
    DEBIAN_FRONTEND=noninteractive sudo apt-get -q -y install postfix
}

postfix_prompt() {
    if [ -z $POSTFIX_DOMAIN ]; then
        POSTFIX_DOMAIN=$(whiptail --backtitle "$( window_title )" --inputbox "Postfix Server Name (Domain name)" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            return $RET
        else
            export POSTFIX_DOMAIN
        fi
    fi
}

# $1 is the server's domain name
configure_postfix() {
    if [ -n "$1" ]; then
        POSTFIX_DOMAIN=$1
    fi

    postfix_prompt

    log_exec sudo mv /etc/postfix/main.cf /etc/postfix/main.cf.old

    echo "postfix postfix/root_address      string ${DEPLOYER_NAME}" | sudo debconf-set-selections
    echo "postfix postfix/rfc1035_violation boolean false" | sudo debconf-set-selections
    echo "postfix postfix/mynetworks        string 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" | sudo debconf-set-selections
    echo "postfix postfix/mailname          string ${POSTFIX_DOMAIN}" | sudo debconf-set-selections
    echo "postfix postfix/recipient_delim   string +" | sudo debconf-set-selections
    echo "postfix postfix/main_mailer_type  select Internet Site" | sudo debconf-set-selections
    echo "postfix postfix/destinations      string localhost" | sudo debconf-set-selections
    DEBIAN_FRONTEND=noninteractive sudo dpkg-reconfigure postfix

    log_exec sudo sed -i "/^myhostname/ a\
    mydomain = ${POSTFIX_DOMAIN}" /etc/postfix/main.cf
    log_exec sudo sed -i '/^myorigin/ s/^/# /' /etc/postfix/main.cf
    log_exec sudo sed -i '/^# myorigin/ a\
    myorigin = $mydomain' /etc/postfix/main.cf

    log_exec sudo service postfix restart
}
