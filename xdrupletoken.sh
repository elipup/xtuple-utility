#!/bin/bash
# Creates OAuth Token for xDruple
# Need to select a database connection for
# ERP_DBCONN
# Need your ECOMM_ADMIN_EMAIL, this could be used for letsencrypt too.


CONF_TIME=$(date +'%s')

generateOA()
{
if [[ -z ${ECOMM_ADMIN_EMAIL} ]]; then
ECOMM_ADMIN_EMAIL="admin@prodiem.xd"
fi

if [[ -z ${NGINX_ECOM_DOMAIN} ]]; then
NGINX_ECOM_DOMAIN="shop.prodiem.xd"
fi

if [[ -z ${NGINX_ECOM_DOMAIN} ]]; then
NGINX_ECOM_DOMAIN="Prodiem Demo Shop"
fi

if [[ -z ${ECOMM_SITE_URL} ]]; then
ECOMM_SITE_URL="http://shop.prodiem.xd"
ERP_SITE_URL="https://erp.prodiem.xd/${DATABASE}"
fi

# Set up a unique dir to do our work.


KEY_TMP=tempkey_${CONF_TIME}

mkdir -p ${KEY_TMP}

# THE P12 KEY OUT NEEDS TO GO IN /var/xtuple/keys/
KEY_P12_PATH=/var/xtuple/keys
sudo mkdir -p ${KEY_P12_PATH}

NGINX_ECOM_DOMAIN_P12=${NGINX_ECOM_DOMAIN}.p12


ssh-keygen -t rsa -b 2048 -C "${ECOMM_ADMIN_EMAIL}" -f ${KEY_TMP}/keypair.key -P ''
openssl req -batch -new -key ${KEY_TMP}/keypair.key -out ${KEY_TMP}/keypair.csr
openssl x509 -req -in ${KEY_TMP}/keypair.csr -signkey ${KEY_TMP}/keypair.key -out ${KEY_TMP}/keypair.crt
openssl pkcs12 -export -in ${KEY_TMP}/keypair.crt -inkey ${KEY_TMP}/keypair.key -out ${KEY_TMP}/${NGINX_ECOM_DOMAIN_P12} -password pass:notasecret
openssl pkcs12 -in ${KEY_TMP}/${NGINX_ECOM_DOMAIN_P12} -passin pass:notasecret -nocerts -nodes | openssl rsa > ${KEY_TMP}/private.pem
openssl rsa -in ${KEY_TMP}/private.pem -passin pass:notasecret -pubout -passout pass:notasecret > ${KEY_TMP}/public.pem
sudo cp ${KEY_TMP}/${NGINX_ECOM_DOMAIN_P12} ${KEY_P12_PATH}

OAPUBKEY=$(<${KEY_TMP}/public.pem)
export OAPUBKEY=${OAPUBKEY}

log "Created OA Public Key in ${KEY_TMP}/public.pem"
}


insertOA()
{
CLIENT_ID=$(${ERP_DBCONN} -c "INSERT INTO xt.oa2client(oa2client_client_id, oa2client_client_secret, oa2client_client_name, \
oa2client_client_email, oa2client_client_web_site, oa2client_client_type, oa2client_active, \
oa2client_issued, oa2client_delegated_access, oa2client_client_x509_pub_cert, oa2client_org) \
SELECT current_database()||'_'||xt.uuid_generate_v4() AS oa2client_client_id, xt.uuid_generate_v4() AS oa2client_client_secret, \
'${NGINX_ECOM_DOMAIN}' AS oa2client_client_name, '${ECOMM_ADMIN_EMAIL}' AS oa2client_client_email, \
'${ERP_SITE_URL}' AS oa2client_client_web_site, 'jwt bearer' AS oa2client_client_type, TRUE AS oa2client_active,  \
now() AS oa2client_issued , TRUE AS oa2client_delegated_access, '${OAPUBKEY}' AS oa2client_client_x509_pub_cert, current_database() AS  oa2client_org \
RETURNING oa2client_client_id; ")
export CLIENT_ID=$CLIENT_ID
log "Got $CLIENT_ID"
}


