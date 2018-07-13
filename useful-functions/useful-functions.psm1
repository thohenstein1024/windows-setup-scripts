<##
 # useful-functions.psm1
 # A PowerShell Module containing useful functions. Use Import-Module to make
 # them available to your script or console session. Alternatively, put this
 # file's containing folder into one of PowerShell's default Module directories.
 # This will make the functions available everywhere and the Import-Module
 # cmdlet is no longer needed.
 # Author: Taylor Hohenstein <thohenstein1024@gmail.com>
 # Source: https://github.com/thohenstein1024/windows-setup-scripts
 # Created: 2/6/2018
 # Modified: 7/13/2018
 #>

function Restart-Elevated([string]$ScriptPath, [string]$WorkingDirectory = '.') {
    # note: The -WorkingDirectory parameter is ignored by Start-Process when using '-Verb RunAs', apparently for
    # security reasons. We can get around this by instructing the elevated PowerShell instance we're creating to change
    # directory as soon as it starts. Unfortunately, when $ScriptPath isn't specified, our workaround has the unintended
    # but logical side effect of causing the new PowerShell instance to exit immediately after changing directory
    # (instead of presenting the user with the elevated PowerShell prompt as intended). Luckily, the -NoExit parameter
    # exists, and it restores our intended behavior.
    $commands = "Set-Location $WorkingDirectory;"
    if ($ScriptPath) {
        $commands += " $ScriptPath;"
        $scriptName = Split-Path $ScriptPath -Leaf
        Write-Host "Restarting PowerShell as administrator and attempting to run '$scriptName'..."
        Start-Process powershell.exe -ArgumentList $commands -Verb RunAs
    } else {
        Write-Host "Restarting PowerShell as administrator..."
        Start-Process powershell.exe -ArgumentList ('-NoExit', $commands) -Verb RunAs
    }
    exit
}

function Test-Admin() {
    $windowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = [System.Security.Principal.WindowsPrincipal]($windowsIdentity)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    return $windowsPrincipal.IsInRole($adminRole)
}

function Confirm-Exit([string]$Prompt, [System.ConsoleColor]$TextColor = $Host.UI.RawUI.ForegroundColor) {
    if ($Host.Name -eq 'ConsoleHost') {
        if (!$Prompt) { $Prompt = "`nPress any key to exit... " }
        Write-Host $Prompt -NoNewline -ForegroundColor $TextColor
        $Host.UI.RawUI.FlushInputBuffer()  # ignore any previous input so the window doesn't unexpectedly close if
        # there was a keypress earlier that got buffered (e.g. the user hit a key while an operation was in progress)
        $Host.UI.RawUI.ReadKey('IncludeKeyUp, NoEcho') > $null
    }
}

function Confirm-Continue([string]$Prompt, [System.ConsoleColor]$TextColor = $Host.UI.RawUI.ForegroundColor) {
    if (!$Prompt) { $Prompt = "`nPress <Enter> to continue: " }
    Write-Host $Prompt -NoNewline -ForegroundColor $TextColor
    $userInput = Read-Host
    if ($userInput) {
        return $false
    } else {
        return $true
    }
}