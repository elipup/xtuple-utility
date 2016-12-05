#!/bin/bash
mobileextras_menu() {

    log "Opened MobileExtra menu"

    ACTIONS=$(whiptail --separate-output --title "Select Components" --checklist --cancel-button "Cancel" \
    "Please choose the Packages or Extensions you would like to install" 15 60 7 \
    "xdruple" "xDruple Ecommerce Extension" OFF \
    "quality" "Quality Extension" OFF \
    3>&1 1>&2 2>&3)

    RET=$?
    if [ $RET = 0 ]; then
        for i in $ACTIONS; do   
            case "$i" in
            "xdruple") msgbox "xDruple not implemented yet"
                         ;;
            "quality") msgbox "Quality not implemented yet"
                         ;;
             *) ;;
            esac || main_menu
        done
    fi

    if [ -n "$ACTIONS" ]; then
        msgbox "The following actions were completed: \n$ACTIONS" 
    elif [ -z "$ACTIONS" ]; then
        msgbox "No actions were taken."
    fi
    return 0;
}
