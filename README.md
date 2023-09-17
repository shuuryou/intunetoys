# Intune Toys

Managing a corporate desktop environment entails more than just setting up systems; it also involves ensuring a distraction-free workspace and automating essential configurations.

While Microsoft Intune and Windows Autopilot go a long way in making this task easier, they have their limitations. This repository contains things that I needed but couldn't find (or wasn't satisfied with) while setting up Intune and Windows Autopilot in Microsoft 365. They're designed to address common challenges faced by administrators.

## Disclaimer

Always test in a controlled environment before deploying in a production scenario. Everything here is provided as-is with no warranties.

## RemoveModernApps PowerShell Script

This PowerShell script is designed for use with Microsoft Intune. It's purpose is to automatically uninstall and deprovision bundled shovelware apps (Cortana, Weather, Xbox, etc.) in Windows 11 Enterprise. These apps might be considered unsuitable distractions for users of managed corporate desktop environments.

While Intune has built-in app uninstall functionality, it's inadequate for managing certain modern apps - for instance, Cortana or the Solitaire Collection cannot be removed using that function. In addition, it appears to stop working completely if the Microsoft Store is disabled using policy. This script was created to bridge these gaps.

### Overview

- **Script Name**: RemoveModernApps.ps1
- **Purpose**: Uninstall and deprovision the specified Microsoft apps in Windows 11 Enterprise.
- **Log Output**: `%WINDIR%\Temp\Onboarding-RemoveModernApps.log`

### Usage

1. Open the [Intune Admin Center](https://endpoint.microsoft.com)
1. Go to **Devices** > **Scripts**
1. Click **Add** > **Windows 10 and later**
1. Enter something into the **Name** text box (e.g. _Microsoft Shovelware App Remover_) and click **Next**
1. Upload the script using the **Script location** field
1. Set **Run this script using the logged on credentials** to **No**
1. Set **Enforce script signature check** to **No**
1. Set **Run script in 64 bit PowerShell Host** to **Yes**
1. Click **Next**
1. Assign the script to your computers, e.g. by clicking **Add all devices** or similar, then click **Next**
1. Click **Add**

### Customizing the Script

You may wish to remove apps from the list in the script if you require them in your organization. Once apps are removed by this script, it can be a bit cumbersome to get them back. To do this, edit the `$Crap` variable as required.

The following apps are removed by default:

* 3D Builder
* Bing apps (News, Weather)
* Calendar and Mail
* Clip Champ Video Editor
* Cortana
* Get Help
* Get Started
* Maps
* Microsoft To-Do
* Movies and TV
* Music
* Office (for home users)
* OneNote
* People
* Photos
* Skype
* Solitaire Collection
* Sway
* Teams (for home users)
* Windows Feedback Hub
* Xbox crap
* Your Phone

### Benefits

- Removes all shovelware apps from a stock Windows 11 Enterprise install by default
- Keeps the Microsoft Store (which can be disabled by policy)
- Keeps useful productivity tools like Calculator, Notepad, Paint, Screen & Sketch (Snipping Tool), Sticky Notes, etc.
- Reduces support overhead by eliminating confusion: users don't have to differentiate between two versions of MS Teams, the Mail app and Outlook, etc.
- Works with Windows Autopilot so that users are onboarded into a clean desktop and never even see Microsoft's shovelware

## SetOSTimeZone PowerShell Script

This PowerShell script is designed for use with Microsoft Intune. Its primary purpose is to set the time zone of a computer based on its external IP address. This is especially useful for fully automated Windows Autopilot deployment scenarios. To accomplish its task, it uses the [ipapi.co](https://ipapi.co/) service, which allows for up to 1000 free API requests per day.

It is unfortunate that such a workaround is necessary, but the OOBE flow as used by Windows 11 and Windows Autopilot currently lacks the feature to prompt users for their time zone selection. Windows attempts to handle time zone detection autonomously, necessitating the activation of its location services. To enable location services, one must modify the Windows Autopilot deployment profile to make the _Privacy settings_ page visible. However, this modification prompts users with additional, potentially unnecessary questions, such as those related to handwriting customization or advertising IDs, which is suboptimal.

Consider the simplicity of this process for end users back in 1995:

![Windows 95 Setup](https://github.com/shuuryou/intunetoys/assets/36278767/f74a0cd6-7699-4595-856d-0abe95a3bfd3)


_Sigh_ :disappointed:

### Overview

- **Script Name**: SetOSTimeZone.ps1
- **Purpose**: Set the computer's time zone based on its external IP address.
- **Log Output**: `%WINDIR%\Temp\Onboarding-SetOSTimeZone.log`

### Usage

1. Open the [Intune Admin Center](https://endpoint.microsoft.com)
1. Go to **Devices** > **Scripts**
1. Click **Add** > **Windows 10 and later**
1. Enter something into the **Name** text box (e.g. _Set Time Zone via Geo IP Lookup_) and click **Next**
1. Upload the script using the **Script location** field
1. Set **Run this script using the logged on credentials** to **No**
1. Set **Enforce script signature check** to **No**
1. Set **Run script in 64 bit PowerShell Host** to **Yes**
1. Click **Next**
1. Assign the script to your computers, e.g. by clicking **Add all devices** or similar, then click **Next**
1. Click **Add**
   
### Customizing the Script

It is possible to specify an API key if you need more API requests in your environment. To do so, purchase an API key and modify the `$API_KEY` variable in the script.

### Benefits

- Eliminates the need to use registry hacks to enable location services during a fully automated Windows Autopilot deployment scenario.
- Prevents the system from defaulting to Windows 11's default time zone (Redmond, Washington).

