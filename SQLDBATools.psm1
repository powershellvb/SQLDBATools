<# 
    Module Name:-   SQLDBATools
    Created By:-    Ajay Kumar Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 30-Oct-2019
    Version:-       0.0
#>

Push-Location;

# First Load Environment Variables
# File :Set-EnvironmentVariables.ps1" is present @ C:\Users\adwivedi\OneDrive - TiVo Inc\Tivo-Assignments\Set-EnvironmentVariables.ps1
# File :Set-EnvironmentVariables.ps1" is also present inside Cmdlets subdirectory with dummy values.
if($verbose)
{
    Write-Host "====================================================";
    Write-Host "'Environment Variables are being loaded.." -ForegroundColor Yellow;
}
if(Test-Path "C:\Set-EnvironmentVariables.ps1") {
    Invoke-Expression -Command "C:\Set-EnvironmentVariables.ps1";
} else {
    $envFile = "$PSScriptRoot\Cmdlets\Set-EnvironmentVariables.ps1"
    Copy-Item $envFile -Destination C:\ | Out-Null;
    Write-Output "Environment file 'Set-EnvironmentVariables.ps1' has been copied on C:\ drive.`nKindly modify the variable values according to your environment";
}
<#
$M_SqlServer = Get-Module -Name SqlServer -ListAvailable -Verbose:$false;
if([String]::IsNullOrEmpty($M_SqlServer)) {
    Write-Output 'SqlServer powershell module needs to be installed. Kindly execute below command in Elevated shell:-'
    Write-Output "`tInstall-Module -Name SqlServer -Scope AllUsers -Force -Confirm:`$false -Verbose:`$false'"
} else {
    Import-Module SqlServer -Global -Verbose:$false | Out-Null;
}
#>
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

