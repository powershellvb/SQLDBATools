Function Set-ServiceBroker_4_LogWalkAlert
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

    $exists = $null;
    $tsqlQuery = @"
    IF NOT EXISTS (select * from msdb.dbo.sysjobs as j where j.name = 'DBA - Log_With_sp_WhoIsActive')
	    SELECT 0 as [Exists]
    ELSE
	    SELECT 1 as [Exists]
"@;
    $runningCode = $null;
    $friendlyErrorMessage = "Kindly make sure Baselining of Server with sp_WhoIsActive is established using 'Setup-BaselineWithWhoIsActive' cmdlet.";
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

    $LogWalkAlert_with_ServiceBroker_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\LogWalkAlert_with_ServiceBroker.sql";

    Write-Verbose "Creating Connection to server, and running script '$LogWalkAlert_with_ServiceBroker_File'";
    $ServerToken = Connect-DbaInstance -SqlInstance $ServerInstance;
    Invoke-DbaQuery -SqlInstance $ServerToken -File $LogWalkAlert_with_ServiceBroker_File -ErrorAction SilentlyContinue;
    Write-Verbose "Required databases objects are created/updated.";

    $tsqlQuery = @"
SELECT j.name as JobName
		,'EXEC DBA..[usp_GetLogWalkJobHistoryAlert_Suppress] @p_JobName = '''+j.name+''', @p_NoOfContinousFailuresThreshold = 2
											,@p_SendMail = 1 
											,@p_Mail_TO = ''IT-Ops-SQLDBA@tivo.com; DSG-ProductionSupport@tivo.com''
											--,@p_Mail_TO = ''ajay.dwivedi@tivo.com;renuka.chopra@tivo.com''
											,@p_Mail_CC = ''Sameer.Jadhav@tivo.com; Niccolo.Arici@tivo.com; Thanveer.Ahamed@tivo.com; Vineet.Agarwal@tivo.com; Luigi.DeGiovanni@tivo.com''
											--,@p_GetSessionRequestDetails = 1
											--,@p_Verbose = 1;' as AddCode
FROM msdb..sysjobs_view j where j.enabled = 1 and j.name like 'DBA Log Walk - %'
order by name;
"@;

    #Write-Host $tsqlQuery;

    $logWalkJobs = Invoke-DbaQuery -SqlInstance $ServerToken -Query $tsqlQuery;

    if ([string]::IsNullOrEmpty($logWalkJobs)) {
        Write-Host "Currently no Log Walk job exists on server [$ServerInstance]. " -ForegroundColor Yellow;
    }
    else 
    {
        foreach($job in $logWalkJobs)
        {
            Write-Host "$($job.JobName)" -ForegroundColor Yellow;
            Write-Host "$($job.AddCode)";
        }
        Write-Host "`r`nKindly add above TSQL code as job step, one per Log Walk job, inside SQL Agent job [DBA Log Walk Alerts]." -ForegroundColor Green;
    }
    
    Write-Host "`r`nSQL Agent Job [DBA - Process - WhoIsActiveQueue] is created." -ForegroundColor Green;
}