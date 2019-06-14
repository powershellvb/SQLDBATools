$SourceServer = 'TUL1MDPDWMID01';
$SourceDbName = 'MuzeUK';
$DestinationServer = 'TUL1MDPDWDS12';
$DestinationDbName = 'MuzeUK';

<#  Script to Setup Log Walk jobs
    Prerequisites:
    1) Source Server should have databases in 'FULL' recovery model
    2) If Destination databases are present, then scriptout permissions, then REPLACE, keeping same database file locations
    3) Check if usual DBA procedures are present
        a) master..sp_Kill
        b) master..sp_HealthCheck
        c) master..sp_WhoIsActive
        d) DBA..usp_WhoIsActive_Blocking
    4) Setup Baselining with [sp_WhoIsActive]
    5) Setup ServiceBroker for new LogWalkAlert
    6) Restore Databases from Source to Destination with NORECOVERY
    7) Create DBA..usp_DBADropDbSnaphot
    8) Create DBA..usp_DBAApplyTLogs
#>

# variable to track Fatal Error
$abort = $false;
$runningCode = $null;
$NewLine_Single = "`r`n";
$NewLine_Double = "`r`n`r`n";
$destinationDbExists = 0;

# Create File Path
$DbaLogWalk_ScriptPath = "c:\temp\TivoDbaLogWalk\$($SourceServer)___2___$($DestinationServer)\$((Get-Date -Format 'yyyy-MMM-dd'))\";
if([System.IO.Directory]::Exists($DbaLogWalk_ScriptPath) -eq $false) {
    New-Item -ItemType "directory" -Path $DbaLogWalk_ScriptPath;
    #$DbaLogWalk_ScriptPath = Get-ItemProperty -LiteralPath $DbaLogWalk_ScriptPath | Select-Object -ExpandProperty FullName;
    #$DbaLogWalk_ScriptPath = $DbaLogWalk_ScriptPath + '\';
    Set-Location $DbaLogWalk_ScriptPath;
}

if($DestinationDbName -eq $null) {$DestinationDbName = $SourceDbName};
$ErrorMessage = $null;

# Create Source Server Token
try {
    $runningCode = "Connect-DbaInstance -SqlInstance $SourceServer";
    $friendlyErrorMessage = "Kindly verify if server '$SourceServer' is up and accessible";
    $sourceSrvToken = Connect-DbaInstance -SqlInstance $SourceServer;
}
catch {
    $ErrorMessage = $_.Exception.Message;
    $FailedItem = $_.Exception.ItemName;
    $abort = $true;
}

if ($abort) {
    $returnMessage = if([string]::IsNullOrEmpty($FailedItem)){$ErrorMessage}else{"$FailedItem => $ErrorMessage"};
    $returnMessage = "RunningCode => $runningCode" + $NewLine_Single + "FriendlyErrorMessage => $friendlyErrorMessage" + $NewLine_Double + $returnMessage;
    Write-Host "$returnMessage" -ForegroundColor Red;
    return;
}

