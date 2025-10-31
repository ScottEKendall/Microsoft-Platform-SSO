## Platform SSO with Microsoft Entra ##

This repository is designed to consolidate everything a Jamf Pro admin might need to configure Platform SSO with Microsoft Entra, and to migrate existing Macs.  I am hoping for other contributors to help make this repo a useful source of information for everything related to this framework.  The repo currently focuses on using Platform SSO with the Jamf Pro MDM, but others are welcome to share configuration files, processes, and best practices for other MDMs.

<p align="center">
  <img src="images/PlatformSSO_Icon.jpg" />
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

### Jamf Pro Configuration ###

In order to prepare for Platform SSO deployment, you must perform the following:

1. [Deploy Microsoft Company Portal](#1-company-portal)
2. [Create the Platform SSO Configuration Profile](#2-create-psso-configuration-profile)
3. [Configure ADE for Simplified Setup](#3-configure-ade-for-simplified-setup)
4. [Remove any existing SSO Extension Profile](#4-remove-the-old-sso-extension)
5. [Enable access to System Settings](#5-enable-access-to-system-settings)
6. [Make sure Touch ID is enabled](#6-enable-touch-id)
7. [Configure jamfAAD to use WebView](#7--configure-jamfaad-to-use-webview)
8. [Deliver the Platform SSO Configuration Profile](#8-deliver-the-psso-config-profile)
9. [Run Device Compliance](#9-run-device-compliance)

### Misc Stuff (Notes / Scripts / EAs)

* [Extension Attributes](#extension-attributes-ea-for-jamf)
* [Scripts](#scripts-used-for-platform-sso)
* [Changes from Extensible SSO](#changes-from-extensible-sso)

### 1. Company Portal ###

* You need to install v5.2404.0 or newer in your prestage enrollment (for new enrollments) or install via policy (to existing users).  Here's a direct download for the Company Portal installer: https://go.microsoft.com/fwlink/?linkid=853070

### 2. Create pSSO Configuration Profile ###

When setting up the Configuration Profile, you can use either the Microsoft [docs](https://learn.microsoft.com/en-us/intune/intune-service/configuration/use-enterprise-sso-plug-in-macos-with-intune?tabs=prereq-jamf-pro%2Ccreate-profile-jamf-pro) or Jamf Pro [docs](https://learn.jamf.com/en-US/bundle/technical-articles/page/Platform_SSO_for_Microsoft_Entra_ID.html#ariaid-title9).  I have included screenshots of my setup for easier reference:

![](images/JAMF_Configuration_Policy_Summary.png)
![](images/JAMF_Configuration_Policy_SSO_Payload1.png)
![](images/JAMF_Configuration_Policy_SSO_Payload2.png)
![](images/JAMF_Configuration_Policy_SSO_Payload3.png)

Please note: you must configure an Associate Domain payload, but it does NOT need to have any contents.

### 3. Configure ADE for Simplified Setup ###

You will need to make some changes to your ADE (Automated Device Enrollment) setup to take advantage of pSSO:

1. In the Jamf Pro console, navigate to Computers > PreStage Enrollment
2. In the General section, you need to "Enable Simplified setup" and add "com.microsoft.CompanyPortalMac" in the field

![](images/JAMF_ADE_General.png)

3. In the Configuration Profiles section, make sure that your Platform SSO group is checked, so it will get pushed down during new enrollments

![](images/JAMF_ADE_ConfigProfiles.png)

4. Make sure to add the Company Portal app in the Enrollment Packages section

### 4. Remove the old SSO Extension ###

You need to have a configuration profile for the Platform SSO that can be deployed.  *IMPORTANT!*  You CANNOT have both SSO Extension and Platform SSO Extension deployed to all users simultaneously.

The best way to do this is to create groupings and deploy the pSSO to the users in the group, while simultenously excluding them from the SSO Extension group.  Screenshot for exxample:

![](images/JAMF_Configuration_Policy_Groupings.png)

### 5. Enable Access to System Settings ###

You will need to make sure thate Sytem Settings -> Users & Groups is available to the users.  Inside of there are options to repair the SSO extension for users

![](images/JAMF_Users_Groups_Settings.png)

You can use the Repair option to fix any issues found during authentication.

### 6. Enable Touch ID ###

You might need to change your existing Configuration Profiles to allow the Touch ID to be accessed and enabled on systems.  If you are not going to use Secure Enclave as the preferred method for pSSO, you can ignore this setting:

![](images/JAMF_Touch_ID.png)

### 7.  Configure jamfAAD to use WebView ###

To avoid issues with browser redirection during the login process, you can configure the JamfAAD app to use WebView instead.  The following policy will perform the following:

* Force jamfAAD to use WebView
* Eanble jamfAAD logging
* Settings to recheck for a valid Entra ID
* Fixes pre-fill authentication failure on first attempt

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>useWKWebView</key>
	<true/>
	<key>logPII</key>
	<string>true</string>
	<key>OIDCUsePassThroughAuth</key>
	<true/>
	<key>OIDCNewPassword</key>
	<false/>
	<key>tokenRetryCount</key>
	<integer>3</integer>
	<key>tokenRetryWaitTime</key>
	<integer>42</integer>
  <key>disableUPNLoginHint</key>
  <true/>
</dict>
</plist>
```
Use the domain __com.jamf.management.jamfAAD__ when configuring this Config Profile

### 8. Deliver the pSSO Config Profile ###

Once you have setup your smart/static group for deployment, you can push it to all of the users. Once the profile gets installed on their Mac, they will see the following in their Notification Center.

![](https://learn.microsoft.com/en-us/intune/intune-service/configuration/media/platform-sso-macos/platform-sso-macos-registration-required.png)

And the user will need to proceed with the registration prompts.

In case the users do not see the notification center prompt (or they dismiss it), it will reappear after a period of time (I think around 15 mins), but you can "force" the prompt to reappear again.  These are a few ways that you can accomplish this:

1. You can have the user log out and log back in.
2. You can run this "faceless" script:

   ```
    #/bin/zsh
    appSSOAgentPID=$(ps -eaf | grep AppSSOAgent.app | grep -v grep | cut -d" " -f 5)
    kill -9 ${appSSOAgentPID}
    app-sso -l > /dev/null 2>&1
   ```

3. [You can show the user this GUI script I created](https://github.com/ScottEKendall/JAMF-Pro-Scripts/blob/main/ForcePlatformSSO/) that will force the prompt to reappear so the users (hopefully) don't miss it again.  This script is focus mode aware and will display an appropriate message.

<img src="https://github.com/ScottEKendall/JAMF-Pro-Scripts/raw/main/ForcePlatformSSO/ForcePlatformSSO.png" width="500" height="400">

## 9. Run Device Compliance ##

In most cases, the Device Compliance _should_ run after successful Registration, but sometimes it does fail.  If you want to avoid any failures, you need to make sure that Device Compliance is run after the user(s) registers with Platform SSO. You can do this one of two ways:

1.  Deliver a policy that executes the command ```/usr/local/jamf/bin/jamfAAD gatherAADInfo```
2.  Have the user run your Register with Entra policy from SS / SS+

![](images/JAMF_Device%20Compliance.png)

_If you do not run this Device Compliance, the user might get the "register your device" when trying to authenticate._

## Extension Attributes (EA) for Jamf Pro

I have an EA script that I use to determine user registration status and create groups accordingly. The script is multi-user aware and can be found here: https://github.com/ScottEKendall/JAMF-Pro-EAs/blob/main/InTune%20Registration%20Status.sh

![](images/JAMF_EA_Registration.png)

## Scripts used for Platform SSO ##

See the [scripts](scripts/) folder for full script contents.

### Verify Device Compliance via Extensible SSO and Platform SSO.sh

This script can be used to determine Device Compliance for both the extensible SSO (SSOe) and Platform SSO. (pSSO).  If the system is registered with Platform SSO, it still needs to acquire the AAD token.

You can test for both (Apple) Platform SSO and (JAMF) Device Compliance in one of two ways:

1.  if ```appleSSO=$(app-sso platform -s | grep "registrationCompleted" | awk -F ":" '{print $2}' | xargs | tr -d ",")``` returns ```true``` then it is apple SSO compliant
2.  if ```jamfSSO=$("/Library/Application Support/JAMF/Jamf.app/Contents/MacOS/Jamf Conditional Access.app/Contents/MacOS/Jamf Conditional Access" getPSSOStatus | head -n 1)``` returns ```2``` then it is Device Compliant

NOTE: Suposedly the ```/usr/local/jamf/bin/jamfAAD getPSSOStatus``` command _should_ return the sames results as step 2 above, but it doesn't, so it might be best to use the Step 2 command for a results test.

Why Check both?

* Because pSSO and Device Compliance are not the same thing. 
* pSSO is between macOS and Intune / Entra,
* Device compliance is between Jamf and Intune / Entra.


## Changes from Extensible SSO ##

When moving away from the (old) extensible SSO method, the "workplace join key" that was present in the Keychain will no longer be there as the functionality of the (new) pSSO has been moved into the Secure Enclave on the mac.  So users will (should) not see this image any longer:

![](images/WPJKeychain.png)

If you have any Smart/Static Groups or EAs that look for the WPJ Key in the users keychain, you need to change your logic to use the ```app-sso platform -s``` terminal command to determine SSO status.

## Reference Documentation and Resources

I am trying to stick with the company "official" docs as much as possible, but I do have an "other" section, and I will try to have comprehensive guides if possible.

### Apple Platform SSO

* [Platform Single Sign-on for macOS](https://support.apple.com/en-gb/guide/deployment/dep7bbb05313/web)

### Jamf Pro Documentation
* [Deploying macOS Platform SSO for Microsoft Entra ID with Jamf Pro](https://learn.jamf.com/en-US/bundle/technical-articles/page/Platform_SSO_for_Microsoft_Entra_ID.html)
  * [Deploying a Platform Single Sign-on Configuration Profile](https://learn.jamf.com/en-US/bundle/technical-articles/page/Platform_SSO_for_Microsoft_Entra_ID.html#ariaid-title9)

### Microsoft Documentation

* [macOS Platform Single Sign-on overview](https://learn.microsoft.com/en-us/entra/identity/devices/macos-psso)
* [Add the macOS Company Portal App](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-company-portal-macos)
* [Microsoft Enterprise SSO plug-in for Apple devices](https://learn.microsoft.com/en-us/entra/identity-platform/apple-sso-plugin)
* [Common Platform SSO scenarios for macOS devices](https://learn.microsoft.com/en-us/intune/intune-service/configuration/platform-sso-scenarios)
* [Troubleshooting the Microsoft Enterprise SSO Extension plugin on Apple devices](https://learn.microsoft.com/en-us/entra/identity/devices/troubleshoot-mac-sso-extension-plugin)
* [End-to-end guide to get started with macOS endpoints](https://learn.microsoft.com/en-gb/intune/solutions/end-to-end-guides/macos-endpoints-get-started?tabs=psso)

### FileWave Documentation

* [Microsoft Enterprise Platform Single Sign-on for macOS](https://kb.filewave.com/books/macos/page/microsoft-enterprise-platform-single-sign-on-for-macos)

### Workspace One

* [Bryan D Garmon / How to configure pSSO & Workspace One](https://www.aftersixcomputers.com/how-to-configure-apple-platform-sso-using-omnissa-workspace-one-uem/)

### Other Resources

* [IntuneMacAdmins - Configure MacOS Platform SSO](https://www.intunemacadmins.com/complete-guide-macos-deployment/configure_macos_platform_sso/)
* [SimpleMDM - How to configure Platform Single Sign-on](https://simplemdm.com/blog/how-to-configure-platform-single-sign-on/)
* [Aaron David Polley - How To Hold macOS User Identity in 2025](https://aarondavidpolley.com/how-to-hold-macos-user-identity-in-2025/)
* [benwhitis\/Jamf_Conditional_Access - MacOS Conditional Access Best Practices](https://github.com/benwhitis/Jamf_Conditional_Access/wiki/MacOS-Conditional-Access-Best-Practices)
