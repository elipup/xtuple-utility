#!/bin/bash

install_postfix() {
    DEBIAN_FRONTEND=noninteractive sudo apt-get -q -y install postfix
}

postfix_prompt() {
    if [ -z $NGINX_DOMAIN ]; then
        NGINX_DOMAIN=$(whiptail --backtitle "$( window_title )" --inputbox "Server Name (Domain name)" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            return $RET
        else
            export NGINX_DOMAIN
        fi
    fi
}

# $1 is the server's domain name
configure_postfix() {
    if [ -n "$1" ]; then
        NGINX_DOMAIN=$1
    fi

    postfix_prompt

    sudo mv /etc/postfix/main.cf /etc/postfix/main.cf.old

    echo "postfix postfix/root_address      string ${DEPLOYER_NAME}" | sudo debconf-set-selections
    echo "postfix postfix/rfc1035_violation boolean false" | sudo debconf-set-selections
    echo "postfix postfix/mynetworks        string 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128" | sudo debconf-set-selections
    echo "postfix postfix/mailname          string ${NGINX_DOMAIN}" | sudo debconf-set-selections
    echo "postfix postfix/recipient_delim   string +" | sudo debconf-set-selections
    echo "postfix postfix/main_mailer_type  select Internet Site" | sudo debconf-set-selections
    echo "postfix postfix/destinations      string localhost" | sudo debconf-set-selections
    DEBIAN_FRONTEND=noninteractive sudo dpkg-reconfigure postfix

    sudo sed -i "/^myhostname/ a\
    mydomain = ${NGINX_DOMAIN}" /etc/postfix/main.cf
    sudo sed -i '/^myorigin/ s/^/# /' /etc/postfix/main.cf
    sudo sed -i '/^# myorigin/ a\
    myorigin = $mydomain' /etc/postfix/main.cf

    sudo service postfix restart
}
