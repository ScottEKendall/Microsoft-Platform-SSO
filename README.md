## Plaform SSO Repository ##

This repository is designed to accomodate everything Micdrosoft Platform SSO related.  My goal is to try and consolidate everything that an admin needs to be aware of when migrating users to Platform SSO for macOS Sequoia and higher.  I am hoping for other contributors in this repo to make this a central repository for everything related to this extension.  I will be posting the information that I have concerning JAMF MDM, but others are welcome to post about configuration files / processes for other MDMs.

<p align="center">
  <img src="./PlatformSSO_Icon.jpg" />
</p>

### AI (Gemini) Overview ###
_of Extensible SSO vs Platform SSO_

Extensible SSO is the underlying framework that allows third-party extensions to enable single sign-on (SSO) on Apple devices, while Platform SSO is an evolution of this technology that provides a more deeply integrated, device-centric SSO experience for macOS. 
Platform SSO offers a more seamless sign-on process for users and deeper integration with Microsoft Entra ID (formerly Azure AD), especially for organizations that have embraced hybrid work and passwordless authentication. 

| Feature            | Extensible SSO (SSOe)                                                                                                                                       | Platform SSO (PSSO)                                                                                                                                                                                                                |
| :----------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| User experience    | Less integrated; users typically had to sign in to unlock the device and then sign in again to activate the SSO extension.                                  | Highly integrated; users sign in once with their Microsoft Entra ID credentials at the macOS login screen, eliminating the need for a second sign-in for apps.                                                                     |
| Scope              | App-centric. A third-party SSO extension could handle authentication for multiple applications, which was flexible for apps that lacked native SSO support. | Device-centric. It works at the device level and includes the underlying SSO app extension. When you configure Platform SSO, you don't need to configure the app extension separately.                                             |
| Authentication     | Supported a variety of authentication protocols, such as OAuth, OpenID Connect, and SAML2.                                                                  | Supports modern authentication methods, including passwordless authentication with a hardware-bound key (Platform Credential), smart cards, and Entra ID passwords. It also supports Kerberos-based SSO for on-premises resources. |
| Credential syncing | Did not automatically sync the local account password with the cloud identity password.                                                                     | With the password authentication method, the user's Microsoft Entra ID password is synchronized with their local macOS account password.                                                                                           |
| Prerequisites      | Requires a Mobile Device Management (MDM) profile to be deployed for the SSO app extension.                                                                 | Requires the macOS device to be enrolled in an MDM and the latest Microsoft Intune Company Portal app to be installed.                                                                                                             |
| Device enrollment  | Supports user and device enrollment.                                                                                                                        | Supports Entra ID Join for Macs, allowing any organizational user to sign into the device.                                                                                                                                         |
| Availability       | Available on iOS, iPadOS, and macOS.                                                                                                                        | Primary focus is on macOS 14+ for the best experience.                                                                                                                                                                             |


**When to use which**

For most modern deployments, Platform SSO is the recommended choice for macOS devices because of its superior user experience and tighter integration with Microsoft Entra ID. 

* Choose Platform SSO if you:
    * Want to simplify the login process for your Mac users.
    * Are adopting passwordless authentication methods.
    * Want to fully integrate your Macs with Microsoft Entra ID.
    * Manage macOS devices with Microsoft Intune or another compatible MDM.

* Use the legacy Extensible SSO framework if you:
    * Need to support older Apple devices running macOS 13 or earlier.
    * Need the flexibility to use a third-party SSO extension for specific applications.
    * Only require the SSO app extension for authentication without the deeper platform integration.

--- End AI Generated Overview ----

### JAMF Configuration ###

In order to prepare for Platform SSO deployment, you must perform the following:

