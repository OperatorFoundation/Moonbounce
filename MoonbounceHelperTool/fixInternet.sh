#!/bin/sh

logMessage()
{
	echo "${@}"
}

resetPrimaryInterface()
{
	set +e # "grep" will return error status (1) if no matches are found, so don't fail on individual errors
	WIFI_INTERFACE="$(networksetup -listallhardwareports | awk '$3=="Wi-Fi" {getline; print $2}')"
	if [ "${WIFI_INTERFACE}" == "" ] ; then
		WIFI_INTERFACE="$(networksetup -listallhardwareports | awk '$3=="AirPort" {getline; print $2}')"
    fi
	PINTERFACE="$( scutil <<-EOF |
        open
        show State:/Network/Global/IPv4
        quit
EOF
    grep PrimaryInterface | sed -e 's/.*PrimaryInterface : //'
    )"
    set -e # resume abort on error

    if [ "${PINTERFACE}" != "" ] ; then
	    if [ "${PINTERFACE}" == "${WIFI_INTERFACE}" -a "${OSVER}" != "10.4" -a -f /usr/sbin/networksetup ] ; then
		    if [ "${OSVER}" == "10.5" ] ; then
			    logMessage "Resetting primary interface '${PINTERFACE}' via networksetup -setairportpower off/on..."
				/usr/sbin/networksetup -setairportpower off
				sleep 2
				/usr/sbin/networksetup -setairportpower on
			else
				logMessage "Resetting primary interface '${PINTERFACE}' via networksetup -setairportpower ${PINTERFACE} off/on..."
				/usr/sbin/networksetup -setairportpower "${PINTERFACE}" off
				sleep 2
				/usr/sbin/networksetup -setairportpower "${PINTERFACE}" on
			fi
		else
		    if [ -f /sbin/ifconfig ] ; then
			    logMessage "Resetting primary interface '${PINTERFACE}' via ifconfig ${PINTERFACE} down/up..."
                /sbin/ifconfig "${PINTERFACE}" down
                sleep 2
			    /sbin/ifconfig "${PINTERFACE}" up
			else
				logMessage "WARNING: Not resetting primary interface because /sbin/ifconfig does not exist."
			fi
		fi
    else
        logMessage "WARNING: Not resetting primary interface because it cannot be found."
    fi
}

resetPrimaryInterface