if($verbose)
{
    Write-Host "====================================================";
    Write-Host "'Get-SqlServerProductKeys.psm1' Module is being loaded.." -ForegroundColor Yellow;
}
Import-Module -Name $PSScriptRoot\Cmdlets\Get-SqlServerProductKeys.psm1
if($verbose)
{
    Write-Host "====================================================";
    Write-Host "Loading other Functions.." -ForegroundColor Yellow;
}
. $PSScriptRoot\Cmdlets\Add-ApplicationInfo.ps1
. $PSScriptRoot\Cmdlets\Add-CollectionError.ps1
. $PSScriptRoot\Cmdlets\Add-HostsEntry.ps1
. $PSScriptRoot\Cmdlets\Add-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Add-SqlAgentOperator.ps1
. $PSScriptRoot\Cmdlets\Add-SqlInstanceInfo.ps1
. $PSScriptRoot\Cmdlets\Add-DatabaseBackupInfo.ps1
. $PSScriptRoot\Cmdlets\Add-SecurityCheckInfo.ps1
. $PSScriptRoot\Cmdlets\Add-VolumeInfo.ps1
. $PSScriptRoot\Cmdlets\Export-Password.ps1
. $PSScriptRoot\Cmdlets\Find-KeywordInSQLDBATools.ps1
. $PSScriptRoot\Cmdlets\Find-SQLInstances.ps1
. $PSScriptRoot\Cmdlets\Functions_ADOQuery.ps1
#. $PSScriptRoot\Get-DBFiles.ps1
. $PSScriptRoot\Cmdlets\Get-AdministrativeEvents.ps1
. $PSScriptRoot\Cmdlets\Get-AdUserInfo.ps1
. $PSScriptRoot\Cmdlets\Get-BackupHistory.ps1
. $PSScriptRoot\Cmdlets\Get-ClusterInfo.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseBackupInfo.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseBackupInfo_SMO.ps1
. $PSScriptRoot\Cmdlets\Get-DbaRestoreScript.ps1
. $PSScriptRoot\Cmdlets\Get-FullQualifiedDomainName.ps1
. $PSScriptRoot\Cmdlets\Get-HBAWin.ps1
. $PSScriptRoot\Cmdlets\Get-LinkedServer.ps1
. $PSScriptRoot\Cmdlets\Get-MachineType.ps1
. $PSScriptRoot\Cmdlets\Get-MSSQLLinkPasswords.ps1
. $PSScriptRoot\Cmdlets\Get-OrphanDatabaseFiles.ps1
#. $PSScriptRoot\Cmdlets\Get-OutlookInBox.ps1
. $PSScriptRoot\Cmdlets\Get-Password4Account.ps1
. $PSScriptRoot\Cmdlets\Get-PerfMonCounters.ps1
. $PSScriptRoot\Cmdlets\Get-PowerPlanInfo.ps1
. $PSScriptRoot\Cmdlets\Get-ProcessForDBA.ps1
. $PSScriptRoot\Cmdlets\Get-RebootHistory.ps1
. $PSScriptRoot\Cmdlets\Get-RunningQueries.ps1
. $PSScriptRoot\Cmdlets\Get-SecurityCheckInfo.ps1
. $PSScriptRoot\Cmdlets\Get-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseRestoreScript.ps1
. $PSScriptRoot\Cmdlets\Get-SQLInstance.ps1
. $PSScriptRoot\Cmdlets\Get-SQLInstanceInfo.ps1
. $PSScriptRoot\Cmdlets\Get-VolumeInfo.ps1
#. $PSScriptRoot\Get-SQLInstance.ps1
. $PSScriptRoot\Cmdlets\Get-VolumeSpaceConsumers.ps1
. $PSScriptRoot\Cmdlets\Get-WhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Grant-SqlAccountRequiredPrivileges.ps1
. $PSScriptRoot\Cmdlets\Install-OlaHallengrenMaintenanceScripts.ps1
. $PSScriptRoot\Cmdlets\Install-SqlInstance.ps1
. $PSScriptRoot\Cmdlets\Invoke-CommandMultiThreaded.ps1
. $PSScriptRoot\Cmdlets\Invoke-sp_WhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Invoke-TsqlScript.ps1
. $PSScriptRoot\Cmdlets\Invoke-SqlQuery.ps1
. $PSScriptRoot\Cmdlets\Join-Object.ps1
. $PSScriptRoot\Cmdlets\Optimize-ModelDatabase.ps1
. $PSScriptRoot\Cmdlets\Out-DataTable.ps1
. $PSScriptRoot\Cmdlets\Reset-OwnerShipToSystemAdministrators.ps1
#. $PSScriptRoot\Cmdlets\Restart-WindowsFirewall.ps1
#. $PSScriptRoot\Cmdlets\Restart-WinRM.ps1
. $PSScriptRoot\Cmdlets\Select-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Send-SQLMail.ps1
. $PSScriptRoot\Cmdlets\Set-BaselineWithWhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Set-BlockingAlert.ps1
. $PSScriptRoot\Cmdlets\Set-DatabaseBackupJobs.ps1
. $PSScriptRoot\Cmdlets\Set-DbaConfigurations.ps1
. $PSScriptRoot\Cmdlets\Set-DbaLogWalk.ps1
. $PSScriptRoot\Cmdlets\Set-DbaMailProfile.ps1
. $PSScriptRoot\Cmdlets\Set-IndexOptimizeJobs.ps1
. $PSScriptRoot\Cmdlets\Set-Owner.ps1
. $PSScriptRoot\Cmdlets\Set-ServiceBroker_4_LogWalkAlert.ps1
. $PSScriptRoot\Cmdlets\Set-SelfServiceModules.ps1
. $PSScriptRoot\Cmdlets\Set-ServerState.ps1
. $PSScriptRoot\Cmdlets\Set-SQLServiceState.ps1
#. $PSScriptRoot\Cmdlets\Set-WinRMFirewallRule.ps1
#. $PSScriptRoot\Cmdlets\Set-WinRMListener.ps1
#. $PSScriptRoot\Cmdlets\Set-WinRMStartup.ps1
. $PSScriptRoot\Cmdlets\Show-Password.ps1
. $PSScriptRoot\Cmdlets\UnInstall-SqlInstance.ps1


Push-Location;

<#
Remove-Module SQLDBATools,dbatools,SqlServer -ErrorAction SilentlyContinue;
Import-Module SQLDBATools,dbatools
#>