# Create Destination Server Token
try {
    $runningCode = "Connect-DbaInstance -SqlInstance $DestinationServer";
    $friendlyErrorMessage = "Kindly verify if server '$DestinationServer' is up and accessible";
    $destinationSrvToken = Connect-DbaInstance -SqlInstance $DestinationServer;
}
catch {
    $ErrorMessage = $_.Exception.Message;
    $FailedItem = $_.Exception.ItemName;
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

# Check 01 => Source database Recovery Model
$runningCode = "select d.recovery_model_desc from sys.databases as d where d.name = '$SourceDbName'";
$friendlyErrorMessage = "Kindly make sure recovery model for database '$SourceDbName' is set to FULL.";
$rModel = Invoke-DbaQuery -SqlInstance $sourceSrvToken -Query "select d.recovery_model_desc from sys.databases as d where d.name = '$SourceDbName'" | Select-Object -ExpandProperty recovery_model_desc;
if([String]::IsNullOrEmpty($rModel) -or $rModel -ne 'Full') {
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

# Check 02 => Verify existance of Destination db, and Scriptout permissions
$tsqlQuery = @"
IF EXISTS (SELECT * FROM sys.databases as d where d.name = '$DestinationDbName')
	SELECT 1 AS [Exists];
ELSE
	SELECT 0 AS [Exists];
"@;
$destinationDbExists = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
if([string]::IsNullOrEmpty($destinationDbExists) -eq $false -and $destinationDbExists -eq 1)
{
    Set-Location $DbaLogWalk_ScriptPath;
    #Export-SqlUser -SqlInstance $destinationSrvToken -Database $DestinationDbName -Path '01) Destination-Permissions-ScriptOut.sql' -NoClobber -Append;
}

# Check 03 => Verify existance of sp_Kill, sp_WhoIsActive, usp_WhoIsActive_Blocking
$tsqlQuery = @"
IF OBJECT_ID('master..sp_WhoIsActive') IS NULL OR OBJECT_ID('master..sp_Kill') IS NULL OR OBJECT_ID('DBA..usp_WhoIsActive_Blocking') IS NULL
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


# Check 04 => Setup Baselining with [sp_WhoIsActive]
$tsqlQuery = @"
IF NOT EXISTS (select * from msdb.dbo.sysjobs as j where j.name = 'DBA - Log_With_sp_WhoIsActive - Cleanup')
	SELECT 0 as [Exists]
ELSE
	SELECT 1 as [Exists]
"@;
$runningCode = $null;
$friendlyErrorMessage = "Kindly make sure server baselining is done with [sp_WhoIsActive] using 'Setup-BaselineWithWhoIsActive' cmdlet.";
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


# Check 05 => Setup ServiceBroker for new LogWalkAlert
$tsqlQuery = @"
IF NOT EXISTS (select * from msdb.dbo.sysjobs as j where j.name = 'DBA - Process - WhoIsActiveQueue')
	SELECT 0 as [Exists]
ELSE
	SELECT 1 as [Exists]
"@;
$runningCode = $null;
$friendlyErrorMessage = "Kindly make sure pre-requisites of New Log Walk Alert with ServiceBroker is established using 'Setup-LogWalkAlert_with_ServiceBroker' cmdlet.";
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

# Check 06 => Create required procs [usp_DBAApplyTLogs],[usp_DBADropDbSnaphot],[usp_DBAKillInactiveUser]
$tsqlQuery = @"
IF OBJECT_ID('DBA..usp_DBAApplyTLogs') IS NULL OR OBJECT_ID('DBA..usp_DBADropDbSnaphot') IS NULL OR OBJECT_ID('DBA..usp_DBAKillInactiveUser') IS NULL
	SELECT 0 as [Exists];
ELSE
	SELECT 1 as [Exists];
"@;
$runningCode = $null;
$friendlyErrorMessage = "Kindly make sure required procedures [usp_DBAApplyTLogs],[usp_DBADropDbSnaphot],[usp_DBAKillInactiveUser] are created in DBA database.";

$exists = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
if([string]::IsNullOrEmpty($exists) -eq $true -or $exists -eq 0) 
{
    $LogWalk_usp_DBAKillInactiveUser_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\LogWalk_usp_DBAKillInactiveUser.sql";
    $LogWalk_usp_DBADropDbSnaphot_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\LogWalk_usp_DBADropDbSnaphot.sql";
    $LogWalk_usp_DBAApplyTLogs_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\LogWalk_usp_DBAApplyTLogs.sql";
    
    Invoke-DbaQuery -SqlInstance $destinationSrvToken -File $LogWalk_usp_DBAKillInactiveUser_File -ErrorAction SilentlyContinue;
    Invoke-DbaQuery -SqlInstance $destinationSrvToken -File $LogWalk_usp_DBADropDbSnaphot_File -ErrorAction SilentlyContinue;
    Invoke-DbaQuery -SqlInstance $destinationSrvToken -File $LogWalk_usp_DBAApplyTLogs_File -ErrorAction SilentlyContinue;

    Write-Host "Log Walk job dependent procedures [usp_DBAApplyTLogs],[usp_DBADropDbSnaphot] & [usp_DBAKillInactiveUser] are created in DBA database." -ForegroundColor Yellow;
}

# Step 07 => Script out RESTORE database tsql code
$existingFiles = $null;
if($destinationDbExists -eq 1)
{
    $tsqExistingFiles = @"
select mf.name as logical_name, mf.physical_name, mf.type_desc
from sys.master_files as mf where mf.database_id = db_id('$DestinationDbName')
"@;
    $existingFiles = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqExistingFiles;
}

$sourceFiles = $null;
$tsqlSourceFiles = @"
select mf.name as logical_name, mf.physical_name, mf.type_desc
from sys.master_files as mf where mf.database_id = db_id('$SourceDbName')
"@;
    $sourceFiles = Invoke-DbaQuery -SqlInstance $sourceSrvToken -Query $tsqlSourceFiles;
    
$latestBackups = Get-DbaBackupHistory -SqlInstance $sourceSrvToken -Database $SourceDbName -Last -DeviceType Disk;
