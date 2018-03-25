<# 
    Module Name:-   SQLDBATools
    Created By:-    Ajay Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 23-Oct-2017
    Version:-       0.1
#>
Import-Module SQLPS -DisableNameChecking;

# File :Set-EnvironmentVariables.ps1" is present @ C:\Users\adwivedi\OneDrive - TiVo Inc\Tivo-Assignments\Set-EnvironmentVariables.ps1
Invoke-Expression -Command "C:\Set-EnvironmentVariables.ps1";
. $PSScriptRoot\Functions_ADOQuery.ps1
. $PSScriptRoot\Execute-SqlQuery.ps1
. $PSScriptRoot\Out-DataTable.ps1
. $PSScriptRoot\Run-CommandMultiThreaded.ps1
. $PSScriptRoot\Get-ServerInfo.ps1
. $PSScriptRoot\Get-VolumeInfo.ps1
. $PSScriptRoot\Get-DBFiles.ps1
. $PSScriptRoot\Get-RunningQueries.ps1
. $PSScriptRoot\Run-sp_WhoIsActive.ps1
. $PSScriptRoot\Export-Password.ps1
. $PSScriptRoot\Send-SQLMail.ps1
. $PSScriptRoot\Get-SQLServices_HashArray.ps1
. $PSScriptRoot\Get-PerfMonCounters.ps1
#. $PSScriptRoot\Get-SQLInstance.ps1
. $PSScriptRoot\Get-DatabaseBackupInfo.ps1
. $PSScriptRoot\Get-DatabaseBackupInfo_SMO.ps1
. $PSScriptRoot\Collect-DatabaseBackupInfo.ps1
. $PSScriptRoot\Get-RebootHistory.ps1


