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
    $srvToken = Connect-DbaInstance -SqlInstance $ServerInstance;

    $friendlyErrorMessage = "Kindly make sure [DBA] database is created before you execute this cmdlet.";
    $exists = Invoke-DbaQuery -SqlInstance $srvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
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
    $exists = Invoke-DbaQuery -SqlInstance $srvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
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
    $exists = Invoke-DbaQuery -SqlInstance $srvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
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

    Invoke-DbaQuery -SqlInstance $srvToken -File $LogWalkAlert_with_ServiceBroker_File -ErrorAction SilentlyContinue;
    Write-Verbose "Required databases objects are created/updated.";
    
    $tsqlQuery = @"
SELECT j.name as JobName
		,'EXEC DBA..[usp_GetLogWalkJobHistoryAlert_Suppress] @p_JobName = '''+j.name+'''
                                            ,@p_NoOfContinousFailuresThreshold = 1
											,@p_PerformAutoExecutionOfLogWalkJob = 1
                                            ,@p_DbName = <<DbName>>
                                            ,@p_SendMail = 1 
											,@p_Mail_TO = ''IT-Ops-SQLDBA@tivo.com; DSG-ProductionSupport@tivo.com''
											,@p_Verbose = 0;' as AddCode
FROM msdb..sysjobs_view j where j.enabled = 1 and j.name like 'DBA Log Walk - %'
order by name;
"@;

    $logWalkJobs = Invoke-DbaQuery -SqlInstance $srvToken -Query $tsqlQuery;

    if ([string]::IsNullOrEmpty($logWalkJobs)) {
        Write-Host "Currently no Log Walk job exists on server [$ServerInstance]. " -ForegroundColor Yellow;
    }
    else 
    {
        foreach($job in $logWalkJobs)
        {
            $LogWalkJobName = $job.JobName;
            if($LogWalkJobName -match "^DBA Log Walk - Restore (?'SourceDbName'[\w-]+)\s*[as]{0,2}\s*(?'DestinationDbName'\w*)\s*$") {
                if(-not [string]::IsNullOrEmpty($Matches['DestinationDbName'])) {
                    $LogWalkDbName = $Matches['DestinationDbName'];
                } else {
                    $LogWalkDbName = $Matches['SourceDbName'];
                }
            }
            $JobAddCode = $job.AddCode -replace '<<DbName>>', "'$LogWalkDbName'";
            Write-Host "$LogWalkJobName" -ForegroundColor Yellow;
            Write-Host "$JobAddCode";
        }
        Write-Host "`r`nKindly add above TSQL code as job step, one per Log Walk job, inside SQL Agent job [DBA Log Walk Alerts]." -ForegroundColor Green;
    }
    
    Write-Host "`r`nSQL Agent Job [DBA - Process - WhoIsActiveQueue] is created." -ForegroundColor Green;
}