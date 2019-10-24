Function Set-BaselineWithWhoIsActive {
<#
.SYNOPSIS
This function creates baselining of server using sp_WhoIsActive monitoring procedue
.DESCRIPTION
This function creates 2 jobs named [DBA - Log_With_sp_WhoIsActive] and [DBA - Log_With_sp_WhoIsActive - Cleanup] to capture what is running on server with default frequency of 15 minutes.
.PARAMETER SqlInstance
Sql Server Instance where whoIsActive baselining has to be setup.
.EXAMPLE
Set-BaselineWithWhoIsActive -SqlInstance 'testvm'
The command creates 2 jobs named [DBA - Log_With_sp_WhoIsActive] and [DBA - Log_With_sp_WhoIsActive - Cleanup] on Sql instance 'testvm'.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('ServerInstance')]
        [String]$SqlInstance
    )

    $tsqlQuery = @"
    IF DB_ID('DBA') IS NOT NULL
	    SELECT 1 as [Exists]
    ELSE
	    SELECT 0 as [Exists]
"@;
    $abort = $false;
    $runningCode = $null;
    $Conn = Connect-DbaInstance -SqlInstance $SqlInstance -Database DBA;
    $friendlyErrorMessage = "Kindly make sure [DBA] database is created before you execute this cmdlet.";

    Write-Verbose "Verify if [DBA] database exists";
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

        Write-Verbose "$returnMessage";
        return $returnMessage;
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

    Write-Verbose "Verify if Self-Service modules are present";
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

        Write-Verbose "$returnMessage";
        return $returnMessage;
    }

    Write-Verbose "Scanning TSQL script file to execute";
    $whoIsActive_Baselining_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\Baselining-with-sp_WhoIsActive.sql";

    if($PSCmdlet.ShouldProcess("$SqlInstance")) {
        Write-Verbose "Setting WhoIsActive baselining";
        Invoke-DbaQuery -SqlInstance $Conn -File $whoIsActive_Baselining_File;    
        Write-Verbose "SQL Agent Jobs [DBA - Log_With_sp_WhoIsActive] & [DBA - Log_With_sp_WhoIsActive - Cleanup] are created along with table [DBA]..[WhoIsActive_ResultSets].`r`n Kindly verify the jobs schedule, and test them by manual execution.";
        return 0;
    }
}