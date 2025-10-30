# copyright 2024, JAMF Software, LLC
# THE SOFTWARE IS PROVIDED "AS-IS," WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
# IN NO EVENT SHALL JAMF SOFTWARE, LLC OR ANY OF ITS AFFILIATES BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OF OR OTHER DEALINGS IN THE SOFTWARE,
# INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR PUNITIVE DAMAGES AND OTHER DAMAGES SUCH AS LOSS OF USE, PROFITS, SAVINGS, TIME OR DATA, BUSINESS INTERRUPTION, OR PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES.
#get logged in user

getValueOf ()
{
  echo $2 | grep "$1" | awk -F ":" '{print $2}' | tr -d "," | xargs
}

# Prompt the user to register if needed
loggedInUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
if [[ -z "$loggedInUser" ]]; then
  echo "no logged in User"
    exit 1
fi

ssoStatus=$(su -l $loggedInUser -c "app-sso platform -s")
if [[ $(getValueOf registrationCompleted "$ssoStatus") != true ]]; then
    su -l $loggedInUser -c "/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access gatherAADInfo"
  echo "Registered via Platform SSO"
    exit 0
fi

#get user home directory
userHome=$(dscl . read "/Users/$loggedInUser" NFSHomeDirectory | awk -F ' ' '{print $2}')
#Check if wpj key is present
WPJKey=$(su -l $loggedInUser -c "/usr/bin/security dump $userHome/Library/Keychains/login.keychain-db | grep MS-ORGANIZATION-ACCESS")
if [[ ! -z "$WPJKey" ]]; then
    #run gatherAADInfo
    su -l $loggedInUser -c "/Library/Application\ Support/JAMF/Jamf.app/Contents/MacOS/Jamf\ Conditional\ Access.app/Contents/MacOS/Jamf\ Conditional\ Access gatherAADInfo"
    exit 0
fi
echo "no WPJ key found"
exit 1