generateEnvPHP()
{
ENV_TMP=envphp_${CONF_TIME}
mkdir -p ${ENV_TMP}

# Environment - live, dev, stage - corresponds to /var/www/live|dev|stage, but I suppose it could be whatever you want the
# document root to be. This is used in NGINX confs for root directive, and is where we are cloning the drupal code into.
# i.e. git clone "https://yourgithubtoken:x-oauth-basic@github.com/xtuple/prodiem.git" /var/www/live

# This becomes the webroot
ENVIRONMENT=${NGINX_ECOM_DOMAIN}_${DATABASE}
export ENVIRONMENT=${NGINX_ECOM_DOMAIN}_${DATABASE}

# This value is in xdruplesettings.ini
#Having something other than "development", "stage"  or "production" here we might have an unexpected behavior

if [[ -z ${PHP_XDRUPLE_ENV} ]]; then
PHP_XDRUPLE_ENV=production
fi

PHP_XDRUPLE_ENVIRONMENT=${PHP_XDRUPLE_ENV}
export PHP_XDRUPLE_ENVIRONMENT=${PHP_XDRUPLE_ENV}


XDRUPLE_TEMPLATE=prodiem

if [[ ! -d /var/www/${ENVIRONMENT} ]]; then
log_exec sudo git clone "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/xtuple/${XDRUPLE_TEMPLATE}" /var/www/${ENVIRONMENT}
else
log "/var/www/${ENVIRONMENT} already exists"
fi

#xTuple REST API
RESCUED_APP_NAME=$(${ERP_DBCONN} -c "SELECT oa2client_client_name FROM xt.oa2client WHERE oa2client_client_id = '${CLIENT_ID}';")
RESCUED_URL=$(${ERP_DBCONN} -c "SELECT oa2client_client_web_site FROM xt.oa2client WHERE oa2client_client_id = '${CLIENT_ID}';")
RESCUED_ISS=${CLIENT_ID}
RESCUED_KEY_FILE=/var/xtuple/keys/${RESCUED_APP_NAME}.p12

# Can set to FALSE, Should ask...
RESCUED_DEBUG=TRUE

### WE SHOULD ASK WHAT THESE ARE
### AND EXPLAIN WHERE THEY CAN GET THEM FROM

if [[ -e xdruplesettings.ini ]]; then

source xdruplesettings.ini
log "Using xdruplesettings.ini"

else
#Authorize.NET
COMMERCE_AUTHNET_AIM_LOGIN=''
COMMERCE_AUTHNET_AIM_TRANSACTION_KEY=''

#UPS
UPS_ACCOUNT_ID=''
UPS_ACCESS_KEY=''
UPS_USER_ID=''
UPS_PASSWORD=''
UPS_PICKUP_SCHEDULE=daily_pickup

#FedEX
FEDEX_BETA=TRUE
FEDEX_KEY=''
FEDEX_PASSWORD=''
FEDEX_ACCOUNT_NUMBER=''
FEDEX_METER_NUMBER=''

fi

# THIS OUTPUT GETS PUT IN /var/www/{ENVIRONMENT}/config/environment.php
# Shipping methods must match what is in xtuple. Need to work on this.
cat << EOF > ${ENV_TMP}/environment.php
<?php

\$configuration = [
  'environment' => '${PHP_XDRUPLE_ENVIRONMENT}',
  'xtuple_rest_api' => [
    'app_name' => '${RESCUED_APP_NAME}',
    'url' => '${RESCUED_URL}',
    'iss' => '${RESCUED_ISS}',
    'key' => '${RESCUED_KEY_FILE}',
    'debug' => ${RESCUED_DEBUG}
  ],
  'authorize_net' => [
    'login' => '${COMMERCE_AUTHNET_AIM_LOGIN}',
    'tran_key' => '${COMMERCE_AUTHNET_AIM_TRANSACTION_KEY}',
  ],
  'ups' => [
    'accountId' => '${UPS_ACCOUNT_ID}',
    'accessKey' => '${UPS_ACCESS_KEY}',
    'userId' => '${UPS_USER_ID}',
    'password' => '${UPS_PASSWORD}',
    'pickupSchedule' => '${UPS_PICKUP_SCHEDULE}',
  ],
  'fedex' => [
    'beta' => ${FEDEX_BETA},
    'key' => '${FEDEX_KEY}',
    'password' => '${FEDEX_PASSWORD}',
    'accountNumber' => '${FEDEX_ACCOUNT_NUMBER}',
    'meterNumber' => '${FEDEX_METER_NUMBER}',
  ],
  'xdruple_shipping' => [
    'specialty' => [
      'specialty' => [
        'code' => 'SPECIALTY',
        'freightClasses' => [
          'BULK',
        ],
        'alwaysAllow' => TRUE,
        'allowedServices' => [
          'customer_pickup',
        ],
      ],
    ],
    'delivery' => [
      'local_delivery' => [
        'code' => 'DELIVERY-LOCAL',
        'rate' => 1499,
      ],
    ],
    'fedex' => [
      'fedex_ground' => [
        'code' => 'FEDEX-GROUND',
      ],
    ],
    'ups' => [
      'ups_ground' => [
        'code' => 'UPS-GROUND',
      ],
    ],
    'pickup' => [
      'customer_pickup' => [
        'code' => 'CUSTOMER-PICKUP',
      ],
    ],
  ],
];

EOF
log "Created /var/www/${ENVIRONMENT}/config/environment.php"

ENV_ALT="environment.php-${CONF_TIME}"

if [[ -e  /var/www/${ENVIRONMENT}/config/environment.php ]]; then

log "environment.php already exists, copying it as /var/www/${ENVIRONMENT}/config/environment.php-${CONF_TIME}"
log_exec sudo cp ${ENV_TMP}/environment.php /var/www/${ENVIRONMENT}/config/${ENV_ALT}

else

log "copying environment.php to /var/www/${ENVIRONMENT}/config/environment.php"
log_exec sudo cp ${ENV_TMP}/environment.php /var/www/${ENVIRONMENT}/config/environment.php

fi

}

