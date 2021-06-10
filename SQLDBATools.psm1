﻿<#
    Module Name:-   SQLDBATools
    Created By:-    Ajay Kumar Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 10-June-2021
    Version:-       0.0.2
#>

Push-Location;

# Establish and enforce coding rules in expressions, scripts, and script blocks.
Set-StrictMode -Version Latest

# Check for OS version
if([bool]($PSVersionTable.PSobject.Properties.name -match "Platform")) {
    [bool]$isWin = $PSVersionTable.Platform -match '^($|(Microsoft )?Win)'
}
else {
    [bool]$isWin = $true
}
$modulePath = Split-Path $MyInvocation.MyCommand.Path -Parent;
$functionsPath = Join-Path $modulePath 'Functions'
$pathSeparator = if($isWin) {'\'} else {'/'}
$verbose = $false;
if ($PSBoundParameters.ContainsKey('Verbose')) { # Command line specifies -Verbose[:$false]
    $verbose = $PSBoundParameters.Get_Item('Verbose')
}

# Set basic environment variables
[string]$envFileBase = $null
[string]$envFile = $null
if($isWin) {
    $envFileBase = Join-Path $modulePath "Functions\Set-EnvironmentVariables.ps1"
} else {
    $envFileBase = Join-Path $modulePath "Functions/Set-EnvironmentVariables.ps1"
}
$envFile = Join-Path $modulePath "Set-EnvironmentVariables.ps1"

# First Load Environment Variables
# File :Set-EnvironmentVariables.ps1" is also present inside Functions subdirectory with dummy values.
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
} 
<#
else {
    Import-Module dbatools -Global -Verbose:$false | Out-Null;
}
#>

# Check for ActiveDirectory module
if ( (Get-Module -ListAvailable | Where-Object { $_.Name -eq 'ActiveDirectory' }) -eq $null )
{
    if($verbose)
    {
        Write-Host "====================================================";
        Write-Host "'ActiveDirectory' module is not installed." -ForegroundColor DarkRed;
        @"
    ** So, few functions like 'Add-ApplicationInfo' might not work with this module. Kindly execute below Functions to import ActiveDirectory.

        Install-Module ServerManager -Force;
        Add-WindowsFeature RSAT-AD-PowerShell;
        Install-Module ActiveDirectory -Force;

"@ | Write-Host -ForegroundColor Yellow;
    }
}


if($verbose) {
    Write-Host "====================================================";
    Write-Host "'Get-SqlServerProductKeys.psm1' Module is being loaded.." -ForegroundColor Yellow;
}
Import-Module -Name $(Join-Path $modulePath "ChildModules$($pathSeparator)Get-SqlServerProductKeys.psm1")


if($verbose) {
    Write-Host "====================================================";
    Write-Host "Loading other Functions.." -ForegroundColor Yellow;
}
#foreach($file in Get-ChildItem -Path $(Join-Path $PSScriptRoot Functions)) {
foreach($file in Get-ChildItem -Path $functionsPath) {
    . ($file.FullName)
}
#Export-ModuleMember -Alias * -Function * -Cmdlet *

Push-Location;

<#
Remove-Module SQLDBATools,dbatools,SqlServer -ErrorAction SilentlyContinue;
Import-Module SQLDBATools
#>
