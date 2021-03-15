function Get-BackupHistory {
<#
    .SYNOPSIS
    This function returns database backup history required to perform database restore
    .DESCRIPTION
    This function returns database backup history for performing either latest restore or point in time recovery.
    It accepts SqlInstance, databases to include/exclude and StopAtTime for point in time recovery.
    .PARAMETER SqlInstance
    Name of SqlInstance where backup history is to be searched
    .PARAMETER Database
    Databases for which backup history is required
    .PARAMETER ExcludeDatabase
    Databases which should be excluded from backup history
    .PARAMETER BackupType
    Type of backup required. Choices include 'Full', 'Diff' and 'Log'
    .PARAMETER StopAtTime
    Point in time for restoring Log Backups
    .EXAMPLE
    Get-BackupHistory -SqlInstance 'testvm' -Database 'db01','Db02' -BackupType Log;
    This command return latest set of Full, Diff & Log for databases db01 and db02 from server testvm
    .EXAMPLE
    Get-BackupHistory -SqlInstance 'testvm' -ExcludeDatabase 'db01','Db02' -BackupType Full;
    This command return latest set of Full bacukps for all databases except db01 and db02 from server testvm
#>
    [CmdletBinding()]
    Param (
        [String]$SqlInstance,
        [String[]]$Database,
        [String[]]$ExcludeDatabase,
        [ValidateSet("Full", "Diff", "Log")][Alias('Type')]
        [String]$BackupType = 'Log',
        [Parameter(HelpMessage="Enter DateTime in 24 hours format (yyyy-MM-dd hh:mm:ss)")]
        [String]$StopAtTime
    )

    # StopAt in String format
    if ([string]::IsNullOrEmpty($StopAtTime) -eq $false) {
        try {
            Write-Verbose "`$StopAtTime = '$StopAtTime'";

            $format = "yyyy-MM-dd HH:mm:ss";
            Write-Verbose "`$format = '$format'";

            $StopAt_Time = [DateTime]::ParseExact($StopAtTime, $format, $null);
            Write-Verbose "`$StopAt_Time = '$StopAt_Time'";

            $StopAt_String = ($StopAt_Time).ToString('MMM dd, yyyy hh:mm:ss tt');
            Write-Verbose "`$StopAt_String = '$StopAt_String'";
        }
        catch {
            Write-Error "Invalid datetime format specified for `$StopAt_Time parameter. Kindly use format:  (yyyy-MM-dd hh:mm:ss)";
            return;
        }
    }

    # Format $Database input
    if([String]::IsNullOrEmpty($Database) -eq $false) {
        #$Database = @('StackOverflow2010','DBA_Snapshot','Staging,Staging2,StagingFiltered','[Mosaic],[MosaicFiltered],RCM_rovicore_20130710_NoMusic1a_en-US')

        Write-Verbose "Formatting `$Database parameter";
        # Create array of databases removing single quotes, square brackets, other other wrong formats
        $DatabaseList = @();
        foreach($dbItem in $Database) {
            $arrayItems = $dbItem.Split(',');
            foreach($arrItem in $arrayItems) {
                $arrItem = $arrItem.Replace("'",''); # remove single quotes
                $arrItem = ($arrItem.Replace('[','')).Replace(']',''); # remove square brackets
                $DatabaseList += $arrItem;
            }
        }

        $Database = $DatabaseList;
        $DatabaseCommaList = "'$($Database -join "','")'";
    }

    # Format $ExcludeDatabase input
    if([String]::IsNullOrEmpty($ExcludeDatabase) -eq $false) {
        # Create array of databases removing single quotes, square brackets, other other wrong formats

        Write-Verbose "Formatting `$ExcludeDatabase parameter";
        $ExcludeDatabaseList = @();
        foreach($dbItem in $ExcludeDatabase) {
            $arrayItems = $dbItem.Split(',');
            foreach($arrItem in $arrayItems) {
                $arrItem = $arrItem.Replace("'",''); # remove single quotes
                $arrItem = ($arrItem.Replace('[','')).Replace(']',''); # remove square brackets
                $ExcludeDatabaseList += $arrItem;
            }
        }

        $ExcludeDatabase = $ExcludeDatabaseList;
        $ExcludeDatabaseCommaList = "'$($ExcludeDatabase -join "','")'";
    }

    if($Database.Count -gt 0 -and $ExcludeDatabase -gt 0) {
        Write-Host "Parameters `$Database and $ExcludeDatabase are not compatible. Kindly one one of them at a time.";
        return;
    }

    # Final Query to execute against Destination
    [System.Collections.ArrayList]$fileHeaders = @();

    Write-Verbose "Creating Tsql query to find database backup history";

    # Query to find database backup history
    $query_databasesFromBackupHistory = @"
SET NOCOUNT ON;
DECLARE @dbName VARCHAR(125),
		@backupStartDate datetime,
		@stopAtTime datetime;
DECLARE @DiffLSN [numeric](25, 0);
DECLARE @SQLString_Full nvarchar(2000);  
DECLARE @SQLString_Diff nvarchar(2000);  
DECLARE @SQLString_Log nvarchar(2000);  
DECLARE @ParmDefinition nvarchar(500); 

IF OBJECT_ID('tempdb..#BackupHistory') IS NOT NULL
	DROP TABLE #BackupHistory;
CREATE TABLE #BackupHistory
(
	[BackupFile] [nvarchar](260) NULL,
	[BackupTypeDescription] [varchar](21) NULL,
	[ServerName] [char](100) NULL,
	[UserName] [nvarchar](128) NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[DatabaseCreationDate] [datetime] NULL,
	[BackupSize] [numeric](20, 0) NULL,
	[FirstLSN] [numeric](25, 0) NULL,
	[LastLSN] [numeric](25, 0) NULL,
	[CheckpointLSN] [numeric](25, 0) NULL,
	[DatabaseBackupLSN] [numeric](25, 0) NULL,
	[BackupStartDate] [datetime] NULL,
	[BackupFinishDate] [datetime] NULL,
	[CompatibilityLevel] [tinyint] NULL,
	[Collation] [nvarchar](128) NULL,
	[IsCopyOnly] [bit] NULL,
	[RecoveryModel] [nvarchar](60) NULL
) ;

/* Build the SQL string to get latest full backup for database. */  
SET @SQLString_Full =  
     N'SELECT	BackupFile = bmf.physical_device_name,
			CASE bs.type WHEN ''D'' THEN ''Database'' WHEN ''I'' THEN ''Differential database'' WHEN ''L'' THEN ''Log'' ELSE NULL END as BackupTypeDescription,
			LTRIM(RTRIM(CAST(SERVERPROPERTY(''ServerName'') AS VARCHAR(125)))) as ServerName,
			UserName = bs.user_name,
			bs.database_name,
			DatabaseCreationDate = bs.database_creation_date,
			BackupSize = COALESCE(bs.compressed_backup_size,bs.backup_size),
			FirstLSN = bs.first_lsn, 
			LastLSN = bs.last_lsn, 
			CheckpointLSN = bs.checkpoint_lsn,
			DatabaseBackupLSN = bs.database_backup_lsn,
			BackupStartDate = bs.backup_start_date,
			BackupFinishDate = bs.backup_finish_date,
			CompatibilityLevel = bs.compatibility_level,
			Collation = bs.collation_name,
			IsCopyOnly = bs.is_copy_only,
			RecoveryModel = bs.recovery_model
	FROM	msdb.dbo.backupmediafamily AS bmf
	INNER JOIN msdb.dbo.backupset AS bs ON bmf.media_set_id = bs.media_set_id
	WHERE	bs.type = ''D'' AND	 is_copy_only = 0 AND database_name = @q_dbName
	AND		bs.backup_start_date >= @q_backupStartDate';

"@;

    if($BackupType -in ('Diff','Log')) {
        $query_databasesFromBackupHistory += @"

/* Build the SQL string to get latest Differential backup for database. */  
SET @SQLString_Diff =  
     N'SELECT	BackupFile = bmf.physical_device_name,
			CASE bs.type WHEN ''D'' THEN ''Database'' WHEN ''I'' THEN ''Differential database'' WHEN ''L'' THEN ''Log'' ELSE NULL END as BackupTypeDescription,
			LTRIM(RTRIM(CAST(SERVERPROPERTY(''ServerName'') AS VARCHAR(125)))) as ServerName,
			UserName = bs.user_name,
			bs.database_name,
			DatabaseCreationDate = bs.database_creation_date,
			BackupSize = COALESCE(bs.compressed_backup_size,bs.backup_size),
			FirstLSN = bs.first_lsn, 
			LastLSN = bs.last_lsn, 
			CheckpointLSN = bs.checkpoint_lsn,
			DatabaseBackupLSN = bs.database_backup_lsn,
			BackupStartDate = bs.backup_start_date,
			BackupFinishDate = bs.backup_finish_date,
			CompatibilityLevel = bs.compatibility_level,
			Collation = bs.collation_name,
			IsCopyOnly = bs.is_copy_only,
			RecoveryModel = bs.recovery_model
	FROM	msdb.dbo.backupmediafamily AS bmf
	INNER JOIN msdb.dbo.backupset AS bs ON bmf.media_set_id = bs.media_set_id
	WHERE	bs.type = ''I'' AND	 is_copy_only = 0 AND database_name = @q_dbName
	AND		bs.backup_start_date >= (SELECT MAX(bs.backup_start_date) AS Latest_DiffBackupDate
									FROM msdb.dbo.backupmediafamily AS bmf INNER JOIN msdb.dbo.backupset AS bs
									ON bmf.media_set_id = bs.media_set_id 
									WHERE bs.type=''I'' and is_copy_only = 0
									AND database_name = @q_dbName
									AND		bs.backup_start_date >= @q_backupStartDate
									)';

"@;
    }

    if($BackupType -eq 'Log') {
        $query_databasesFromBackupHistory += @"

/* Build the SQL string to get all latest Log backups after differential */  
SET @SQLString_Log =  
     N'SELECT	BackupFile = bmf.physical_device_name,
			CASE bs.type WHEN ''D'' THEN ''Database'' WHEN ''I'' THEN ''Differential database'' WHEN ''L'' THEN ''Log'' ELSE NULL END as BackupTypeDescription,
			LTRIM(RTRIM(CAST(SERVERPROPERTY(''ServerName'') AS VARCHAR(125)))) as ServerName,
			UserName = bs.user_name,
			bs.database_name,
			DatabaseCreationDate = bs.database_creation_date,
			BackupSize = COALESCE(bs.compressed_backup_size,bs.backup_size),
			FirstLSN = bs.first_lsn, 
			LastLSN = bs.last_lsn, 
			CheckpointLSN = bs.checkpoint_lsn,
			DatabaseBackupLSN = bs.database_backup_lsn,
			BackupStartDate = bs.backup_start_date,
			BackupFinishDate = bs.backup_finish_date,
			CompatibilityLevel = bs.compatibility_level,
			Collation = bs.collation_name,
			IsCopyOnly = bs.is_copy_only,
			RecoveryModel = bs.recovery_model
	FROM	msdb.dbo.backupmediafamily AS bmf
	INNER JOIN msdb.dbo.backupset AS bs ON bmf.media_set_id = bs.media_set_id
	WHERE	bs.type = ''L'' AND	 is_copy_only = 0 AND database_name = @q_dbName
	AND		bs.backup_start_date >= @q_backupStartDate
	AND		(	@q_DiffLSN < bs.first_lsn
				OR
				(@q_DiffLSN >= bs.first_lsn and @q_DiffLSN <=  bs.last_lsn)
			)';

"@;
    }

    $query_databasesFromBackupHistory += @"
  
DECLARE databases_cursor CURSOR LOCAL FORWARD_ONLY FOR 
		--	Find latest Full backup for each database
		SELECT MAX(bs.backup_start_date) AS Latest_FullBackupDate, database_name
		FROM msdb.dbo.backupmediafamily AS bmf INNER JOIN msdb.dbo.backupset AS bs 
		ON bmf.media_set_id = bs.media_set_id WHERE bs.type='D' and is_copy_only = 0
        $( if([String]::IsNullOrEmpty($StopAt_String) -eq $false){ "AND bs.backup_start_date <= '$StopAtTime'"} )
        $( if($ExcludeDatabase.Count -gt 0){ "AND database_name NOT IN ($ExcludeDatabaseCommaList)" } )
        $( if($Database.Count -gt 0){ "AND database_name IN ($DatabaseCommaList)" } )
		GROUP BY database_name;

OPEN databases_cursor
FETCH NEXT FROM databases_cursor INTO @backupStartDate, @dbName;

WHILE @@FETCH_STATUS = 0 
BEGIN
    SET @DiffLSN = NULL;
	BEGIN TRY
		SET @ParmDefinition = N'@q_dbName varchar(125), @q_backupStartDate datetime2';
		--	Find latest full
		INSERT #BackupHistory
		EXECUTE sp_executesql @SQLString_Full, @ParmDefinition,  
							  @q_dbName = @dbName,
							  @q_backupStartDate = @backupStartDate; 
    
"@;

    if($BackupType -in ('Diff','Log')) {
        $query_databasesFromBackupHistory += @"

		--	Find latest differential
		INSERT #BackupHistory
		EXECUTE sp_executesql @SQLString_Diff, @ParmDefinition,  
							  @q_dbName = @dbName,
							  @q_backupStartDate = @backupStartDate; 

"@;
    }

    if($BackupType -eq 'Log') {
        $query_databasesFromBackupHistory += @"

		SELECT @DiffLSN = LastLSN FROM #BackupHistory WHERE DatabaseName = @dbName AND BackupTypeDescription = 'Differential database';		
		IF @DiffLSN IS NULL
			SELECT @DiffLSN = LastLSN FROM #BackupHistory WHERE DatabaseName = @dbName AND BackupTypeDescription = 'Database';

		SET @ParmDefinition = N'@q_dbName varchar(125), @q_backupStartDate datetime2, @q_DiffLSN [numeric](25, 0)';
		--	Find latest log
		INSERT #BackupHistory
		EXECUTE sp_executesql @SQLString_Log, @ParmDefinition,  
							  @q_dbName = @dbName,
							  @q_backupStartDate = @backupStartDate,
							  @q_DiffLSN = @DiffLSN ; 

"@;
    }

    $query_databasesFromBackupHistory += @"

	END TRY
	BEGIN CATCH
		PRINT ' -- ---------------------------------------------------------';
		PRINT ERROR_MESSAGE();
		PRINT ' -- ---------------------------------------------------------';
	END CATCH
		
	FETCH NEXT FROM databases_cursor INTO @backupStartDate, @dbName;
END

CLOSE databases_cursor;
DEALLOCATE databases_cursor ;

SELECT * FROM #BackupHistory
ORDER BY DatabaseName, BackupTypeDescription, BackupStartDate;
"@;

    $srvObj = Connect-DbaInstance -SqlInstance $SqlInstance;
    
    Write-Verbose "Querying [$SqlInstance] for backup history";
    $tBackupHistory = Invoke-DbaQuery -SqlInstance $srvObj -Query $query_databasesFromBackupHistory;
    #$nodes = @(Invoke-DbaQuery -SqlInstance $srvObj -Query 'SELECT NodeName FROM sys.dm_os_cluster_nodes;' | Select-Object -ExpandProperty NodeName);
        
    $ServerName = $SqlInstance.Split('\')[0];
    $ssn = New-PSSession -ComputerName $ServerName -Name $ServerName;

    Write-Verbose "Looping through backup file from BackupHistory to find existence";
    foreach ($backup in $tBackupHistory) { 
           
        $bkpFile = $backup.BackupFile;
        $BackupFile_NetworkPath = "\\$ServerName\"+($bkpFile.Replace(':','$'));

        $FilePresentOnDisk = Invoke-Command -Session $ssn -ScriptBlock {[System.IO.File]::Exists($Using:bkpFile)}
        $BackupSizeBytes = $backup.BackupSize;
        $BackupSize = [PSCustomObject]@{
                            Bytes = $BackupSizeBytes;
                            KiloBytes = [math]::round($BackupSizeBytes / 1Kb,2);
                            MegaByte = [math]::round($BackupSizeBytes / 1Mb,2);
                            GigaByte = [math]::round($BackupSizeBytes / 1Gb,2);
                            TeraByte = [math]::round($BackupSizeBytes / 1Tb,2);
                        }
        
        $MethodBlock = {    if($this.TeraByte -ge 1) {
                                "$($this.TeraByte) tb"
                            }elseif ($this.GigaByte -ge 1) {
                                "$($this.GigaByte) gb"
                            }elseif ($this.MegaByte -ge 1) {
                                "$($this.MegaByte) mb"
                            }elseif ($this.KiloBytes -ge 1) {
                                "$($this.KiloBytes) kb"
                            }else {
                                "$($this.Bytes) bytes"
                            }
                        }
        $BackupSize | Add-Member -MemberType ScriptMethod -Name tostring -Value $MethodBlock -Force;

        $headerInfo = [PSCustomObject]@{
                                ServerName = $(($backup.ServerName).Trim());
                                DatabaseName = $backup.DatabaseName;                                                            
                                BackupTypeDescription = $backup.BackupTypeDescription;                                
                                BackupSize = $BackupSize;
                                BackupFile = $bkpFile;
                                BackupStartDate = $backup.BackupStartDate;
                                BackupFinishDate = $backup.BackupFinishDate;
                                RecoveryModel = $backup.RecoveryModel;
                                FilePresentOnDisk = $FilePresentOnDisk;
                                BackupFile_NetworkPath = $BackupFile_NetworkPath;  
                                FirstLSN = $backup.FirstLSN;
                                LastLSN = $backup.LastLSN;
                                CheckpointLSN = $backup.CheckpointLSN;
                                DatabaseBackupLSN = $backup.DatabaseBackupLSN;
                                CompatibilityLevel = $backup.CompatibilityLevel;
                                Collation = $backup.Collation;
                    }
        $fileHeaders.Add($headerInfo) | Out-Null;
    } # Loop through $tBackupHistory

    $ssn | Remove-PSSession;
    Write-Output $fileHeaders
}