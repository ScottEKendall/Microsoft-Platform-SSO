#!/bin/zsh
# Enable Company Portal SSO + autofill extensions for the console user.
# Designed to run as root so launchctl/pluginkit can reach the UI session.
# Version history:
#  1.0.0 – Initial helper (Microsoft sample)
#  1.0.1 – Added console-user lookup rather than $USER.
#  1.0.2 – Added logging and version banner.
#  1,0.3 - Added missing LOG_FILE variable

script_version="1.0.2"

LOGGED_IN_USER=$( scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
LOG_FILE=$(/var/logs/PortalAutofill.log)
USER_DIR=$( dscl . -read /Users/${LOGGED_IN_USER} NFSHomeDirectory | awk '{ print $2 }' )
USER_UID=$(id -u "$LOGGED_IN_USER")
APP_TO_CHECK="/Applications/Company Portal.app"
APP_EXTENSIONS=(
    "com.microsoft.CompanyPortalMac.ssoextension"
    "com.microsoft.CompanyPortalMac.Mac-Autofill-Extension"
)

function admin_user ()
{
    [[ $UID -eq 0 ]] && return 0 || return 1
}

function logMe () 
{
    # Basic two pronged logging function that will log like this:
    #
    # 20231204 12:00:00: Some message here
    #
    # This function logs both to STDOUT/STDERR and a file
    # The log file is set by the $LOG_FILE variable.
    # if the user is an admin, it will write to the logfile, otherwise it will just echo to the screen
    #
    # RETURN: None
    if admin_user; then
        echo "$(/bin/date '+%Y-%m-%d %H:%M:%S'): ${1}" | tee -a "${LOG_FILE}"
    else
        echo "$(/bin/date '+%Y-%m-%d %H:%M:%S'): ${1}"
    fi
}

function runAsUser () 
{  
    launchctl asuser "$USER_UID" sudo -u "$LOGGED_IN_USER" "$@"
}

function checkForFile ()
{
    # PURPOSE: Verify a file exists
    # PARAMS: #1 - Filename to check for
    # RETURN: None
    filename=$1
    if [[ ! -d "${filename}" ]]; then
        logMe "ERROR: $filename doesn't exist!"
        exit 1
    fi
    logMe "INFO: $filename found."
}

# Make sure that the app exists before checking for extensions

checkForFile $APP_TO_CHECK

# check each extension listed in the array to see if it is enabled in PlugKit

for extension in "${APP_EXTENSIONS[@]}"; do
    logMe "Checking for extension: $extension"
    results=$(runAsUser pluginkit -m | grep "${extension}")
    # Check if extension exists
    if [[ -z $results ]]; then
        logMe "Error: Extension not found: ${extension}"
        logMe "Skipping..."
        continue
    fi
    logMe "Extension found: $extension"
    # Check if the extension is enabled
    if [[ $(echo $results | awk '{print $1}') == "+" ]]; then
        logMe "$extension is already enabled"
    else
        logMe "$extension is not enabled. Enabling now..."
        runAsUser pluginkit -e use -i "${extension}"
        logMe "$extension has been enabled"
    fi
done