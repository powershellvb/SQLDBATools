<# 
    Module Name:-   SQLDBATools
    Created By:-    Ajay Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 22-Apr-2018
    Version:-       0.2
#>
#Import-Module SQLPS -DisableNameChecking;

# File :Set-EnvironmentVariables.ps1" is present @ C:\Users\adwivedi\OneDrive - TiVo Inc\Tivo-Assignments\Set-EnvironmentVariables.ps1
Invoke-Expression -Command "C:\Set-EnvironmentVariables.ps1";
. $PSScriptRoot\Cmdlets\Add-ApplicationInfo.ps1
. $PSScriptRoot\Cmdlets\Add-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Collect-DatabaseBackupInfo.ps1
. $PSScriptRoot\Cmdlets\Collect-VolumeInfo.ps1
. $PSScriptRoot\Cmdlets\Discover-SQLInstances.ps1
. $PSScriptRoot\Cmdlets\Execute-SqlQuery.ps1
. $PSScriptRoot\Cmdlets\Export-Password.ps1
. $PSScriptRoot\Cmdlets\Functions_ADOQuery.ps1
#. $PSScriptRoot\Get-DBFiles.ps1
. $PSScriptRoot\Cmdlets\Get-ProcessForDBA.ps1
. $PSScriptRoot\Cmdlets\Get-RunningQueries.ps1
. $PSScriptRoot\Cmdlets\Get-ServerInfo.ps1
. $PSScriptRoot\Cmdlets\Get-VolumeInfo.ps1
. $PSScriptRoot\Cmdlets\Get-SQLServices_HashArray.ps1
. $PSScriptRoot\Cmdlets\Get-PerfMonCounters.ps1
#. $PSScriptRoot\Get-SQLInstance.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseBackupInfo.ps1
. $PSScriptRoot\Cmdlets\Get-DatabaseBackupInfo_SMO.ps1
. $PSScriptRoot\Cmdlets\Get-VolumeSpaceConsumers.ps1
. $PSScriptRoot\Cmdlets\Out-DataTable.ps1
. $PSScriptRoot\Cmdlets\Script-SQLDatabaseRestore.ps1
. $PSScriptRoot\Cmdlets\Run-CommandMultiThreaded.ps1
. $PSScriptRoot\Cmdlets\Run-sp_WhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Send-SQLMail.ps1

<#
Remove-Module SQLDBATools;
Import-Module SQLDBATools -DisableNameChecking;
#>
