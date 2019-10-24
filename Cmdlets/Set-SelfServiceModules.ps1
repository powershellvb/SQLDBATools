Function Set-SelfServiceModules
{
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

    Write-Verbose "Scanning TSQL script files to be executed";
    $SelfServiceModules_CleanUp_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-Certificate Cleanup.sql";
    $SelfServiceModules_CleanUp_File_DBA = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-Certificate Cleanup-DBA.sql";
    $SelfServiceModules_AllProcedures_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-All-Procedures.sql";
    $SelfServiceModules_SignModules_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-Sign-Procedures.sql";

    $tsqlQuery = @"
    IF DB_ID('DBA') IS NOT NULL
	    SELECT 1 as [Exists]
    ELSE
	    SELECT 0 as [Exists]
"@;
    $abort = $false;
    $runningCode = $null;
    $friendlyErrorMessage = "Kindly make sure [DBA] database is created before you execute this cmdlet.";
    $exists = Invoke-DbaQuery -SqlInstance $ServerInstance -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
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

        Write-Verbose $returnMessage;
        return $returnMessage;
    }

    Write-Verbose "Creating connection against [$ServerInstance] server";
    $ServerToken = Connect-DbaInstance -SqlInstance $ServerInstance;
    
    Write-Verbose "Running Cleanup code from file '$SelfServiceModules_CleanUp_File'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_CleanUp_File;

    Write-Verbose "Running Cleanup code from file '$SelfServiceModules_CleanUp_File_DBA'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_CleanUp_File_DBA;

    Write-Verbose "Compiling All procedures from file '$SelfServiceModules_AllProcedures_File'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_AllProcedures_File;

    Write-Verbose "Creating certificate and signing the modules. Code from file '$SelfServiceModules_SignModules_File'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_SignModules_File;

    Write-Verbose "SelfServiceModules creation finished.";
    return 0;
}