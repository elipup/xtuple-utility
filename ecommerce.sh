#!/bin/bash

setup_ecommerce() {
    php_prompt
    RET=$?
    if [ $RET -ne 0 ]; then
        return $RET
    fi

    set_ecommerce_info
    RET=$?
    if [ $RET -ne 0 ]; then
        return $RET
    fi
    
#    log_choice install_postgresql 9.3
#    log_choice drop_cluster 9.3 main auto
    
#    provision_ecom_cluster
#    RET=$?
#    if [ $RET -ne 0 ]; then
#        msgbox "Error while provisioning a postgres eCommerce cluster."
#        return $RET
#    fi
    
#    configure_postfix
#    RET=$?
#    if [ $RET -ne 0 ]; then
#        msgbox "Error while configuring postfix"
#        return $RET
#    fi
    
    install_nginx
    RET=$?
    if [ $RET -ne 0 ]; then
        msgbox "Error while installing nginx"
	   return $RET
    fi
    prep_nginx
    configure_nginx_ecom
    
    configure_php
    RET=$?
    if [ $RET -ne 0 ]; then
        msgbox "Error while configuring php."
        return $RET
    fi

    install_composer
    RET=$?
    if [ $RET -ne 0 ]; then
        msgbox "Error while configuring composer."
        return $RET
    fi

    configure_mongo
    RET=$?
    if [ $RET -ne 0 ]; then
        msgbox "Error while configuring mongo."
        return $RET
    fi
}
