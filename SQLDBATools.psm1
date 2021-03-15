<#
    Module Name:-   SQLDBATools
    Created By:-    Ajay Kumar Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 20-June-2020
    Version:-       0.0.1
#>

Push-Location;

# Establish and enforce coding rules in expressions, scripts, and script blocks.
Set-StrictMode -Version Latest

# Check for OS version
[bool]$isWin = $PSVersionTable.Platform -match '^($|(Microsoft )?Win)'
$modulePath = Split-Path $MyInvocation.MyCommand.Path -Parent;
#Write-Host "$PSScriptRoot"
$cmdletPath = Join-Path $modulePath 'Cmdlets'
$pathSeparator = if($isWin) {'\'} else {'/'}
$verbose = $false;
if ($PSBoundParameters.ContainsKey('Verbose')) { # Command line specifies -Verbose[:$false]
    $verbose = $PSBoundParameters.Get_Item('Verbose')
}
<#
if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent -or [String]::IsNullOrEmpty($MyInvocation.PSScriptRoot)) {
    $verbose = $true;
}
#>

# Set basic environment variables
[string]$envFileBase = $null
[string]$envFile = $null
if($isWin) {
    $envFileBase = Join-Path $modulePath "Cmdlets\Set-EnvironmentVariables.ps1"
} else {
    $envFileBase = Join-Path $modulePath "Cmdlets/Set-EnvironmentVariables.ps1"
}
$envFile = Join-Path $modulePath "Set-EnvironmentVariables.ps1"

# First Load Environment Variables
# File :Set-EnvironmentVariables.ps1" is also present inside Cmdlets subdirectory with dummy values.
if($verbose) {
    Write-Host "====================================================";
    Write-Host "'Environment Variables are being loaded from '$envFile'.." -ForegroundColor Yellow;
}
# If environment variable file present
if(Test-Path $envFile) {
    Invoke-Expression -Command $envFile;
}
else {
    Copy-Item $envFileBase -Destination $modulePath | Out-Null;
    Write-Output "Environment file 'Set-EnvironmentVariables.ps1' has been copied on '$envFileBase'.`nKindly modify the variable values according to your environment";
}

$M_dbatools = Get-Module -Name dbatools -ListAvailable -Verbose:$false;
if([String]::IsNullOrEmpty($M_dbatools)) {
    Write-Output 'dbatools powershell module needs to be installed. Kindly execute below command in Elevated shell:-'
    Write-Output "`tInstall-Module -Name dbatools -Scope AllUsers -Force -Confirm:`$false -Verbose:`$false'"
} else {
    Import-Module dbatools -Global -Verbose:$false | Out-Null;
}


# Check for ActiveDirectory module
if ( (Get-Module -ListAvailable | Where-Object { $_.Name -eq 'ActiveDirectory' }) -eq $null )
{
    if($verbose)
    {
        Write-Host "====================================================";
        Write-Host "'ActiveDirectory' module is not installed." -ForegroundColor DarkRed;
        @"
    ** So, few functions like 'Add-ApplicationInfo' might not work with this module. Kindly execute below Cmdlets to import ActiveDirectory.

        Install-Module ServerManager -Force;
        Add-WindowsFeature RSAT-AD-PowerShell;
        Install-Module ActiveDirectory -Force;

"@ | Write-Host -ForegroundColor Yellow;
    }
}

<#
if($verbose) {
    Write-Host "====================================================";
    Write-Host "'Get-SqlServerProductKeys.psm1' Module is being loaded.." -ForegroundColor Yellow;
}
Import-Module -Name $(Join-Path $cmdletPath Get-SqlServerProductKeys.psm1)
#>

if($verbose) {
    Write-Host "====================================================";
    Write-Host "Loading other Functions.." -ForegroundColor Yellow;
}
foreach($file in Get-ChildItem -Path $(Join-Path $PSScriptRoot Cmdlets)) {
    . $file.FullName
    #$file.FullName | Write-Host
    #$ExecutionContext.SessionState.InvokeCommand.GetCommand($($file.FullName), 'ExternalScript')
}

#Export-ModuleMember -Alias * -Function * -Cmdlet *

Push-Location;

<#
Remove-Module SQLDBATools,dbatools,SqlServer -ErrorAction SilentlyContinue;
Import-Module SQLDBATools,dbatools
#>
