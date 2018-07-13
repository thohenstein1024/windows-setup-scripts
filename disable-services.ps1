<##
 # disable-services.ps1
 # This script disables unwanted services in Windows 8.1. Add services you want
 # to disable to the list below; remove or comment out services you don't want
 # to disable. When the script is run, the current status of the services will
 # be displayed and the user will be prompted to continue.
 # Author: Taylor Hohenstein <thohenstein1024@gmail.com>
 # Source: https://github.com/thohenstein1024/windows-setup-scripts
 # Created: 1/4/2018
 # Modified: 7/13/2018
 #>

$services = @(
	'wscsvc'                    # Security Center (used by Action Center)
	'HomeGroupListener'         # HomeGroup Listener
    'HomeGroupProvider'         # HomeGroup Provider
)


Import-Module (Join-Path $PSScriptRoot .\useful-functions\useful-functions.psm1)


# Restart PowerShell as admin and rerun the script, but only if we aren't already admin
# (disabling services with PowerShell requires elevated privileges)
$scriptPath = $PSCommandPath
if (!(Test-Admin)) {
    Write-Host "This script requires elevated privileges to run."
    Restart-Elevated -ScriptPath $scriptPath
} else {
    # Change the appearance of the window a bit
    # TODO: note about nice appearance on 8.1 because of color bug
    $Host.UI.RawUI.ForegroundColor = 'DarkMagenta'
    $Host.UI.RawUI.BackgroundColor = 'DarkYellow'
    Clear-Host  # clear the window so the new background color
    # applies to the entire window background and not just the text
    $Host.PrivateData.ErrorForegroundColor = 'White'
    $Host.PrivateData.ErrorBackgroundColor = 'DarkRed'
    $Host.PrivateData.WarningForegroundColor = 'Yellow'
    $Host.PrivateData.WarningBackgroundColor = 'DarkCyan'
    $scriptName = Split-Path $scriptPath -Leaf
    $Host.UI.RawUI.WindowTitle = $Host.UI.RawUI.WindowTitle + " - " + $scriptName
}

# Display the current status of the services
$numServices = $services.Count
Write-Host "`nTHE FOLLOWING $numServices SERVICES WILL BE DISABLED:`n" -ForegroundColor DarkCyan
$serviceProperties = @('Name', 'State', 'StartMode', 'DisplayName')
$maxServiceNameLength = ($services | Measure-Object Length -Maximum).Maximum
$formattedServiceProperties = @(
    @{
        Expression = {$_.($serviceProperties[0])};
        Label      = "Service Name";
        Width      = [int]$maxServiceNameLength + 2;
        Alignment  = 'Left'
    },
    @{
        Expression = {$_.($serviceProperties[1])};
        Label      = "Status";
        Width      = 9;
        Alignment  = 'Left'
    },
    @{
        Expression = {$_.($serviceProperties[2])};
        Label      = "Startup Type";
        Width      = 14;
        Alignment  = 'Left'
    },
    @{
        Expression = {$_.($serviceProperties[3])};
        Label      = "Display Name";
        Alignment  = 'Left'
    }
)
$formattedServicesTable = (
    # note: The Get-Service cmdlet performs better than Get-CimInstance (and is easier to use because it accepts an
    # array of services), but it can't quite do everything we need. The StartType property wasn't exposed to Get-Service
    # until PowerShell 5.0, and Windows 8.1 ships with PowerShell 4.0. Since the script needs to work on a clean install
    # of Windows 8.1, we'll need to use Get-CimInstance instead of Get-Service. Get-WmiObject would also work.
    Get-CimInstance -ClassName Win32_Service -Property $serviceProperties |
        Where-Object {$_.Name -in $services} | Sort-Object DisplayName |
        Format-Table -Property $formattedServiceProperties | Out-String
).Trim()  # get rid of the line breaks that Format-Table adds at
# the top and bottom of the table so we have more formatting control
Write-Host $formattedServicesTable

# Prompt before continuing so the user has a chance to back out
if (!(Confirm-Continue -TextColor DarkRed)) {
    exit
}

# Disable each service while giving feedback
Write-Host "`n`nDISABLING $numServices SERVICES...`n" -ForegroundColor DarkCyan
$checkMark = [char]8730
foreach ($service in $services) {
    Set-Service $service -StartupType Disabled -ErrorVariable disableServiceError
    if (!$disableServiceError) {
        Write-Host " $checkMark $service" -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 1  # make the output appear line by line instead of appearing all at once
    } else {
        Write-Host " X $service couldn't be disabled" -ForegroundColor Red
        Start-Sleep -Milliseconds 250  # pause for a bit so the error doesn't instantly scroll off-screen
    }
}
Write-Host "`nDONE." -ForegroundColor DarkCyan

# Prompt before displaying the status of the services so the feedback above doesn't get pushed off-screen
if (!(Confirm-Continue -Prompt "`nPress <Enter> to see the current status of the services: " -TextColor DarkRed)) {
    exit
}

# Display the current status of the services
Write-Host "`n`nCURRENT STATUS OF $numServices SERVICES:`n" -ForegroundColor DarkCyan
$formattedServicesTable = (
    Get-CimInstance -ClassName Win32_Service -Property $serviceProperties |
        Where-Object {$_.Name -in $services} | Sort-Object DisplayName |
        Format-Table -Property $formattedServiceProperties | Out-String
).Trim()
Write-Host $formattedServicesTable

# Keep the window open until the user presses a key
Confirm-Exit -TextColor DarkRed