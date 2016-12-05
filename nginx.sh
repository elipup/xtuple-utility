#!/bin/bash

nginx_menu() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    log "Opened nginx menu"

    while true; do
        NGM=$(whiptail --backtitle "xTuple Utility v$_REV" --menu "$( menu_title nginx\ Menu )" 0 0 4 --cancel-button "Cancel" --ok-button "Select" \
            "1" "Install nginx" \
            "2" "Configure nginx for ERP" \
		  "3" "Configure nginx for eCommerce" \
            "4" "Remove nginx" \
            "5" "Return to main menu" \
            3>&1 1>&2 2>&3)

        RET=$?

        if [ $RET -ne 0 ]; then
            break
        else
            case "$NGM" in
            "1") log_choice install_nginx ;;
            "2") log_choice configure_nginx_mwc ;;
		  "3") log_choice configure_nginx_ecom ;;
            "4") log_choice remove_nginx ;;
            "5") break ;;
            *) msgbox "How did you get here? nginx_menu $NGM" && break ;;
            esac
        fi
    done

}

install_nginx() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    log "Installing nginx"
    log_arg

    log_exec sudo apt-get -y install nginx
    RET=$?
    if [ $RET -ne 0 ]; then
        msgbox "Nginx failed to install."
        return $RET
    fi
}

clear_nginx_settings() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    unset NGINX_HOSTNAME
    unset NGINX_DOMAIN
    unset NGINX_SITE
    unset NGINX_CERT
    unset NGINX_KEY
    unset NGINX_PORT
}


