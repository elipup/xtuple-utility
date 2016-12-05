#!/bin/bash

getsettoken(){
log "In: ${BASH_SOURCE} ${FUNCNAME[0]}"
if [[ -e oatokens.txt ]]; then
     AUTHKEYS+=$(<oatokens.txt)
fi

if [[ -z $AUTHKEYS ]]; then
whiptail --backtitle "$( window_title )" --msgbox "Let's set up your github personal access token or find existing ones on your system. \
You will have an option to select existing, manually enter, or generate a new one." 10 60 3>&1 1>&2 2>&3

get_composer_token

generate_github_token
ssh_setup
composer config --global github-oauth.github.com ${GITHUB_TOKEN}

cat <<EOF>> oatokens.txt
${GITHUB_TOKEN}
EOF

else

AUTHKEYCNT=( $AUTHKEYS )
TAGCNT=${#AUTHKEYCNT[@]}
TAGCNT1=$( expr ${TAGCNT} + 1)
TAGCNT2=$( expr ${TAGCNT} + 2)
TAGCNTM1=$( expr ${TAGCNT} - 1)

MENUVER=$(whiptail --backtitle "$( window_title )" --menu "Choose GitHub Personal Access Token" 15 60 7 --cancel-button "Exit" --ok-button "Select" \
        $(paste -d '\n' \
        <(seq 0 ${TAGCNTM1}) \
        <(echo "${AUTHKEYS}" | tr ' ' '\n')) \
        "${TAGCNT1}" "Manually Enter Token" \
        "${TAGCNT2}" "Generate New Token" \
        3>&1 1>&2 2>&3)

   RET=$?

    if [ $RET -eq 0 ]; then
        if [[ $MENUVER -eq ${TAGCNT} ]]; then
            return 0;

        elif [[ $MENUVER -lt ${TAGCNT1} ]]; then

            read -a tagversionarray <<< $AUTHKEYS
            GITHUB_TOKEN=${tagversionarray[$MENUVER]}

        elif [[ $MENUVER -eq ${TAGCNT1} ]]; then

            GITHUB_TOKEN=$(whiptail --backtitle "$( window_title )" --inputbox "Enter your GitHub Personal Access Token" 8 60 3>&1 1>&2 2>&3)
            RET=$?
             if [ $RET -ne 0 ]; then
              return $RET
             fi
cat <<EOF>> oatokens.txt
${GITHUB_TOKEN}
EOF


        elif [[ $MENUVER -eq ${TAGCNT2} ]]; then

            generate_github_token

       fi

declare file=oatokens.txt
declare regex="${GITHUB_TOKEN}"
declare file_content=$( cat "${file}" )
if [[ " $file_content " =~ $regex  ]]
    then

# whiptail --backtitle "$( window_title )" --msgbox "You've selected an existing token: ${GITHUB_TOKEN}" 8 60 3>&1 1>&2 2>&3

composer config --global github-oauth.github.com ${GITHUB_TOKEN}

 fi

     return $RET

    fi
        
        # log_exec sudo su xtuple -c "cd /opt/xtuple/$MWCVERSION/"$MWCNAME" && git clone https://${GITHUB_TOKEN}:x-oauth-basic@github.com/xtuple/xdruple-extension.git && cd /opt/xtuple/$MWCVERSION/"$MWCNAME"/xdruple-extension && git submodule update --init --recursive && npm install"
#    else
#        log "Not installing the xDruple extension"
# fi

      

fi    
echo "End Up Here if There is no Composer token found, and we manually enter the token."

}
