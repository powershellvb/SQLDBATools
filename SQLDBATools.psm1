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

if($verbose) {
    Write-Host "====================================================";
    Write-Host "'Get-SqlServerProductKeys.psm1' Module is being loaded.." -ForegroundColor Yellow;
}
Import-Module -Name $(Join-Path $cmdletPath Get-SqlServerProductKeys.psm1)
if($verbose) {
    Write-Host "====================================================";
    Write-Host "Loading other Functions.." -ForegroundColor Yellow;
}

. $(Join-Path $cmdletPath 'Add-ApplicationInfo.ps1')
. $(Join-Path $cmdletPath 'Add-CollectionError.ps1')
. $(Join-Path $cmdletPath 'Add-HostsEntry.ps1')
. $(Join-Path $cmdletPath 'Add-ServerInfo.ps1')
. $(Join-Path $cmdletPath 'Add-SqlAgentOperator.ps1')
. $(Join-Path $cmdletPath 'Add-SqlInstanceInfo.ps1')
. $(Join-Path $cmdletPath 'Add-DatabaseBackupInfo.ps1')
. $(Join-Path $cmdletPath 'Add-SecurityCheckInfo.ps1')
. $(Join-Path $cmdletPath 'Add-VolumeInfo.ps1')
. $(Join-Path $cmdletPath 'Export-Password.ps1')
. $(Join-Path $cmdletPath 'Find-KeywordInSQLDBATools.ps1')
. $(Join-Path $cmdletPath 'Find-SQLInstances.ps1')
. $(Join-Path $cmdletPath 'Functions_ADOQuery.ps1')
. $(Join-Path $cmdletPath 'Get-AdministrativeEvents.ps1')
. $(Join-Path $cmdletPath 'Get-AdUserInfo.ps1')
. $(Join-Path $cmdletPath 'Get-BackupHistory.ps1')
. $(Join-Path $cmdletPath 'Get-ClusterInfo.ps1')
. $(Join-Path $cmdletPath 'Get-DatabaseBackupInfo.ps1')
. $(Join-Path $cmdletPath 'Get-DatabaseBackupInfo_SMO.ps1')
. $(Join-Path $cmdletPath 'Get-DbaRestoreScript.ps1')
. $(Join-Path $cmdletPath 'Get-FullQualifiedDomainName.ps1')
. $(Join-Path $cmdletPath 'Get-HBAWin.ps1')
. $(Join-Path $cmdletPath 'Get-LinkedServer.ps1')
. $(Join-Path $cmdletPath 'Get-MacAddress.ps1')
. $(Join-Path $cmdletPath 'Get-MachineType.ps1')
. $(Join-Path $cmdletPath 'Get-MSSQLLinkPasswords.ps1')
. $(Join-Path $cmdletPath 'Get-OrphanDatabaseFiles.ps1')
. $(Join-Path $cmdletPath 'Get-Password4Account.ps1')
. $(Join-Path $cmdletPath 'Get-PerfMonCounters.ps1')
. $(Join-Path $cmdletPath 'Get-PowerPlanInfo.ps1')
. $(Join-Path $cmdletPath 'Get-ProcessForDBA.ps1')
. $(Join-Path $cmdletPath 'Get-RebootHistory.ps1')
. $(Join-Path $cmdletPath 'Get-RunningQueries.ps1')
. $(Join-Path $cmdletPath 'Get-SecurityCheckInfo.ps1')
. $(Join-Path $cmdletPath 'Get-ServerInfo.ps1')
. $(Join-Path $cmdletPath 'Get-DatabaseRestoreScript.ps1')
. $(Join-Path $cmdletPath 'Get-SQLInstance.ps1')
. $(Join-Path $cmdletPath 'Get-SQLInstanceInfo.ps1')
. $(Join-Path $cmdletPath 'Get-VolumeInfo.ps1')
. $(Join-Path $cmdletPath 'Get-VolumeSpaceConsumers.ps1')
. $(Join-Path $cmdletPath 'Get-WhoIsActive.ps1')
. $(Join-Path $cmdletPath 'Grant-SqlAccountRequiredPrivileges.ps1')
. $(Join-Path $cmdletPath 'Install-OlaHallengrenMaintenanceScripts.ps1')
. $(Join-Path $cmdletPath 'Install-SqlInstance.ps1')
. $(Join-Path $cmdletPath 'Invoke-CommandMultiThreaded.ps1')
. $(Join-Path $cmdletPath 'Invoke-sp_WhoIsActive.ps1')
. $(Join-Path $cmdletPath 'Invoke-TsqlScript.ps1')
. $(Join-Path $cmdletPath 'Invoke-SqlQuery.ps1')
. $(Join-Path $cmdletPath 'Join-Object.ps1')
. $(Join-Path $cmdletPath 'Optimize-ModelDatabase.ps1')
. $(Join-Path $cmdletPath 'Out-DataTable.ps1')
. $(Join-Path $cmdletPath 'Reset-OwnerShipToSystemAdministrators.ps1')
. $(Join-Path $cmdletPath 'Select-ServerInfo.ps1')
. $(Join-Path $cmdletPath 'Send-SQLMail.ps1')
. $(Join-Path $cmdletPath 'Set-BaselineWithWhoIsActive.ps1')
. $(Join-Path $cmdletPath 'Set-BlockingAlert.ps1')
. $(Join-Path $cmdletPath 'Set-DatabaseBackupJobs.ps1')
. $(Join-Path $cmdletPath 'Set-DbaConfigurations.ps1')
. $(Join-Path $cmdletPath 'Set-DbaLogWalk.ps1')
. $(Join-Path $cmdletPath 'Set-DbaMailProfile.ps1')
. $(Join-Path $cmdletPath 'Set-IndexOptimizeJobs.ps1')
. $(Join-Path $cmdletPath 'Set-Owner.ps1')
. $(Join-Path $cmdletPath 'Set-ServiceBroker_4_LogWalkAlert.ps1')
. $(Join-Path $cmdletPath 'Set-SelfServiceModules.ps1')
. $(Join-Path $cmdletPath 'Set-ServerState.ps1')
. $(Join-Path $cmdletPath 'Set-SQLServiceState.ps1')
. $(Join-Path $cmdletPath 'Show-Password.ps1')
. $(Join-Path $cmdletPath 'Uninstall-SqlInstance.ps1')

Push-Location;

<#
Remove-Module SQLDBATools,dbatools,SqlServer -ErrorAction SilentlyContinue;
Import-Module SQLDBATools,dbatools
#>
