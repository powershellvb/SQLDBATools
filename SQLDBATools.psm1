<# 
    Module Name:-   SQLDBATools
    Created By:-    Ajay Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 30-Dec-2018
    Version:-       0.2
#>

Push-Location;
# First Load Environment Variables
if($verbose)
{
    Write-Host "====================================================";
    Write-Host "'Environment Variables are being loaded.." -ForegroundColor Yellow;
}
Invoke-Expression -Command "C:\Set-EnvironmentVariables.ps1";

Write-Verbose "====================================================";
Write-Verbose "Kindly import 'dbatools' powershell module..";
Write-Verbose "====================================================";

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

# File :Set-EnvironmentVariables.ps1" is present @ C:\Users\adwivedi\OneDrive - TiVo Inc\Tivo-Assignments\Set-EnvironmentVariables.ps1
# File :Set-EnvironmentVariables.ps1" is also present inside Cmdlets subdirectory with dummy values.
if($verbose)
{
    Write-Host "====================================================";
    Write-Host "'Environment Variables are being loaded.." -ForegroundColor Yellow;
}
Invoke-Expression -Command "C:\Set-EnvironmentVariables.ps1";
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
. $PSScriptRoot\Cmdlets\Add-SqlInstanceInfo.ps1
. $PSScriptRoot\Cmdlets\Collect-DatabaseBackupInfo.ps1
. $PSScriptRoot\Cmdlets\Collect-SecurityCheckInfo.ps1
. $PSScriptRoot\Cmdlets\Collect-VolumeInfo.ps1
. $PSScriptRoot\Cmdlets\Discover-SQLInstances.ps1
. $PSScriptRoot\Cmdlets\Execute-SqlQuery.ps1
. $PSScriptRoot\Cmdlets\Export-Password.ps1
. $PSScriptRoot\Cmdlets\Fetch-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Find-KeywordInSQLDBATools.ps1
. $PSScriptRoot\Cmdlets\Functions_ADOQuery.ps1
#. $PSScriptRoot\Get-DBFiles.ps1
. $PSScriptRoot\Cmdlets\Get-AdministrativeEvents.ps1
. $PSScriptRoot\Cmdlets\Get-AdUserInfo.ps1
. $PSScriptRoot\Cmdlets\Get-ClusterInfo.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseBackupInfo.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseBackupInfo_SMO.ps1
. $PSScriptRoot\Cmdlets\Get-FullQualifiedDomainName.ps1
. $PSScriptRoot\Cmdlets\Get-MachineType.ps1
. $PSScriptRoot\Cmdlets\Get-PerfMonCounters.ps1
. $PSScriptRoot\Cmdlets\Get-PowerPlanInfo.ps1
. $PSScriptRoot\Cmdlets\Get-ProcessForDBA.ps1
. $PSScriptRoot\Cmdlets\Get-RebootHistory.ps1
. $PSScriptRoot\Cmdlets\Get-RunningQueries.ps1
. $PSScriptRoot\Cmdlets\Get-SecurityCheckInfo.ps1
. $PSScriptRoot\Cmdlets\Get-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Get-SQLInstance.ps1
. $PSScriptRoot\Cmdlets\Get-SQLInstanceInfo.ps1
. $PSScriptRoot\Cmdlets\Get-VolumeInfo.ps1
#. $PSScriptRoot\Get-SQLInstance.ps1
. $PSScriptRoot\Cmdlets\Get-VolumeSpaceConsumers.ps1
. $PSScriptRoot\Cmdlets\Get-WhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Invoke-TsqlScript.ps1
. $PSScriptRoot\Cmdlets\Join-Object.ps1
. $PSScriptRoot\Cmdlets\Out-DataTable.ps1
. $PSScriptRoot\Cmdlets\Reset-OwnerShipToSystemAdministrators.ps1
#. $PSScriptRoot\Cmdlets\Restart-WindowsFirewall.ps1
#. $PSScriptRoot\Cmdlets\Restart-WinRM.ps1
. $PSScriptRoot\Cmdlets\Run-CommandMultiThreaded.ps1
. $PSScriptRoot\Cmdlets\Run-sp_WhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Script-SQLDatabaseRestore.ps1
. $PSScriptRoot\Cmdlets\Send-SQLMail.ps1
. $PSScriptRoot\Cmdlets\Set-TivoMailProfile.ps1
#. $PSScriptRoot\Cmdlets\Set-WinRMFirewallRule.ps1
#. $PSScriptRoot\Cmdlets\Set-WinRMListener.ps1
#. $PSScriptRoot\Cmdlets\Set-WinRMStartup.ps1


Push-Location;

<#
Remove-Module SQLDBATools -ErrorAction SilentlyContinue;
Import-Module SQLDBATools -DisableNameChecking;
#>