1. [Deploy Microsoft Company Portal](#company-portal)
2. [Create the Platform SSO Configuration Profile](#ceate-psso-configuration-profile)
3. [Configure ADE for Simplified Setup](#configure-ade-for-simplied-setup)
4. [Remove any existing SSO Extension Profile](#removing-the-sso-exension)
5. [Enable access to the System Settings](#enable-access-to-system-settings)
6. [Make sure touchID is enabled](#enable-touchid)
7. [Deliver the PlatformSSO Configuration Profile](#deliver-the-psso-config-profile)
8. [Run Device Compliance from CompanyPorta](#8-device-compliance)

### 1. Company Portal ###

* You need to install v5.2404.0 or newer in your prestage enrollment (for new enrollments) or install via policy (to existing users).  Company Portal can be downloaded [here](https://go.microsoft.com/fwlink/?linkid=853070)

### 2. Create pSSO Configuration Profile ###

When setting up the Configuration Profile, you can use either the Microsoft [docs](https://learn.microsoft.com/en-us/intune/intune-service/configuration/use-enterprise-sso-plug-in-macos-with-intune?tabs=prereq-jamf-pro%2Ccreate-profile-jamf-pro) or JAMF [docs](https://learn.jamf.com/en-US/bundle/technical-articles/page/Platform_SSO_for_Microsoft_Entra_ID.html#ariaid-title9).  I have included screenshots of my setup for easier reference:

![](./JAMF_Configuration_Policy_Summary.png)
![](./JAMF_Configuration_Poicy_SSO_Payload1.png)
![](./JAMF_Configuration_Poicy_SSO_Payload2.png)
![](./JAMF_Configuration_Poicy_SSO_Payload3.png)

Please note: you must configure an Associate Domain payload, but it does NOT need to have anything in it, just configure it... 

### 3. Configure ADE for Simplied Setup ###

You will need to make some changes to your ADE (Automated Device Enrollment) setup to take advantage of pSSO:

1. Navigate to JAMF > Computers > Prestage Enrollment
2. In the General section, you need to "Enable Simplified setup" and add "com.microsoft.CompanyPortalMac" in the field

![](./JAMF_ADE_General.png)

3. In the Configuration Profiles section, make sure that your Platform SSO group is checked, so it will get pushed down during new enrollments

![](./JAMF_ADE_ConfigProfiles.png)

4. Make sure to add the Company Portal app in the Enrollment Packages section

### 4. Removing the (old) SSO Exension ###

You need to have a configuration profile for the Platform SSO that can be deployed.  *IMPORTANT!*  You CANNOT have both SSO Extension and Platform SSO Extension deployed to all users simultaneously.  

The best way to do this is to create groupings and deploy the pSSO to the users in the group, while simultenously excluding them from the SSO Extension group.  Screenshot for exxample:

![](./JAMF_Configuration_Policy_Groupings.png)

### 5. Enable Access to System Settings ###

You will need to make sure thate Sytem Settings -> Users & Groups is available to the users.  Inside of there are options to repair the SSO extension for users

![](JAMF_Users_Groups_Settings.png)

You can use the Repair option to fix any issues found during authentication.

### 6. Enable TouchID ###

You might need to change your existing Configuration Profiles to allow the Touch ID to be accesed/enabled on systems.  If you are not going to use Secure Enclave as the preferred method for pSSO, you can ignore this setting:

![](JAMF_Touch_ID.png)

### 7. Deliver the pSSO Config Profile ###

Once you have setup your smart/static group for deployment, you can push it to all of the users...once the profile gets installed on their mac, they will see the following in their notification center.

![](https://learn.microsoft.com/en-us/intune/intune-service/configuration/media/platform-sso-macos/platform-sso-macos-registration-required.png)

And the user will need to proceed with the registration prompts.

In case the users do not see the notification center prompt (or they dismiss it), it will reappear after a period of time (I think around 15 mins), but you can "force" the prompt to reappear again.  You can either have the user logout/login, or you can use a script I created (found [here](https://github.com/ScottEKendall/JAMF-Pro-Scripts/blob/main/ForcePlatformSSO/README.md) that will force the prompt to reappear and show a nice GUI screen so the users (hopefully) don't miss it again.

<img src="https://github.com/ScottEKendall/JAMF-Pro-Scripts/raw/main/ForcePlatformSSO/ForcePlatformSSO.png" width="500" height="400">

## 8. Device Compliance ##

You need to make sure that Device Compliance is run after the user(s) registers with Platform SSO. You can do this one of two ways:

1.  Deliver a policy that executes the command ```/usr/local/jamf/bin/jamfAAD gatherAADInfo```
2.  Have the user run your Register with Entra policy from SS / SS+

![](./JAMF_Device%20Compliance.png)

_If you do not run this Device Compliance, the user might get the "register your device" when trying to authenticate._

## Extended Attributes (EA) for JAMF

I have an EA script that I use to determine the status of the User(s) registration status and create groups accordingly.... It is multi-user aware. Script can be found [here](https://github.com/ScottEKendall/JAMF-Pro-EAs/blob/main/InTune%20Registration%20Status.sh)

![](JAMF_EA_Registration.png)

## Scripts used for Platform SSO ##

This script can be used to determine Device Compliance for both the SSO Extension and Platform SSO.  If the system is registered with Platform SSO, it still needs to acqire the AAD token.

```#!/bin/bash
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
```

## Reference Documentation ##

I am trying to stick with the company "official" docs as much as possible, but I do have an "other" section, and I will try to have comprehensive guides if possible.

Apple Platform SSO Docs

* pSSO for macOS [here](https://support.apple.com/en-gb/guide/deployment/dep7bbb05313/web)


JAMF Docs
* Platform SSO can be found [here](https://learn.jamf.com/en-US/bundle/technical-articles/page/Platform_SSO_for_Microsoft_Entra_ID.html)
* Configuration Profiles can be found [here](https://learn.jamf.com/en-US/bundle/technical-articles/page/Platform_SSO_for_Microsoft_Entra_ID.html#ariaid-title9)

Microsoft Links:
* Overview of pSSO [here](https://learn.microsoft.com/en-us/entra/identity/devices/macos-psso)
* Company portal can be found [here](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-company-portal-macos)
* SSO Plugin for Apple Devices [here](https://learn.microsoft.com/en-us/entra/identity-platform/apple-sso-plugin)
* Common pSSO scenerios [here](https://learn.microsoft.com/en-us/intune/intune-service/configuration/platform-sso-scenarios)

Other Links:

* Comprehensive guide on configuring inTune for pSSO / inTune MacAdmins [here:](https://www.intunemacadmins.com/complete-guide-macos-deployment/configure_macos_platform_sso/)
* How to configure pSSO / SimpleMDM [here](https://simplemdm.com/blog/how-to-configure-platform-single-sign-on/)