Function Set-BaselineWithWhoIsActive
{
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
    $friendlyErrorMessage = "Kindly make sure self help stored procedures like sp_HealthCheck/sp_WhoIsActive/sp_Kill/usp_WhoIsActive_Blocking are created using 'Setup-SelfServiceModules' cmdlet.";
    $exists = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
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

    $ServerToken = Connect-DbaInstance -SqlInstance $ServerInstance;
    Invoke-DbaQuery -SqlInstance $ServerToken -File $whoIsActive_Baselining_File;
    
    Write-Host "SQL Agent Jobs [DBA - Log_With_sp_WhoIsActive] & [DBA - Log_With_sp_WhoIsActive - Cleanup] are created along with table [DBA]..[WhoIsActive_ResultSets].`r`n Kindly verify the jobs schedule, and test them by manual execution." -ForegroundColor Green;
}