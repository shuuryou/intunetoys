###############################################################################
# DriverInstaller.ps1                                                         #
# PowerShell script for Microsoft Intune to automatically install custom      #
# drivers during Windows Autopilot's OOBE. To generate the required machine   #
# ID, invoke with -idonly argument.                                           #
#                                                                             #
# Log output at %WINDIR%\Temp\Onboarding-DriverInstaller.log                  #
#                                                                             #
# https://github.com/shuuryou/intunetoys                                      #
# https://github.com/shuuryou/intunetoys/blob/main/LICENSE                    #
###############################################################################

$DRIVERSTORE = 'https://example.com/changeme/'
$DRIVERSTORE_USER = 'set or leave blank'
$DRIVERSTORE_PASS = 'set or leave blank'

###############################################################################

function Main
{
	param([switch]$IDOnly = $false)

	try
	{
		$Errors = $False

		if (-not $IDOnly)
		{
			Start-Transcript -Path $env:windir\Temp\Onboarding-DriverInstaller.log
		}

		Write-Output('Attempting to create the machine ID for this PC.')

		try
		{
			$MachineID = ''

			# Collect a bunch of stuff that is hopefully unique enough for each
			# machine and doesn't change when Windows is reinstalled.

			Get-NetAdapter -Physical | ForEach-Object { $MachineID += $_.MacAddress }
			$Baseboard = Get-WmiObject win32_baseboard
			$MachineID += $Baseboard.Manufacturer + $Baseboard.Model + $Baseboard.SerialNumber + $Baseboard.SKU + $Baseboard.Product
			$MachineID = Get-Hash($MachineID)
		}
		catch
		{
			Write-Error('Unable to create the machine ID for this PC. Unable to continue. Error: {0}' -f $_)
			Exit 1
		}

		Write-Output('Machine ID: {0}' -f $MachineID)

		###############################################################################

		if ($IDOnly)
		{
			Write-Output("That's all you wanted. Enjoy.")
			Exit 0
		}

		###############################################################################

		if ($DRIVERSTORE_PASS -ne '' -and $DRIVERSTORE_PASS -ne '')
		{
			$DRIVERSTORE_PASS = ConvertTo-SecureString $DRIVERSTORE_PASS -AsPlainText -Force
			$DRIVERSTORE_CREDENTIALS = New-Object System.Management.Automation.PSCredential($DRIVERSTORE_USER, $DRIVERSTORE_PASS)
		}
		else
		{
			$DRIVERSTORE_CREDENTIALS = $null
		}

		$DriverListURL = "$DRIVERSTORE/drivers.csv"

		Write-Output('Now downloading driver list from "{0}".' -f $DriverListURL)

		try
		{
			$DriverList = Invoke-RestMethod $DriverListURL -Credential $DRIVERSTORE_CREDENTIALS | ConvertFrom-Csv -Delim ','
		}
		catch
		{
			Write-Error('Unable to download or parse the driver list: {0}' -f $_)
			Exit 1
		}

		Write-Output('Successfully downloaded the driver list.')

		###############################################################################

		Write-Output('Now processing drivers for this PC.' )

		$DriverPath = "$env:windir\Temp\driverinstall"

		$DriverList = $DriverList | Where-Object { $_.MachineID -eq $MachineID }

		if (-Not(Test-Path -Path 'HKLM:\Software\Onboarding-DriverInstaller'))
		{
			New-Item -Path 'HKLM:\Software\Onboarding-DriverInstaller' | Out-Null
		}

		if (Test-Path -LiteralPath $DriverPath)
		{
			Write-Output('Cleaning up stale driver installation work directory "{0}".' -f $DriverPath)

			Remove-Item -LiteralPath $DriverPath -Force -Recurse | Out-Null

			Write-Output('Finished cleaning up stale driver installation work directory.')
		}

		foreach ($Driver in $DriverList)
		{
			Write-Output('Considering to process driver "{0}".' -f $Driver.Description)
		
			$Installed = Test-RegistryValue -Path 'HKLM:\Software\Onboarding-DriverInstaller' -Name $Driver.Description -PassThru

			if ($Installed -ne $False)
			{
				Write-Output('This driver is already installed. Local version: {0}, offered version: {1}.' -f $Installed, $Driver.Version)

				if ($Installed -ge $Driver.Version)
				{
					Write-Output('Local driver is the same or newer. Skipping.') 
					continue
				}

				Write-Output('This driver needs to be updated.')
			}
			else
			{
				Write-Output('This driver needs to be installed.')

			}

			Write-Output('STARTING to process driver "{0}".' -f $Driver.Description)

			Write-Output('Creating driver installation work directory.')
		
			New-Item -ItemType Directory -Force -Path $DriverPath | Out-Null

			$DriverURL = "$DRIVERSTORE/$($Driver.File)"
		
			Write-Output('Downloading driver ZIP archive from "{0}".' -f $DriverURL)
		
			try
			{
				Invoke-WebRequest -Uri $DriverURL -Credential $DRIVERSTORE_CREDENTIALS -OutFile $DriverPath\driver.zip | Out-Null
			}
			catch
			{
				Write-Error('Unable to download driver ZIP archive. Skipping. Error: {0}' -f $_)
				$Errors = $True
				continue
			}
		
			Write-Output('Extracting files from driver ZIP archive.')
		
			try
			{
				Expand-Archive -Path $DriverPath\driver.zip -DestinationPath $DriverPath | Out-Null
			}
			catch
			{
				Write-Error('Unable to extract driver ZIP archive. Skipping. Error: {0}' -f $_)
				$Errors = $True
				continue
			}
		
			Write-Output('Running install script from driver ZIP archive.')

			try
			{
				Start-Process -FilePath "$DriverPath\install.cmd" -WorkingDirectory $DriverPath -Wait -NoNewWindow
			}
			catch
			{
				Write-Error('Unable to start installation script. Skipping this driver. Error: {0}' -f $_)
				$Errors = $True
				continue
			}
		
			Write-Output('Marking driver as installed.')
		
			New-ItemProperty -Force -Path 'HKLM:\Software\Onboarding-DriverInstaller' -Name $Driver.Description -Value $Driver.Version -Type 'Dword' | Out-Null
		
			Write-Output('Cleaning up.')
		
			Remove-Item -LiteralPath $DriverPath -Force -Recurse | Out-Null
		
			Write-Output('FINISHED processing driver "{0}".' -f $Driver.Description)
		}

		Write-Output('Finished processing all drivers for this PC.')

		###############################################################################

		if ($Errors)
		{
			Write-Error('Errors were encountered during the driver installation process.')
			Exit 1
		}

		Write-Output('Everything went well.')

		Exit 0
	}
	finally 
	{
		if (-not $IDOnly)
		{
			Stop-Transcript
		}
	}
}

Function Test-RegistryValue
{
	param(
		[Alias('PSPath')]
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[String]$Path
		,
		[Parameter(Position = 1, Mandatory = $true)]
		[String]$Name
		,
		[Switch]$PassThru
	) 

	process
	{
		if (Test-Path $Path)
		{
			$Key = Get-Item -LiteralPath $Path
			$Value = $Key.GetValue($Name, $null)
			if ($null -ne $Value)
			{
				if ($PassThru)
				{
					$Value
				}
				else
				{
					$true
				}
			}
			else
			{
				$false
			}
		}
		else
		{
			$false
		}
	}
}

function Get-Hash
{
	param ([parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]$String)

	# The hash is really, really long. Run it through SHA1 to make it
	# shorter. The hash isn't a secret or anything like that, so this
	# isn't a security issue. SHA1 is fine.
	
	$SHA1 = new-object -TypeName System.Security.Cryptography.SHA1CryptoServiceProvider
	$UTF8 = new-object -TypeName System.Text.ASCIIEncoding
	$Hash = [System.BitConverter]::ToString($SHA1.ComputeHash($UTF8.GetBytes($String))).Replace('-', '').ToLower()
	
	return $Hash
}

Main @args