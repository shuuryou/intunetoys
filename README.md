# Intune Toys

Managing a corporate desktop environment entails more than just setting up systems; it also involves ensuring a distraction-free workspace and automating essential configurations.

While Microsoft Intune and Windows Autopilot go a long way in making this task easier, they have their limitations. This repository contains things that I needed but couldn't find (or wasn't satisfied with) while setting up Intune and Windows Autopilot in Microsoft 365. They're designed to address common challenges faced by administrators.

## Disclaimer

Always test in a controlled environment before deploying in a production scenario. Everything here is provided as-is with no warranties.

## RemoveModernApps PowerShell Script

Its purpose is to automatically uninstall and deprovision bundled shovelware apps (Cortana, Weather, Xbox, etc.) in Windows 11 Enterprise. These apps might be considered unsuitable distractions for users of managed corporate desktop environments.

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

Its purpose is to set the time zone of a computer based on its external IP address. This is especially useful for fully automated Windows Autopilot deployment scenarios. To accomplish its task, it uses the [ipapi.co](https://ipapi.co/) service, which allows for up to 1000 free API requests per day.

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

## DriverInstaller PowerShell Script

It facilitates the automated installation of custom drivers during the Windows Autopilot's Out-Of-Box Experience (OOBE). Moreover, the script also serves as a utility to generate the required machine ID when executed with the `-idonly` argument.

The script establishes a connection to a web server specified in the `$DRIVERSTORE` variable at the script's beginning. For authentication purposes, you can provide credentials using the `$DRIVERSTORE_USER` and `$DRIVERSTORE_PASS` variables. If authentication isn't required, these variables should be empty.

Upon execution, the script fetches a list of available drivers from `$DRIVERSTORE/drivers.csv`. For instance, if `$DRIVERSTORE` is set to `https://www.example.com/test/`, the script will attempt to access `https://www.example.com/test/drivers.csv`. The CSV data is then parsed, and relevant drivers, which match the machine ID of the executing computer, are identified. Further details on the CSV file format are discussed in the subsequent section.

Each driver is encapsulated within a ZIP file along with an `install.cmd` script, sourced from the same location as `drivers.csv` (e.g., `https://www.example.com/test/mydriver.zip`). After downloading, the ZIP file is extracted to a temporary directory and `install.cmd` is invoked. This script directs the installation process and can be customized to meet specific requirements. Once the driver installation concludes, the temporary directory is purged.

The script attempts to prevent the reinstallation of previously installed drivers by maintaining a registry-based state list at `HKLM\Software\Onboarding-DriverInstaller`. However, updating drivers is possible by incrementing their version number in the CSV file.

The entire driver installation process is logged. The log file is stored at `%WINDIR%\Temp\Onboarding-DriverInstaller.log`.

### Benefits

* Streamlines the installation of drivers not covered by Windows Update during Windows Autopilot's OOBE.
* Grants total control over the driver installation process via scripting.
* Detailed logging to help troubleshoot issues.
* No duplicate driver installs even if the script is run multiple times by Microsoft Intune. 
* Easily push driver updates by incrementing the driver version number.

### Creating Custom Driver Packages

Constructing a driver package is straightforward. The exact procedure depends on the driver's packaging. The script triggers the `install.cmd` batch file, which is where you should embed your driver installation logic.

For instance, an EXE-based driver might be installed like this:

```batch
REM Intel 620 graphics driver installation in silent mode
gfx_win_101.2115.exe -o -s
```

For INF-based drivers, you might employ:

```batch
REM Install driver for the Contoso Deluxe Webcam
pnputil /add-driver *.inf /install /subdirs

REM Eradicate the intrusive Contoso telemetry agent
sc delete contosotelemetry
```

The `install.cmd` batch file can be tailored to your needs, ensuring maximum flexibility.

### CSV File Format

A correctly formatted CSV file is important for the correct operation of the script. The `drivers.csv` file acts as the central directory for available drivers. It contains entries that associate specific machine IDs with their corresponding driver packages.

#### Example

```csv
MachineID,Version,Description,File
017f9d2cee61e6e7f51936571c7b94780dab5e33,LegacyIntelGraphics,1,intelgraphics_v1.zip
403926033d001b5279df37cbbe5287b7c7c267fa,SpecificNvidiaGraphics,2,nvidia_v2.zip
```

#### Format

* `MachineID`: This is used to match the executing computer's machine ID, ensuring the correct drivers are chosen.
* `Version`: The version number of the driver. Increment this for driver updates. Must be a positive integer, e.g. `1`.
* `Description`: The name of the driver, primarily for reference purposes.
* `File`: File name (not URL) of the ZIP file that contains the driver package and its installation script.

The first line in the CSV file must strictly follow the format: `MachineID,Version,Description,File`. PowerShell parses the first line and uses it to set object property names used throughout the script. Ensure there's no whitespace or deviations, or the script will malfunction.

The machine ID is not the same as Windows Autopilot's hardware hash, because the hardware hash changes every time it is generated.  Moreover, extracting information from it is not straightforward.

To retrieve the machine ID for a specific system, run `DriverInstaller.ps1` with the `-idonly` argument. The machine ID generated is a hash derived from all MAC addresses of the physical network adapters present in the system, coupled with data from the `Win32_Baseboard` WMI class.

## Integration with Microsoft Intune

1. Design your `drivers.csv` file and driver packages as described above.
1. Set up a web server, accessible to your target devices, and position the `drivers.csv` and driver packages in an appropriate directory for server access.
1. Modify the PowerShell script to update `$DRIVERSTORE`, `$DRIVERSTORE_USER`, and `$DRIVERSTORE_PASS` according to your environment.
1. Open the [Intune Admin Center](https://endpoint.microsoft.com)
1. Go to **Devices** > **Scripts**
1. Click **Add** > **Windows 10 and later**
1. Enter something into the **Name** text box (e.g. _Driver Installer_) and click **Next**
1. Upload the script using the **Script location** field
1. Set **Run this script using the logged on credentials** to **No**
1. Set **Enforce script signature check** to **No**
1. Set **Run script in 64 bit PowerShell Host** to **Yes**
1. Click **Next**
1. Assign the script to your computers, e.g. by clicking **Add all devices** or similar, then click **Next**
1. Click **Add**

To re-run the script, simply edit and save the script entry within Intune without actually changing anything.
