#!/bin/bash


inspect_this_db(){
unset APPLY_FOUNDATION
PKGEXTLIST='XDRUPLE QUALITY REGMGMT DISTRIBUTION MANUFACTURING INVENTORY COMMERCIALCORE'

BUILDMSG+="${DATABASE} is xTuple ${XTAPP} Edition v${XTVER}\n\n"

for PKGEXT in ${PKGEXTLIST}; do
`unset HAS_${PKGEXT}_EXT`
`unset HAS_${PKGEXT}_PKG`
if [[ ${XTEXT} == *"${PKGEXT,,}"* ]]; then
declare "HAS_${PKGEXT}_EXT=true"
declare "UPGRADE_${PKGEXT}_EXT=true"
hasext="HAS_${PKGEXT}_EXT"
upext="UPGRADE_${PKGEXT}_EXT"
BUILDMSG+="${PKGEXT,,} ext is installed."
fi

if [[ ${XTPKG} == *"${PKGEXT,,}"* ]]; then
declare "HAS_${PKGEXT}_PKG=true"
declare "UPGRADE_${PKGEXT}_PKG=true"
haspkg="HAS_${PKGEXT}_PKG"
uppkg="UPGRADE_${PKGEXT}_PKG"

BUILDMSG+="${PKGEXT,,} pkg is installed."
fi
done

if [[ ${HASMWC} == "f" ]]; then
BUILDMSG+="* No existing MWC Extensions\n"
BUILD_EXTENSIONS="true"
FRESH_XDRUPLE="true"
fi

if [[ ${XTAPP} == "PostBooks" ]]; then
APPLY_FOUNDATION='-f'
fi

if [[ ${XTEXT} ]]; then
BUILDMSG+="* MWC Extensions: \n ${XTEXT}\n\n"
fi

if [[ ${XTEXT} == *"xdruple"* ]]; then
HAS_XDRUPLE_EXT="true"
UPGRADE_XDRUPLE_EXT="true"
fi

if [[ ${XTEXT} == *"quality"* ]]; then
HAS_QUALITY_EXT="true"
UPGRADE_QUALITY_EXT="true"
fi

if [[ ${XTEXT} == *"regmgmt"* ]]; then
HAS_REGMGMT_EXT="true"
UPGRADE_REGMGMT_EXT="true"
fi

if [[ ${XTPKG} == *"quality"* ]]; then
BUILDMSG+="* Your installation has quality QT Components\n"
HAS_QUALITY_PKG="true"
UPGRADE_QUALITY_PKG="true"
fi

if [[ ${XTPKG} == *"regmgmt"* ]]; then
BUILDMSG+="* Your installation has Registration Management QT Components\n"
HAS_REGMGMT_PKG="true"
UPGRADE_REGMGMT_PKG="true"
fi

if [[ ${XTPKG} == *"xdruple"* ]]; then
BUILDMSG+="* Your installation has xDruple QT Components\n"
HAS_XDRUPLE_PKG="true"
UPGRADE_XDRUPLE_PKG="true"
fi

if [[ ${XTPKG} ]]; then
BUILDMSG+="* Packages: \n ${XTPKG}\n"
fi

if [[ ${INSTALLALL} ]]; then
log "${BUILDMSG}"

else
whiptail --backtitle "$( window_title )" --msgbox "${BUILDMSG}" 25 65 3>&1 1>&2 2>&3

fi

# exit
}


build_app_fun()
{

if [[ ${HAS_XDRUPLE_EXT} == "true" ]]; then 
log "If it has xdruple ext, then it has to have mwc... \
We already know if PostBooks. If xtver is 4.9.5, we'll have APPLY_FOUNDATION set \
 And we don't need to ask if they want to install xdruple."

log_exec sudo su - xtuple -c "cd $XTDIR && ./scripts/build_app.js -c /etc/xtuple/$MWCVERSION/"$MWCNAME"/config.js"
    RET=$?
    if [ $RET -ne 0 ]; then
        log "buildapp failed to run. Check output and try again"
        do_exit
    fi
log "Build_app was a success!"

else

log "We don't have xDruple, let's see check for MWC and if we want to install xDruple"

   if [[ ${HASMWC} == "f" && ${XDRUPLEEXT} == "true" && ${XTAPP} == "PostBooks" && ${XTVER} == "4.9.5"  ]]; then
   log "This is the first case - does not have mwc and wants to install xdruple."
   log "We'll run build_app.js for the core, and again for xDruple"
   log "We've already determined if this is PostBooks 4.9.5 and if APPLY_FOUNDATION needs to be done"

	log_exec sudo su - xtuple -c "cd $XTDIR && ./scripts/build_app.js -c /etc/xtuple/$MWCVERSION/"$MWCNAME"/config.js "$APPLY_FOUNDATION""
	    RET=$?
	    if [ $RET -ne 0 ]; then
	        log "buildapp Core failed to run. Check output and try again"
	        do_exit
	    fi
# We can check for the private extensions dir...
if [[ -d /opt/xtuple/${MWCVERSION}/${MWCNAME}/private-extensions ]]; then
	log_exec sudo su - xtuple -c "cd $XTDIR && ./scripts/build_app.js -c /etc/xtuple/$MWCVERSION/"$MWCNAME"/config.js -e ../private-extensions/source/inventory "$APPLY_FOUNDATION""
	    RET=$?
	    if [ $RET -ne 0 ]; then
	        log "buildapp Inventory failed to run. Check output and try again"
        	do_exit
	    fi

	log_exec sudo su - xtuple -c "cd $XTDIR && ./scripts/build_app.js -c /etc/xtuple/$MWCVERSION/"$MWCNAME"/config.js -e ../private-extensions/source/xdruple"
	    RET=$?
	    if [ $RET -ne 0 ]; then
        	log "buildapp xDruple failed to run. Check output and try again"
	        do_exit
	    fi
else
msgbox "Commercial Extensions for ${MWCNAME}/private-extensions doesn't exist."
fi

   elif [[ ${HASMWC} == "t" && ${XDRUPLEEXT} == "true" ]]; then
   log "This is the second case - Has mwc, and wants to install xdruple."
   log "We'll run build_app.js for the core, and specify -e path to ../private-extensions/source/xdruple"
   log "We've already determined if this is PostBooks and if APPLY_FOUNDATION needs to be done"

log_exec sudo su - xtuple -c "cd $XTDIR && ./scripts/build_app.js -c /etc/xtuple/$MWCVERSION/"$MWCNAME"/config.js -e ../private-extensions/source/xdruple "$APPLY_FOUNDATION""
	    RET=$?
	    if [ $RET -ne 0 ]; then
        	log "buildapp xDruple failed to run. Check output and try again"
	        do_exit
	    fi


   elif [[ ${HASMWC} == "t" && ${XDRUPLEEXT} == "false" ]]; then
   log "This is the third case - Has mwc, does not want to install xdruple. \
We just need to run build_app. "
   else
log "Not sure how we got here with"
log "${HASMWC} ${XDRUPLEEXT} ${HAS_XDRUPLE_EXT}"
   fi

   log "I think this is good."


fi
}
