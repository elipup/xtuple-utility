#!/bin/bash

install_php() {
    sudo apt-get -q -y install \
        php5-common \
        php5-fpm \
        php5-cli \
        php5 \
        php5-dev \
        php5-json \
        php5-gd \
        php5-pgsql \
        php5-curl \
        php5-intl \
        php5-mcrypt \
        php-apc \
        memcached \
        php5-memcache
}

php_prompt(){
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"
generate_github_token

}

php_prompt_old() {
 if (whiptail --title "GitHub Personal Access Token" --yesno "Would you like to setup your GitHub Personal Access Token?" 10 60) then
        log "Creating GitHub Personal Access Token"

        GITHUBNAME=$(whiptail --backtitle "$( window_title )" --inputbox "Enter your GitHub username" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            return $RET
        fi

        GITHUBPASS=$(whiptail --backtitle "$( window_title )" --passwordbox "Enter your GitHub password" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            return $RET
        fi

        log "Generating your Github token."

		WORKDATE=`date "+%m%d%Y_%s"`

        curl https://api.github.com/authorizations --user ${GITHUBNAME}:${GITHUBPASS} --data '{"scopes":["user","read:org","public_repo"],"note":"Added Via xTau '${WORKDATE}'"}' -o GITHUB_TOKEN_${WORKDATE}.log
        GITHUB_TOKEN=$(jq --raw-output '.token | select(length > 0)' GITHUB_TOKEN_${WORKDATE}.log)
        OAMSG=$(jq --raw-output '.' GITHUB_TOKEN_${WORKDATE}.log)

	    if [[ -z "${GITHUB_TOKEN}" ]]; then
	    whiptail --backtitle "$( window_title )" --msgbox "Error creating your token. ${OAMSG}" 8 60 3>&1 1>&2 2>&3
	    break
	    else
	    whiptail --backtitle "$( window_title )" --msgbox "Your GitHub Personal Access token is: ${GITHUB_TOKEN}" 8 60 3>&1 1>&2 2>&3
	    export GITHUB_TOKEN
	    fi

whiptail --backtitle "$( window_title )" --msgbox "You can maintain your Github Personal Access Tokens at: https://github.com/settings/tokens" 8 60 3>&1 1>&2 2>&3
fi

}

ssh_prompt(){
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"
ssh_setup
}

ssh_prompt_old(){
# This is added so composer doesn't ask for auth during the process.
if [[ -e ~/.ssh/config ]]; then

log "Found SSH config"

SSHFILE=~/.ssh/config

declare file=${SSHFILE}
declare regex="\s+
#Added by xTau
Host github.com
HostName github.com
StrictHostKeyChecking no\s+"

declare file_content=$( cat "${file}" )
if [[ " $file_content " =~ $regex ]]
    then
log "SSH Config is good"
else
cat << EOF >> ~/.ssh/config

#Added by xTau
Host github.com
HostName github.com
StrictHostKeyChecking no

EOF

fi

else
log "Creating ~/.ssh/config"

if [ ! -d ~/.ssh  ]; then
log_exec sudo mkdir -p ~/.ssh

else
cat << EOF >> ~/.ssh/config

#Added by xTau
Host github.com
HostName github.com
StrictHostKeyChecking no

EOF
fi

fi

}

configure_php() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"
log " 1"
    sudo sed -i '/^error_reporting/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;error_reporting/ a\
    error_reporting = E_ALL' /etc/php5/fpm/php.ini
log " 2"

    sudo sed -i '/^memory_limit/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;memory_limit/ a\
    memory_limit = 256M' /etc/php5/fpm/php.ini
log " 3"

    sudo sed -i '/^;php_admin_value\[memory_limit\]/ a\
    php_value[memory_limit] = 256M' /etc/php5/fpm/pool.d/www.conf

    sudo sed -i '/^upload_max_filesize/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;upload_max_filesize/ a\
    upload_max_filesize = 64M' /etc/php5/fpm/php.ini
log " 4"

    sudo sed -i '/^post_max_size/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;post_max_size/ a\
    memory_limit = 64M' /etc/php5/fpm/php.ini

    sudo sed -i '/^max_input_vars/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^; max_input_vars/ a\
    max_input_vars = 100000' /etc/php5/fpm/php.ini

    sudo sed -i '/^date.timezone/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i "/^;date.timezone/ a\
    date.timezone = ${TIMEZONE}" /etc/php5/fpm/php.ini
log " 5"

    sudo sed -i '/^session.gc_probability/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;session.gc_probability/ a\
    session.gc_probability = 1' /etc/php5/fpm/php.ini

    sudo sed -i '/^session.gc_divisor/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;session.gc_divisor/ a\
    session.gc_divisor = 100' /etc/php5/fpm/php.ini

    sudo sed -i '/^session.gc_maxlifetime/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;session.gc_maxlifetime/ a\
    session.gc_maxlifetime = 200000' /etc/php5/fpm/php.ini

    sudo sed -i '/^session.cookie_lifetime/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;session.cookie_lifetime/ a\
    session.cookie_lifetime = 2000000' /etc/php5/fpm/php.ini

    ## Command-line interface
    sudo sed -i '/^error_reporting/ s/^/;/' /etc/php5/cli/php.ini
    sudo sed -i '/^;error_reporting/ a\
    error_reporting = E_ALL' /etc/php5/cli/php.ini
log " 6"

    sudo sed -i '/^memory_limit/ s/^/;/' /etc/php5/cli/php.ini
    sudo sed -i '/^;memory_limit/ a\
    memory_limit = 512M' /etc/php5/cli/php.ini

    sudo sed -i '/^date.timezone/ s/^/;/' /etc/php5/cli/php.ini
    sudo sed -i "/^;date.timezone/ a\
    date.timezone = ${TIMEZONE}" /etc/php5/cli/php.ini


log " 7"

    # Drush
    log_exec wget https://github.com/drush-ops/drush/releases/download/8.0.0-rc3/drush.phar && \
    log_exec chmod +x drush.phar && \
    log_exec sudo mv drush.phar /usr/local/bin/drush && \
    log_exec drush init
log " 8"

    # Mongo
    log_exec printf "\n" | sudo pecl install mongo && \
    log_exec echo "extension=mongo.so" > /etc/php5/mods-available/mongo.ini && \
    log_exec sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/cli/conf.d/20-mongo.ini && \
    log_exec sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/fpm/conf.d/20-mongo.ini
log " 9"

    # PHPUnit
    log_exec wget https://phar.phpunit.de/phpunit-old.phar && \
    log_exec chmod +x phpunit-old.phar && \
    log_exec sudo mv phpunit-old.phar /usr/local/bin/phpunit
log " 10"

    # Restart PHP and Nginx
    log_exec sudo service php5-fpm restart
    log_exec sudo service nginx restart
log " 11"

}

install_composer(){
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    # Composer
    log_exec curl -sS https://getcomposer.org/installer | php && \
    log_exec sudo mv composer.phar /usr/local/bin/composer && \

log "Setting up your composer auth.json"

#if (whiptail --backtitle "$( window_title )" --yesno "Would you like to setup composer auth.json?"  8 60 3>&1 1>&2 2>&3) then

#   log "Checking for composer..."

# DEPLOYER NAME SHOULD JUST BE DEFAULT xtuple
#    log_exec sudo chown -R ${DEPLOYER_NAME}:${DEPLOYER_NAME} /home/${DEPLOYER_NAME}/.composer

log_exec sudo su - ${DEPLOYER_NAME} -c "composer config --global github-oauth.github.com ${GITHUB_TOKEN}"

#    whiptail --backtitle "$( window_title )" --msgbox "Wrote auth.json for Composer" 8 60 3>&1 1>&2 2>&3

#  else

#    composer config --global github-oauth.github.com ${GITHUB_TOKEN}

#    whiptail --backtitle "$( window_title )" --msgbox "Wrote auth.json for Composer" 8 60 3>&1 1>&2 2>&3

#  fi

}
