Function Set-DbaLogWalk
{
<#
.SYNOPSIS
    Create Log Walk job in TiVo environment. This scripts out Database restore code along with job creation.
.DESCRIPTION
    This function accepts Source Server/Database & Destination Server/Database, and creates Log Walk Job.
.PARAMETER SourceServer
    Name of the source server
.PARAMETER SourceDbName
    Name of the Source database
.PARAMETER DestinationServer
    Name of the Destination server
.PARAMETER DestinationDbName
    Name of the Source database
.PARAMETER ScriptOutPermissions
    With this switch, script out existing database permissions
.PARAMETER RecoverDatabase
    With this switch, script out database RESTORE to perform refresh and RECOVER databases by brining them in READ_WRITE mode
.PARAMETER GenerateRESTOREScriptOnly
    With this switch, script out database RESTORE with update script for [DBALastFileApplied] ONLY. Do not check Baselining, SelfServiceModules, ServiceBroker setup, or LogWalk existance.
.PARAMETER SizeThreshold_GB
    Size in GigaBytes. Default 30. For backup files larger than SizeThreshold_GB, ROBOCOPY command will be generated to copy them on Destination Server from Source Server.
.PARAMETER ProcessAllLogBackups
    With this switch, we process all available Log backup files. By default, we process, last Full, diff & 1st Log backup.
.EXAMPLE
    C:\PS> Setup-DbaLogWalk -SourceServer DbServer01 -SourceDbName MyDb1 -DestinationServer DbServer02
    Generates RESTORE tsql code for [MyDb1] database, and creates Log Walk job named [DBA Log Walk - Restore MyDb1 as MyDb1]
.EXAMPLE
    C:\PS> Setup-DbaLogWalk -SourceServer DbServer01 -SourceDbName MyDb1 -DestinationServer DbServer02 -DestinationDbName MyDb2
    Generates RESTORE tsql code for [MyDb2] database, and creates Log Walk job named [DBA Log Walk - Restore MyDb1 as MyDb2]
.EXAMPLE
    C:\PS> Setup-DbaLogWalk -SourceServer DbServer01 -SourceDbName MyDb1 -DestinationServer DbServer02 -DestinationDbName MyDb2 -ScriptOutPermissions
    Script out existing permissions of DestinationDbName, and then Generate RESTORE tsql code for [MyDb2] database, and creates Log Walk job named [DBA Log Walk - Restore MyDb1 as MyDb2]
.EXAMPLE
    C:\PS> Setup-DbaLogWalk -SourceServer DbServer01 -SourceDbName MyDb1 -DestinationServer DbServer02 -DestinationDbName MyDb2 -ScriptOutPermissions -RecoverDatabase
    Script out existing permissions of DestinationDbName and Generate RESTORE tsql code for [MyDb2] database. The code generated will bring database in READ_WRITE mode(RECOVERY).
.EXAMPLE
    C:\PS> Setup-DbaLogWalk -SourceServer DbServer01 -SourceDbName MyDb1 -DestinationServer DbServer02 -DestinationDbName MyDb2 -GenerateRESTOREScriptOnly
    Generate RESTORE tsql code for [MyDb2] database with NORECOVERY option
.EXAMPLE
    C:\PS> Setup-DbaLogWalk -SourceServer DbServer01 -SourceDbName MyDb1 -DestinationServer DbServer02 -DestinationDbName MyDb2 -GenerateRESTOREScriptOnly -ProcessAllLogBackups
    Generate RESTORE tsql code for [MyDb2] database with NORECOVERY option with Last Full + Diff + All available log backups.
.LINK
    https://github.com/imajaydwivedi/SQLDBATools
.NOTES
    Author: Ajay Dwivedi
    EMail:  ajay.dwivedi2007@gmail.com
    Date:   June 14, 2019
    Documentation: https://github.com/imajaydwivedi/SQLDBATools   
#>
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory=$true )]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance_Source')]
        [String]$SourceServer,

        [Parameter( Mandatory=$true )]
        [ValidateNotNullOrEmpty()]
        [Alias('SourceDb')]
        [String]$SourceDbName,

        [Parameter( Mandatory=$true )]
        [ValidateNotNullOrEmpty()]
        [Alias('SQLInstance_Destination')]
        [String]$DestinationServer,

        [Parameter( Mandatory=$false )]
        [Alias('DestinationDb')]
        [String]$DestinationDbName,
       
        [Parameter( Mandatory=$false )]
        [Alias('ScriptPermissions')]
        [Switch]$ScriptOutPermissions,

        [Parameter( Mandatory=$false )]
        [Alias('SetRecovery','EnableDatabaseRecovery','EnableRecovery')]
        [Switch]$RecoverDatabase,

        [Parameter( Mandatory=$false )]
        [Alias('GenerateDatabaseRESTOREScriptOnly')]
        [Switch]$GenerateRESTOREScriptOnly,

        [Parameter( Mandatory=$false )]
        [Alias('BackupFileSizeThreshold4RemoteCopy_GB')]
        [Double]$SizeThreshold_GB = 30,

        [Parameter( Mandatory=$false )]
        [Alias('ProcessAllAvailableLogBackups')]
        [Switch]$ProcessAllLogBackups
    )

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

    if($RecoverDatabase) {$GenerateRESTOREScriptOnly = $true}

    # variable to track Fatal Error
    $abort = $false;
    $runningCode = $null;
    $NewLine_Single = "`r`n";
    $NewLine_Double = "`r`n`r`n";
    $destinationDbExists = 0;

    # Create File Path
    $DbaLogWalk_ScriptPath = "c:\temp\TivoDbaLogWalk\$($SourceServer)___2___$($DestinationServer)\$((Get-Date -Format 'yyyy-MMM-dd'))\";
    Write-Verbose "Checking if script path '$DbaLogWalk_ScriptPath' exists";
    if([System.IO.Directory]::Exists($DbaLogWalk_ScriptPath) -eq $false) {
        New-Item -ItemType "directory" -Path $DbaLogWalk_ScriptPath;
    }

    if([string]::IsNullOrEmpty($DestinationDbName) -eq $true) {$DestinationDbName = $SourceDbName};
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
    if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
        Write-Host "Verifying the recovery model for database '$SourceDbName'";
    }
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
	    SELECT 1 AS [Exists], case when d.state_desc = 'ONLINE' then 1 else 0 end as IsOnline FROM sys.databases as d where d.name = '$DestinationDbName';
    ELSE
	    SELECT 0 AS [Exists], 0 as IsOnline;
