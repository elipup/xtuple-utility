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

php_prompt() {
    if [ -z $GITHUB_TOKEN ]; then
        GITHUB_TOKEN=$(whiptail --backtitle "$( window_title )" --inputbox "Github token" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            return $RET
        else
            export GITHUB_TOKEN
        fi
    fi
}

configure_php() {
    sudo sed -i '/^error_reporting/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;error_reporting/ a\
    error_reporting = E_ALL' /etc/php5/fpm/php.ini

    sudo sed -i '/^memory_limit/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;memory_limit/ a\
    memory_limit = 256M' /etc/php5/fpm/php.ini

    sudo sed -i '/^;php_admin_value\[memory_limit\]/ a\
    php_value[memory_limit] = 256M' /etc/php5/fpm/pool.d/www.conf

    sudo sed -i '/^upload_max_filesize/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;upload_max_filesize/ a\
    upload_max_filesize = 64M' /etc/php5/fpm/php.ini

    sudo sed -i '/^post_max_size/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^;post_max_size/ a\
    memory_limit = 64M' /etc/php5/fpm/php.ini

    sudo sed -i '/^max_input_vars/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i '/^; max_input_vars/ a\
    max_input_vars = 100000' /etc/php5/fpm/php.ini

    sudo sed -i '/^date.timezone/ s/^/;/' /etc/php5/fpm/php.ini
    sudo sed -i "/^;date.timezone/ a\
    date.timezone = ${TIMEZONE}" /etc/php5/fpm/php.ini

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

    sudo sed -i '/^memory_limit/ s/^/;/' /etc/php5/cli/php.ini
    sudo sed -i '/^;memory_limit/ a\
    memory_limit = 512M' /etc/php5/cli/php.ini

    sudo sed -i '/^date.timezone/ s/^/;/' /etc/php5/cli/php.ini
    sudo sed -i "/^;date.timezone/ a\
    date.timezone = ${TIMEZONE}" /etc/php5/cli/php.ini

    # Composer
    log_exec curl -sS https://getcomposer.org/installer | sudo php && \
    log_exec sudo mv composer.phar /usr/local/bin/composer && \
    log_exec mkdir -p /home/${DEPLOYER_NAME}/.composer && \
    log_exec echo "{
    \"config\": {
        \"github-oauth\": {
            \"github.com\": \"${GITHUB_TOKEN}\"
        },
        \"process-timeout\": 600,
        \"preferred-install\": \"dist\",
        \"github-protocols\": [\"https\"]        
    }
}" > /home/${DEPLOYER_NAME}/.composer/config.json && \
    log_exec sudo chown -R ${DEPLOYER_NAME}:${DEPLOYER_NAME} /home/${DEPLOYER_NAME}/.composer

    # Drush
    log_exec wget https://github.com/drush-ops/drush/releases/download/8.0.0-rc3/drush.phar && \
    log_exec chmod +x drush.phar && \
    log_exec sudo mv drush.phar /usr/local/bin/drush && \
    log_exec drush init

    # Mongo
    log_exec printf "\n" | sudo pecl install mongo && \
    log_exec echo "extension=mongo.so" > /etc/php5/mods-available/mongo.ini && \
    log_exec sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/cli/conf.d/20-mongo.ini && \
    log_exec sudo ln -s /etc/php5/mods-available/mongo.ini /etc/php5/fpm/conf.d/20-mongo.ini

    # PHPUnit
    log_exec wget https://phar.phpunit.de/phpunit-old.phar && \
    log_exec chmod +x phpunit-old.phar && \
    log_exec sudo mv phpunit-old.phar /usr/local/bin/phpunit

    # Restart PHP and Nginx
    log_exec sudo service php5-fpm restart
    log_exec sudo service nginx restart
}