nginx_prompt() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    if [ -z $NGINX_HOSTNAME ]; then
        NGINX_HOSTNAME=$(whiptail --backtitle "$( window_title )" --inputbox "Host name (the domain comes next)" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_HOSTNAME
        fi
    fi

    if [ -z $NGINX_DOMAIN ]; then
        NGINX_DOMAIN=$(whiptail --backtitle "$( window_title )" --inputbox "Domain name (example.com)" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_DOMAIN
        fi
    fi

    if [ -z $NGINX_SITE ]; then
        NGINX_SITE=$(whiptail --backtitle "$( window_title )" --inputbox "Site name. This will be the name of the config file." 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_SITE
        fi
    fi

    if [ -z $GEN_SSL ]; then
        if (whiptail --title "Generate SSL key" --yesno "Would you like to generate a self signed SSL certificate and key?" 10 60) then
            GEN_SSL=true
	   else
	       GEN_SSL=false
	   fi
	   export GEN_SSL
    fi

    if [ -z $NGINX_CERT ]; then
        NGINX_CERT=$(whiptail --backtitle "$( window_title )" --inputbox "SSL Certificate file path" 8 60 "/etc/xtuple/ssl/server.crt" 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_CERT
        fi
    fi

    if [ -z $NGINX_KEY ]; then
        NGINX_KEY=$(whiptail --backtitle "$( window_title )" --inputbox "SSL Key file path" 8 60 "/etc/xtuple/ssl/server.key" 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_KEY
        fi
    fi

    if [ -z $NGINX_PORT ]; then
        NGINX_PORT=$(whiptail --backtitle "$( window_title )" --inputbox "Upstream Port number.  Make sure it is available first!" 8 60 "8443" 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_PORT
        fi
    fi
}

prep_nginx() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original
    sudo cp $WORKDIR/nginx/nginx.conf /etc/nginx/

    sudo mv /etc/nginx/mime.types /etc/nginx/mime.types.original
    sudo cp $WORKDIR/nginx/mime.types /etc/nginx/

    sudo mv /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.original
    sudo cp $WORKDIR/nginx/fastcgi_params /etc/nginx/

    sudo cp -R $WORKDIR/nginx/apps /etc/nginx/
    sudo cp -R $WORKDIR/nginx/conf.d/* /etc/nginx/conf.d/

    # Set default domain to return 404 for non-setup URLs
    sudo cp $WORKDIR/nginx/sites-available/default.conf.template /etc/nginx/sites-available/default.http.conf && \
    sudo ln -s /etc/nginx/sites-available/default.http.conf /etc/nginx/sites-enabled/default.http.conf

    sudo rm /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default 2>&1 >/dev/null
}

# $1 is hostname for nginx
# $2 is domain name
# $3 is the site name to use
# $4 is to generate an ssl key
# $5 specifies a cert file
# $6 specifies a key file
# $7 is the port to use
configure_nginx_mwc()
{
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    log "Configuring nginx"

    if [ -n "$1" ]; then
        NGINX_HOSTNAME=$1
    fi

    if [ -n "$2" ]; then
        NGINX_DOMAIN=$2
    fi

    if [ -n "$3" ]; then
        NGINX_SITE=$3
    fi

    if [ -n "$4" ]; then
        GEN_SSL=$4
    fi

    if [ -n "$5" ]; then
        NGINX_CERT=$5
    fi

    if [ -n "$6" ]; then
        NGINX_KEY=$6
    fi

    if [ -n "$7" ]; then
        NGINX_PORT=$7
    fi

    NGINX_FQDN=${NGINX_HOSTNAME}.${NGINX_DOMAIN}

    nginx_prompt
    RET=$?
    if [ $RET -ne 0 ]; then
        return $RET
    fi

    log_arg $NGINX_HOSTNAME $NGINX_DOMAIN $NGINX_SITE $NGINX_CERT $NGINX_KEY $NGINX_PORT

    prep_nginx

    log_exec sudo cp $WORKDIR/templates/nginx-site /etc/nginx/sites-available/$NGINX_FQDN
    log_exec sudo sed -i -e "s#DOMAINNAME#$NGINX_DOMAIN#" -e "s#HOSTNAME#$NGINX_HOSTNAME#" /etc/nginx/sites-available/$NGINX_FQDN
    RET=$?
    if [ $RET -ne 0 ]; then
        msgbox "Error configuring nginx.  Check site file in /etc/nginx/sites-available"
        return $RET
    fi

    log_exec sudo ln -s /etc/nginx/sites-available/$NGINX_FQDN /etc/nginx/sites-enabled/$NGINX_FQDN

    if [ -z "$4" ] || [ "$4" = "true" ]; then
        log_exec sudo mkdir -p /etc/xtuple/ssl
        log_exec sudo openssl req -x509 -newkey rsa:2048 -subj /CN=$NGINX_FQDN -days 365 -nodes \
            -keyout $NGINX_KEY -out $NGINX_CERT
        RET=$?
        if [ $RET -ne 0 ]; then
            msgbox "SSL Certificate creation failed."
            return $RET
        fi
    fi


   log_exec sudo sed -i -e 's#SERVER_CRT#'$NGINX_CERT'#g' -e 's#SERVER_KEY#'$NGINX_KEY'#g' /etc/nginx/sites-available/$NGINX_FQDN
   log_exec sudo sed -i 's#MWCPORT#'$NGINX_PORT'#g' /etc/nginx/sites-available/$NGINX_FQDN

    log_exec sudo service nginx reload
    RET=$?
    if [ $RET -ne 0 ]; then

        msgbox "Reloading nginx configuration failed. Check the log file for errors."
        return $RET
    else
	if [[ ${INSTALLALL} ]]; then
        log "nginx installed and configured successfully."
	else
        msgbox "nginx installed and configured successfully."
	fi
    fi
}

nginx_ecom_prompt() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    if [ -z $NGINX_ECOM_DOMAIN ]; then
        NGINX_ECOM_DOMAIN=$(whiptail --backtitle "$( window_title )" --inputbox "Domain name for ecommerce" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_ECOM_DOMAIN
        fi
    fi
    
    if [ -z $NGINX_DOMAIN_ALIAS ]; then
        NGINX_DOMAIN_ALIAS=$(whiptail --backtitle "$( window_title )" --inputbox "Domain Alias" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export NGINX_DOMAIN_ALIAS
        fi
    fi

    if [ -z $HTTP_AUTH_PASS ]; then
        HTTP_AUTH_PASS=$(whiptail --backtitle "$( window_title )" --inputbox --passwordbox "HTTP Authorization Password" 8 60 3>&1 1>&2 2>&3)
        RET=$?
        if [ $RET -ne 0 ]; then
            clear_nginx_settings
            return $RET
        else
            export HTTP_AUTH_PASS
        fi
    fi
}

configure_nginx_ecom() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    log "Configuring nginx"

    if [ -n "$1" ]; then
        NGINX_ECOM_DOMAIN=$1
    fi

# What's this?    
    if [ -n "$2" ]; then
        NGINX_DOMAIN_ALIAS=$2
    fi

# don't do the htaccess...
    if [ -n "$3" ]; then
        HTTP_AUTH_PASS=$3
    fi

    nginx_ecom_prompt
    
    prep_nginx

# Include these changes into the general Nginx Site Configuration.
# Environment should be variable
# Include SSL by default in each domain config.  Do not separate it out into /conf.d
# And Create them one at a time.
# Basically create  it the way we do it for a mobile site, but include the xdruple stuff.

  #  environments=("dev" "stage" "live")
  #  for ENVIRONMENT in "${environments[@]}"

log "Environment is ${ENVIRONMENT}"
if [ -n "${ENVIRONMENT}" ];
then
    
        # Set dev and live domain aliases (for development)
        log_exec sudo cp $WORKDIR/nginx/sites-available/stage.conf.template /etc/nginx/sites-available/${ENVIRONMENT}.http.conf
        log_exec sudo sed -i "s/{DOMAIN_ALIAS}/${NGINX_DOMAIN_ALIAS}/g" /etc/nginx/sites-available/${ENVIRONMENT}.http.conf
        log_exec sudo sed -i "s/{ENVIRONMENT}/${ENVIRONMENT}/g" /etc/nginx/sites-available/${ENVIRONMENT}.http.conf
        log_exec sudo ln -s /etc/nginx/sites-available/${ENVIRONMENT}.http.conf /etc/nginx/sites-enabled/${ENVIRONMENT}.http.conf

        log_exec sudo mkdir -p /var/log/nginx/${ENVIRONMENT}
        log_exec sudo mkdir -p /var/www/${ENVIRONMENT}

#        # Set real domain for production usage (with or without SSL)
#        if [ ${ENVIRONMENT} = "live" ]
#        then
#            if [ ${SSL} = "ssl" ]
#            then
#                log_exec sudo cp $WORKDIR/nginx/sites-available/https.conf.template /etc/nginx/sites-available/https.conf
#                log_exec sudo sed -i "s/{DOMAIN}/${NGINX_ECOM_DOMAIN}/g" /etc/nginx/conf.d/ssl.conf
#                log_exec sudo sed -i "s/{DOMAIN}/${NGINX_ECOM_DOMAIN}/g" /etc/nginx/sites-available/https.conf
#                log_exec sudo sed -i "s/{ENVIRONMENT}/${ENVIRONMENT}/g" /etc/nginx/sites-available/https.conf
#                log_exec sudo ln -s /etc/nginx/sites-available/https.conf /etc/nginx/sites-enabled/https.conf
#            else
#                log_exec sudo cp $WORKDIR/nginx/sites-available/http.conf.template /etc/nginx/sites-available/http.conf
#                log_exec sudo sed -i "s/{DOMAIN}/${NGINX_ECOM_DOMAIN}/g" /etc/nginx/sites-available/http.conf
#                log_exec sudo sed -i "s/{ENVIRONMENT}/${ENVIRONMENT}/g" /etc/nginx/sites-available/http.conf
#                log_exec sudo ln -s /etc/nginx/sites-available/http.conf /etc/nginx/sites-enabled/http.conf
#            fi
#        fi
#    done
else
log "No ENVIRONMENT set"
fi

    log_exec sudo chown -R ${DEPLOYER_NAME}:${DEPLOYER_NAME} /var/www/*

    log_exec sudo htpasswd -b -c /var/www/.htpasswd xtuple ${HTTP_AUTH_PASS}

    log_exec sudo service nginx restart
}

remove_nginx() {
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

    if (whiptail --title "Are you sure?" --yesno "Uninstall nginx?" --yes-button "Yes" --no-button "No" 10 60) then
        log "Uninstalling nginx..."
        log_exec sudo apt-get -y remove nginx
        RET=$?
        return $RET
    else
        return 0
    fi

}

set_local_hosts(){
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

(echo '127.0.0.1 '${NGINX_ECOM_DOMAIN} ${NGINX_SITE}'') | sudo tee -a /etc/hosts >/dev/null

}

setup_shop_prodiem(){
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"
log "ENV is ${ENVIRONMENT}"
log "NGINX_ECOM_DOMAIN is ${NGINX_ECOM_DOMAIN}"

sudo mkdir -p /var/log/nginx/${ENVIRONMENT}

(echo '

## Return (no rewrite) server block.
#server {
#    listen 80;
#    server_name '${NGINX_ECOM_DOMAIN}';
#    return 301 $scheme://'${NGINX_ECOM_DOMAIN}'$request_uri;
#}

server {
    listen 80;
    server_name '${NGINX_ECOM_DOMAIN}';
    limit_conn arbeit 32;

    access_log /var/log/nginx/'${ENVIRONMENT}'/access.log;
    error_log /var/log/nginx/'${ENVIRONMENT}'/error.log;
    root /var/www/'${ENVIRONMENT}'/drupal/core;
    include apps/drupal/security.conf;
    include apps/drupal/drupal.conf;
}'
) | sudo tee -a /etc/nginx/sites-enabled/${ENVIRONMENT}.conf >/dev/null

}


# This is ignored.
setup_erp_prodiem(){

log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"

(echo '
upstream node-erp {
  server 127.0.0.1:8443;
}

# auto redirect http -> https
server {
  listen 80;
  server_name erp.prodiem.xd;
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl;
  ssl on;
  ssl_certificate /etc/xtuple/ssl/server.crt;
  ssl_certificate_key /etc/xtuple/ssl/server.key;

  server_name erp.prodiem.xd;

  index index.html index.htm;

  access_log /var/log/nginx/erp.prodiem.xd.access.log;
  error_log /var/log/nginx/erp.prodiem.xd.error.log;

  # https://wiki.mozilla.org/Security/Server_Side_TLS
  ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
  ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA;
  ssl_prefer_server_ciphers on;
#  ssl_dhparam /etc/ssl/certs/dhparam.pem;
#  ssl_session_cache shared:SSL:60m;
  ssl_session_timeout 60m;

  location / {
    proxy_pass https://node-erp;
    proxy_redirect off;
    proxy_set_header X-NginX-Proxy true;
    proxy_set_header Host $http_host;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;

    # for socket.io
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";

    #error_page 502 = @handle_node_down;
  }

  # 502 gateway error, the upstream node service is likely down
  location @handle_node_down {
    # show a nice picture of a bunny or something
  }
}') | sudo tee -a /etc/nginx/sites-enabled/erp.prodiem.xd.conf >/dev/null


}