runConsolePHP(){
XDENV_ROOT=/var/www/${ENVIRONMENT}

# Install MongoDB PHP
sudo apt-get install -q -y  pkg-config libpcre3-dev 
sleep 5
sudo pecl install mongodb

echo "extension = mongodb.so" > mongodb.ini
sudo mv mongodb.ini /etc/php5/mods-available/mongodb.ini
sudo chown root:root /etc/php5/mods-available/mongodb.ini
sudo ln -s /etc/php5/mods-available/mongodb.ini /etc/php5/cli/conf.d/20-mongodb.ini 
sudo ln -s /etc/php5/mods-available/mongodb.ini /etc/php5/fpm/conf.d/20-mongodb.ini

    # Restart PHP and Nginx
    log_exec sudo service php5-fpm restart

log_exec sudo su - ${DEPLOYER_NAME} -c "composer config --global process-timeout 600"
log_exec sudo su - ${DEPLOYER_NAME} -c "composer config --global preferred-install dist"
log_exec sudo su - ${DEPLOYER_NAME} -c "composer config --global secure-http false"
log_exec sudo su - ${DEPLOYER_NAME} -c "composer config --global github-protocols https git ssh"


sudo chown -R ${DEPLOYER_NAME}:${DEPLOYER_NAME} ${XDENV_ROOT}
log_exec sudo su - ${DEPLOYER_NAME} -c "cd ${XDENV_ROOT} && composer install"
RET=$?
    if [ $RET -ne 0 ]; then
        log "composer install failed for some reason."
        do_exit
    fi

log_exec sudo su - ${DEPLOYER_NAME} -c "cd ${XDENV_ROOT} && sudo ./console.php install:prepare:directories"
RET=$?
    if [ $RET -ne 0 ]; then
        log "console.php install:prepare:directories failed for some reason."
        do_exit
    fi

sudo chown -R ${DEPLOYER_NAME}:${DEPLOYER_NAME} ${XDENV_ROOT}
# This script drops db if exists... and the role/user... needs to change.
sleep 10
pushd ${XDENV_ROOT}
echo "${ECOMM_DB_NAME} ${ECOMM_DB_PASS} ${ECOMM_DB_USER}"
./console.php install:drupal --mongo-admin-user=${MONGO_ADMIN_USER} --mongo-admin-pass=${MONGO_ADMIN_PASS} --db-name=${ECOMM_DB_NAME} --db-pass=${ECOMM_DB_PASS} --db-user=${ECOMM_DB_USER} --user-pass=${ECOMM_XD_USER_PASS} --site-mail=${ECOMM_ADMIN_EMAIL}  --site-name="${ECOMM_NAME}"
RET=$?
    if [ $RET -ne 0 ]; then
        log "Failed: ./console.php install:drupal --mongo-admin-user=${MONGO_ADMIN_USER} --mongo-admin-pass=${MONGO_ADMIN_PASS} --db-name=${ECOMM_DB_NAME} --db-pass=${ECOMM_DB_PASS} --db-user=${ECOMM_DB_USER} --user-pass=${ECOMM_XD_USER_PASS} --site-mail=${ECOMM_ADMIN_EMAIL}  --site-name=${ECOMM_NAME}"

popd
        do_exit
    fi
popd

sudo chown -R www-data:www-data ${XDENV_ROOT}/web


}
#generateOA
#insertOA
#generateEnvPHP

show_config(){

# 9 times out of 10 this needs to be done for some reason...
sudo service nginx stop
sudo killall nginx
sudo service nginx start


if type "ec2metadata" > /dev/null; then

#prefer this if we have it and we're on EC2...

IP=`ec2metadata --public-ipv4`

else

IP=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`

fi

if [[ ${INSTALLALL} ]]; then
clear
fi

log_ec " "
log_ec " "
log_ec "     ************************************"
log_ec "     ***** IMPORTANT!!! PLEASE READ *****"
log_ec "     ************************************"
log_ec " "
log_ec "     Here is the information to get logged in!"
log_ec " "
log_ec "     First, Add the following to your system's /etc/hosts (or equivalent)"
log_ec "     ${IP} ${NGINX_ECOM_DOMAIN} ${NGINX_SITE}"
log_ec " "
log_ec "     xTuple Desktop Client Login:"
log_ec "     Server: ${IP}"
log_ec "     Port: ${PGPORT}"
log_ec "     Database: ${DATABASE}"
log_ec "     User: admin"
log_ec "     Pass: admin"
log_ec " "
log_ec "     xTuple Mobile Web Client Login:"
log_ec "     Login at https://${NGINX_SITE}"
log_ec "     User: admin"
log_ec "     Pass: admin"
log_ec " "
log_ec "     Ecommerce Site Login:"
log_ec "     Login at http://${NGINX_ECOM_DOMAIN}/login"
log_ec "     User: Developer"
log_ec "     Pass: ${ECOMM_XD_USER_PASS}"
log_ec " "
log_ec "     Misc. Info:"
log_ec "     Webroot: /var/www/${ENVIRONMENT}"
log_ec "     GitHub Token Used: ${GITHUB_TOKEN}"
log_ec " "
log_ec "     This file is ${EC_LOG_FILE} "
log_ec " "
log_ec " "

}
