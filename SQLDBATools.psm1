<# 
    Module Name:-   SQLDBATools
    Created By:-    Ajay Dwivedi
    Email ID:-      ajay.dwivedi2007@gmail.com
    Modified Date:- 22-Apr-2018
    Version:-       0.2
#>
Push-Location;
Write-Host "====================================================";
Write-Host "Kindly import 'dbatools' powershell module.." -ForegroundColor Green;
Write-Host "====================================================";

<#
# Create -Verbose Switch
if( ($PSCmdlet.MyInvocation.BoundParameters).Count -eq 0 ) {
    $verbose = $false;
}
elseif( $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent ) { $verbose = $true; } else { $verbose = $false; }

# Check for SqlServer module
if ( (Get-Module -ListAvailable -Name SqlServer) -ne $null )
{
    if ( (Get-Module -Name SqlServer) -eq $null ) 
    {
        if($verbose) {
            Write-Host "====================================================";
            Write-Host "'SqlServer' Module is being loaded.." -ForegroundColor Yellow;
        }

        try { Remove-Module SQLPS -ErrorAction SilentlyContinue;
                Import-Module SqlServer -ErrorAction SilentlyContinue; }
        Catch { if($verbose) {Write-Host "Module SqlServer already loaded..";} }

        if($verbose) {
            Write-Host "====================================================";
            Write-Host "'SqlServer' Module is loaded with SQLDBATools.." -ForegroundColor Green;
        }
    }
}
    
# Find SQL PsProvider and load it
$sqlProvider = Get-PSProvider | Where-Object {$_.Name -eq 'SqlServer'}
if([String]::IsNullOrEmpty($sqlProvider.Name))
{
    if($verbose) {
        Write-Host "====================================================";
        Write-Host "'SqlServer' PSProvider not found. Trying to load it with '$PSScriptRoot\Cmdlets\Load-SmoAndSqlProvider.ps1'" -ForegroundColor Yellow;
    }

    Invoke-Expression -Command "$PSScriptRoot\Cmdlets\Load-SmoAndSqlProvider.ps1";

    # Check is SQL PSProvider is loaded now?
    $sqlProvider = Get-PSProvider | Where-Object {$_.Name -eq 'SqlServer'};
    if([String]::IsNullOrEmpty($sqlProvider.Name)) 
    {
        if($verbose) {
            Write-Host "====================================================";
            Write-Host "Could not load SqlServer PSProvider" -ForegroundColor Red;
        }
    }
    else {
        if($verbose) {
            Write-Host "SqlServer PSProvider loaded successfully." -ForegroundColor Green;
        }
    }
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
. $PSScriptRoot\Cmdlets\Script-SQLDatabaseRestore.ps1
. $PSScriptRoot\Cmdlets\Run-CommandMultiThreaded.ps1
. $PSScriptRoot\Cmdlets\Run-sp_WhoIsActive.ps1
. $PSScriptRoot\Cmdlets\Send-SQLMail.ps1
. $PSScriptRoot\Cmdlets\Set-TivoMailProfile.ps1

Push-Location;

<#
Remove-Module SQLDBATools -ErrorAction SilentlyContinue;
Import-Module SQLDBATools -DisableNameChecking;
#>
