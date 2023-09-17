###############################################################################
# RemoveModernApps.ps1                                                        #
# PowerShell script for Microsoft Intune to automatically uninstall and       #
# deprovision Microsoft's shovelware apps in Win 11 Enterprise that are       #
# unsuitable for managed corporate desktop environments.                      #
#                                                                             #
# Log output at %WINDIR%\Temp\Onboarding-RemoveModernApps.log                 #
#                                                                             #
# https://github.com/shuuryou/intunetoys                                      #
# https://github.com/shuuryou/intunetoys/blob/main/LICENSE                    #
###############################################################################

# You may wish to remove apps from this list if you require them in your
# organization. Once they're gone, they're gone (unless you like messing
# with the finer details of modern app packaging in Windows).
# 549981c3f5f10 is Cortana
$Crap = "*3dbuilder*", "*sway*", "*communicationsapps*", "*officehub*", `
		"*bing*", "*zune*", "*gethelp*", "*photos*", "*skype*", "*maps*", `
		"*solitaire*", "*getstarted*", "*onenote*", "*people*", `
		"*yourphone*", "*teams*", "*todos*", "*windowsfeedbackhub*", `
		"*xbox*", "*mixedreality*", "*clipchamp*", "*gamingapp*", `
		"*549981c3f5f10*"

###############################################################################

Start-Transcript -Path $env:windir\Temp\Onboarding-RemoveModernApps.log

foreach ($Pattern in $Crap)
{
	Write-Output("Processing removal pattern ""{0}...""" -f $Pattern)
	$Packages = Get-AppxPackage -AllUsers $Pattern
	foreach ($Package in $Packages)
	{
		Write-Output("BEGIN REMOVAL: ""{0}"":" -f $Package.Name)

		try
		{
			Remove-AppxPackage -AllUsers $Package 2>&1 | Out-Null # Intune gets angry if there's error output
		}
		catch
		{
			Write-Output("Failed. Ignoring error. Error was: {0}" -f $_)
		}

		Write-Output("END REMOVAL: ""{0}"":" -f $Package.Name)
	}
}

foreach ($Pattern in $Crap)
{
	Write-Output("Processing deprovisioning pattern ""{0}...""" -f $Pattern)
	$Package = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like $Pattern } 
	
	if ($Package -eq $Null)
	{
		Write-Output("No matching package(s) found to to deprovision.")
		continue
	}
	
	Write-Output("BEGIN DEPROVISION: ""{0}"":" -f $Package.PackageName)

	try
	{
		Remove-AppxProvisionedPackage -Online $Package 2>&1 | Out-Null # Intune gets angry if there's error output
	}
	catch
	{
		Write-Output("Failed. Ignoring error. Error was: {0}" -f $_)
	}

	Write-Output("END DEPROVISION: ""{0}"":" -f $Package.Name)
}


Write-Output "Finished."

Exit 0