"@;
    $ExistsOnline = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqlQuery;
    $destinationDbExists = $ExistsOnline.Exists;
    $destinationDbOnline = $ExistsOnline.IsOnline;
    if([string]::IsNullOrEmpty($destinationDbExists) -eq $false -and $destinationDbOnline -eq 1 -and $ScriptOutPermissions -eq $true)
    {
        Write-Host "Scripting out permissions for database [$SourceDbName] in file '$($DbaLogWalk_ScriptPath)01) Destination-Permissions-ScriptOut.sql'" -ForegroundColor Yellow;
        Export-SqlUser -SqlInstance $destinationSrvToken -Database $DestinationDbName -Path "$($DbaLogWalk_ScriptPath)01) Destination-Permissions-ScriptOut.sql" -NoClobber -Append;
    }

    # Check 03 => Verify existance of sp_Kill, sp_WhoIsActive, usp_WhoIsActive_Blocking
    if($GenerateRESTOREScriptOnly)
    {
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
        $friendlyErrorMessage = "Kindly make sure pre-requisites of New Log Walk Alert with ServiceBroker is established using 'Setup-ServiceBroker_4_LogWalkAlert' cmdlet.";
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

        # Check 07 => Create table DBA..DBALastFileApplied
        $tsqlQuery = @"
        IF OBJECT_ID('DBA..DBALastFileApplied') IS NOT NULL
	        SELECT 1 AS [Exists];
        ELSE
	        SELECT 0 AS [Exists];
"@;
        $runningCode = $null;
        $friendlyErrorMessage = "Kindly make sure table [DBA]..[DBALastFileApplied] exists.";

        $exists = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
        if([string]::IsNullOrEmpty($exists) -eq $true -or $exists -eq 0) 
        {
            $LogWalk_tbl_DBALastFileApplied_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\LogWalk_tbl_DBALastFileApplied.sql";    
            Invoke-DbaQuery -SqlInstance $destinationSrvToken -File $LogWalk_tbl_DBALastFileApplied_File;
            Write-Host "Table table [DBA]..[DBALastFileApplied] created successfully." -ForegroundColor Yellow;
        }
    }

    # Step 08 => Script out RESTORE database tsql code    
    $runningCode = "Get-DbaBackupHistory -SqlInstance $SourceServer -Database $SourceDbName -Last -DeviceType Disk";
    $friendlyErrorMessage = "Kindly make Full+Log backup jobs are configured on source [$SourceServer] for database [$SourceDbName].";
    $latestBackups = Get-DbaBackupHistory -SqlInstance $sourceSrvToken -Database $SourceDbName -Last -DeviceType Disk;

    if([string]::IsNullOrEmpty($latestBackups)) {
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

    $existingFiles = $null;
    if($destinationDbExists -eq 1)
    {
        $tsqExistingFiles = @"
    select CASE WHEN mf.type_desc = 'ROWS' THEN 'D' ELSE 'L' END as FileType, mf.name as LogicalName, mf.physical_name as PhysicalName
    from sys.master_files as mf where mf.database_id = db_id('$DestinationDbName')
"@;
        $existingFiles = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqExistingFiles;
    }

    $commentHeader = if ($SourceDbName -eq $DestinationDbName) {"[$SourceServer]"} else {"[$SourceDbName] => [$DestinationDbName]"};
    $restoreText_Full = '';
    $restoreText_Differential = '';
    $restoreText_Log = '';
    $restoreText_RoboCopy = '';
    $restoreText_Final = "";

    $isFirstLogBackupApplied = $false;
    $LastFileApplied = $null;
    $bkpFileSize_Larger = $false;
    $logBackupFiles_Counter = 0;
    $isLastLogBackupFile = $false;
    $logBackupFiles_Count = @($latestBackups | Where-Object {$_.Type -eq 'LOG'}).Count;
    if($ProcessAllLogBackups -eq $false) {
        if($logBackupFiles_Count -ge 2) {
            $logBackupFiles_Count = 1;
        }
    }

    foreach($bkp in $latestBackups)
    {
        if($bkp.Type -eq 'LOG'){$logBackupFiles_Counter += 1}
        if($logBackupFiles_Counter -gt $logBackupFiles_Count) {
            break;
        }

        if($logBackupFiles_Counter -eq $logBackupFiles_Count){$isLastLogBackupFile = $true}
        
        $bkpFileSize_GB = $null;

        $bkpFileSize_GB = $bkp.CompressedBackupSize.Gigabyte;
        if([string]::IsNullOrEmpty($bkpFileSize_GB)){$bkpFileSize_GB = $bkp.TotalSize.Gigabyte}

        if($bkpFileSize_GB -gt $SizeThreshold_GB -and $bkpFileSize_Larger -eq $false){$bkpFileSize_Larger = $true}
        
        if($bkp.Path -match ":") {
            $backupPath = "\\$SourceServer\" + ($($bkp.Path) -replace ':\\','$\');
        }else {
            $backupPath = $bkp.Path;        
        }

        $backupFile_BaseName = if($($bkp.Path) -match ".+\\(?'fileName'\w+\.[a-zA-Z]{1,3})") {$Matches['fileName']} else {$null};
        
        if($bkpFileSize_GB -gt $SizeThreshold_GB) 
        {
            $backupFile_NetworkPathDirectory = (Get-ItemProperty $backupPath | Select-Object -ExpandProperty DirectoryName)+'\';    
            $src = $backupFile_NetworkPathDirectory;
            $dst = 'Local\Path\On\Destination\';
            $restoreText_RoboCopy += "Invoke-Command -ComputerName $DestinationServer -ScriptBlock { robocopy '$src' '$dst' $backupFile_BaseName /it}";            
        }

        if($bkp.Type -eq 'Full') #'Log','Differential'
        {
            $restoreText_Full = @"
    
        -- $commentHeader - Full restore of $($bkp.TotalSize) total size from $($bkp.CompressedBackupSize) backup of '$($bkp.Start)'
        RESTORE DATABASE [$DestinationDbName] FROM DISK = N'$(if($bkpFileSize_GB -gt $SizeThreshold_GB){$dst+$backupFile_BaseName}else{$backupPath})'
            WITH    NORECOVERY,
                    STATS = 5
                    $(if($destinationDbExists -eq 1){',REPLACE'})
"@;

            # Add WITH MOVE option in Full Restore
            $fileList = if($destinationDbExists -eq 1){$existingFiles}else{$bkp.FileList};
            foreach ($file in $fileList)
            {
                $restoreText_Full += @"
`r`n                    ,MOVE N'$($file.LogicalName)' TO N'$($file.PhysicalName)'
"@;
            }

            $restoreText_Full += @"

        GO


"@;
        }

        if($bkp.Type -eq 'Differential')
        {
            $restoreText_Differential = @"
        -- $commentHeader - Differential restore of $($bkp.TotalSize) total size from $($bkp.CompressedBackupSize) backup of '$($bkp.Start)'
        RESTORE DATABASE [$DestinationDbName] FROM DISK = N'$(if($bkpFileSize_GB -gt $SizeThreshold_GB){$dst}else{$backupPath})'
            WITH    NORECOVERY,
                    STATS = 5
"@;
        
            $restoreText_Differential += @"

        GO


"@;
        }

        if($bkp.Type -eq 'Log')
        {
            $restoreText_Log += @"
        -- $commentHeader - Log restore of $($bkp.TotalSize) total size from backup of '$($bkp.Start)'
        RESTORE LOG [$DestinationDbName] FROM DISK = N'$backupPath'
            WITH    STATS = 5,
                    $(if($isLastLogBackupFile -and $RecoverDatabase){'RECOVERY'}else{'NORECOVERY'})
"@;

            $restoreText_Log += @"

        GO


"@;
            if($isLastLogBackupFile) {
                $LastFileApplied = $backupFile_BaseName;
            }
        }
    }

    $tsqlUpdateLastFileApplied = @"
        USE DBA;
        GO

        IF EXISTS (SELECT * FROM [dbo].[DBALastFileApplied] WHERE [dbname] = '$DestinationDbName')
	        UPDATE [dbo].[DBALastFileApplied] SET [LastFileApplied] = '$LastFileApplied', [PointerResetFile] = '$LastFileApplied'  WHERE [dbname] = '$DestinationDbName';
        ELSE
	        INSERT [dbo].[DBALastFileApplied] ([dbname],[LastFileApplied],[PointerResetFile]) SELECT '$DestinationDbName','$LastFileApplied','$LastFileApplied';
        GO

"@;

    $tsqlKillDatabaseSessions = '';
    if($destinationDbOnline -eq 1) {
        $tsqlKillDatabaseSessions = @"

        USE master
        GO

        EXEC sp_Kill @p_DbName = '$DestinationDbName', @p_Force = 1;
        GO

"@;
    }

    $restoreText_Final = $(if($bkpFileSize_Larger){$restoreText_RoboCopy}else{''}) + $tsqlKillDatabaseSessions + $restoreText_Full + $restoreText_Differential + $restoreText_Log + $(if($RecoverDatabase){''}else{$tsqlUpdateLastFileApplied});
    
    $scriptOutRESTORE_SmallDbs_File = "$($DbaLogWalk_ScriptPath)02) RESTORE Database - ScriptOut - SmallDbs.sql";
    $scriptOutRESTORE__LargeDbs_File = "$($DbaLogWalk_ScriptPath)02) RESTORE Database - ScriptOut - LargeDbs.sql";
    
    $scriptOutRESTORE_File = if($bkpFileSize_Larger){$scriptOutRESTORE__LargeDbs_File}else{$scriptOutRESTORE_SmallDbs_File}

    Write-Host "Scripting out RESTORE code for database [$DestinationDbName] in file '$scriptOutRESTORE_File'" -ForegroundColor Yellow;
    $restoreText_Final | Out-File -FilePath $scriptOutRESTORE_File -Append;
    #Write-Host "Opening the scripted DATABASE RESTORE tsql code in notepad.." -ForegroundColor Green;
    #notepad "$scriptOutRESTORE_File";

    if($RecoverDatabase -eq $false -and $GenerateRESTOREScriptOnly -eq $false)
    {
        $logWalkJobText = Get-Content "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\LogWalk_Create_Job.sql";
        $tsqlLogWalkJobCreation = $logWalkJobText  -replace 'AjayDwivediSourceDatabase',"$SourceDbName";
        $tsqlLogWalkJobCreation = $tsqlLogWalkJobCreation  -replace 'AjayDwivediDestinationDatabase',"$DestinationDbName";
        $SourceLogFilesNetworkPath = (Get-ItemProperty $backupPath | Select-Object -ExpandProperty DirectoryName)+'\';
        $tsqlLogWalkJobCreation = $tsqlLogWalkJobCreation  -replace 'SourceLogFilesNetworkPath',"$SourceLogFilesNetworkPath";
        $tsqlLogWalkJobCreation = $tsqlLogWalkJobCreation  -replace 'TufFilesLocation','f:\LogWalk_TUF_Files\';

        $tsqlQuery = @"
        IF NOT EXISTS (select * from msdb.dbo.sysjobs as j where j.name = 'DBA Log Walk - Restore $SourceDbName as $DestinationDbName')
	        SELECT 0 as [Exists]
        ELSE
	        SELECT 1 as [Exists]
"@;
        $scriptOutLogWalkJobCreation_File = "$($DbaLogWalk_ScriptPath)03) DBA Log Walk - Restore $SourceDbName as $DestinationDbName.sql";
        $tsqlLogWalkJobCreation | Out-File -FilePath $scriptOutLogWalkJobCreation_File -Append;
        $exists = Invoke-DbaQuery -SqlInstance $destinationSrvToken -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
        if([string]::IsNullOrEmpty($exists) -eq $true -or $exists -eq 0) {
            Write-Host "Creating job [DBA Log Walk - Restore $SourceDbName as $DestinationDbName] on $DestinationServer" -ForegroundColor Yellow;
            Invoke-DbaQuery -SqlInstance $destinationSrvToken -File $scriptOutLogWalkJobCreation_File;
            Write-Host "Job [DBA Log Walk - Restore $SourceDbName as $DestinationDbName] is created." -ForegroundColor Green;
        }
        else {
            Write-Host "Job named [DBA Log Walk - Restore $SourceDbName as $DestinationDbName] already exists. So simply scripting job creation code in file '$scriptOutLogWalkJobCreation_File'." -ForegroundColor Green;
        }
    }
}

