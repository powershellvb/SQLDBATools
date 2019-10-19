Function Set-BaselineWithWhoIsActive {
<#
.SYNOPSIS
This function creates master..sp_WhoIsActive, master..sp_HealthCheck, master..sp_kill & DBA..dbo.usp_WhoIsActive_Blocking
.DESCRIPTION
This function drops and recreates procedures master..sp_WhoIsActive, master..sp_HealthCheck, master..sp_kill & DBA..dbo.usp_WhoIsActive_Blocking. 
Once created, the procedures are Certificate signed using login [CodeSigningLogin] so that users of [public] role are able to execute these objects.
.PARAMETER ServerInstance
Sql Server Instance against which self service modules are to be created    
.EXAMPLE
Set-SelfServiceModules -ServerInstance 'testvm'
The command creates master..sp_WhoIsActive, master..sp_HealthCheck, master..sp_kill & DBA..dbo.usp_WhoIsActive_Blocking on Sql instance 'testvm'.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('SqlInstance')]
        [String]$ServerInstance
    )

    $tsqlQuery = @"
    IF DB_ID('DBA') IS NOT NULL
	    SELECT 1 as [Exists]
    ELSE
	    SELECT 0 as [Exists]
"@;
    $abort = $false;
    $runningCode = $null;
    $Conn = Connect-DbaInstance -SqlInstance testvm -Database DBA;
    $friendlyErrorMessage = "Kindly make sure [DBA] database is created before you execute this cmdlet.";
    $exists = Invoke-DbaQuery -SqlInstance $Conn -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
    if([string]::IsNullOrEmpty($exists) -eq $true -or $exists -eq 0) {
        $abort = $true;
    }
    if ($abort) {
        if ([string]::IsNullOrEmpty($ErrorMessage) -eq $false) {
            $returnMessage = if([string]::IsNullOrEmpty($FailedItem)){$ErrorMessage}else{"$FailedItem => $ErrorMessage"};
        } else {$returnMessage = '';}
        if ([string]::IsNullOrEmpty($runningCode) -eq $false) {
            $rcMessage = "RunningCode => $runningCode" + $NewLine_Single;
        } else {$rcMessage = '';}
        if ([string]::IsNullOrEmpty($friendlyErrorMessage) -eq $false) {
            $feMessage = "FriendlyErrorMessage => $friendlyErrorMessage" + $NewLine_Double;
        } else {$feMessage = '';}

        $returnMessage = $rcMessage + $feMessage + $returnMessage;

        Write-Host "$returnMessage" -ForegroundColor Red;
        return;
    }

    $exists = $null;
    $tsqlQuery = @"
    IF OBJECT_ID('master..sp_WhoIsActive') IS NULL
	    SELECT 0 as [Exists]
    ELSE
	    SELECT 1 as [Exists]
"@;
    $runningCode = $null;
    $friendlyErrorMessage = "Kindly make sure self help stored procedures like sp_HealthCheck/sp_WhoIsActive/sp_Kill/usp_WhoIsActive_Blocking are created using 'Set-SelfServiceModules' cmdlet.";
    $exists = Invoke-DbaQuery -SqlInstance $Conn -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
    if([string]::IsNullOrEmpty($exists) -eq $true -or $exists -eq 0) {
        $abort = $true;
    }
    if ($abort) {
        if ([string]::IsNullOrEmpty($ErrorMessage) -eq $false) {
            $returnMessage = if([string]::IsNullOrEmpty($FailedItem)){$ErrorMessage}else{"$FailedItem => $ErrorMessage"};
        } else {$returnMessage = '';}
        if ([string]::IsNullOrEmpty($runningCode) -eq $false) {
            $rcMessage = "RunningCode => $runningCode" + $NewLine_Single;
        } else {$rcMessage = '';}
        if ([string]::IsNullOrEmpty($friendlyErrorMessage) -eq $false) {
            $feMessage = "FriendlyErrorMessage => $friendlyErrorMessage" + $NewLine_Double;
        } else {$feMessage = '';}

        $returnMessage = $rcMessage + $feMessage + $returnMessage;

        Write-Host "$returnMessage" -ForegroundColor Red;
        return;
    }

    $whoIsActive_Baselining_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\Baselining-with-sp_WhoIsActive.sql";

    Invoke-DbaQuery -SqlInstance $Conn -File $whoIsActive_Baselining_File;
    
    Write-Host "SQL Agent Jobs [DBA - Log_With_sp_WhoIsActive] & [DBA - Log_With_sp_WhoIsActive - Cleanup] are created along with table [DBA]..[WhoIsActive_ResultSets].`r`n Kindly verify the jobs schedule, and test them by manual execution." -ForegroundColor Green;
}