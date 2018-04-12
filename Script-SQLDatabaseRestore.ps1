Function Script-SQLDatabaseRestore
{
    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory=$true,
                    ParameterSetName="BackupsFromPath")]
        [Parameter( Mandatory=$true,
                    ParameterSetName="RestoreAs_BackupFromPath" )]
        [Alias('PathOfBackups')]
        [String]$BackupPath,

        [Parameter( Mandatory=$true,
                    ParameterSetName="FromBackupHistory")]
        [Parameter( Mandatory=$true,
                    ParameterSetName="RestoreAs_BackupFromHistory" )]
        [Alias('SQLInstance_Source')]
        [String]$Source_SQLInstance,

        [Parameter( Mandatory=$true )]
        [ValidateSet("LatestAvailable", "LastestFullOnly", "LatestFullAndDiffOnly","PointInTime")]
        [String]$RestoreCategory = "LatestAvailable",

        [Parameter( Mandatory=$true )]
        [Alias('Target_SQLInstance','SQLInstance_Destination')]
        [String]$Destination_SQLInstance,
        
        [Parameter( Mandatory=$false,
                    ParameterSetName="RestoreAs_BackupFromPath" )]
        [Parameter( Mandatory=$false,
                    ParameterSetName="RestoreAs_BackupFromHistory" )]
        [Alias('DirectlyExecute')]
        [Switch]$ExecuteDirectly_DonotScriptout,

        [parameter( Mandatory=$false)]
        [Alias('Replace')]
        [Switch]$Overwrite,

        [parameter( Mandatory=$false)]
        [Switch]$NoRecovery,

        [Parameter( Mandatory=$true)]
        [Alias('Destination_Data_Path','Data_Path_Destination')]
        [String]$DestinationPath_Data,

        [Parameter( Mandatory=$true)]
        [Alias('Destination_Log_Path','Log_Path_Destination')]
        [String]$DestinationPath_Log,

        [Parameter( Mandatory=$false )]
        [Alias('SourceDatabasesToRestore')]
        [String[]]$SourceDatabase,

        [Parameter( Mandatory=$false,
                    ParameterSetName="BackupsFromPath")]
        [Parameter( Mandatory=$false,
                    ParameterSetName="FromBackupHistory")]
        [Switch]$Skip_Databases,

        [Parameter( Mandatory=$true,
                    ParameterSetName="RestoreAs_BackupFromPath" )]
        [Parameter( Mandatory=$true,
                    ParameterSetName="RestoreAs_BackupFromHistory" )]
        [Alias('DestinationDatabase_NewName')]
        [String]$RestoreAs
    )

    # Create File for storing result
    $ResultFile = "C:\temp\RestoreDatabaseScripts_$(Get-Date -Format ddMMMyyyyTHHmm).sql";

    # Add blackslash '\' at the end of path
    if ($DestinationPath_Data.EndsWith('\') -eq $false) {
        $DestinationPath_Data += '\';
    }
    if ($DestinationPath_Log.EndsWith('\') -eq $false) {
        $DestinationPath_Log += '\';
    }

    # Final Query to execute against Destination
    $fileHeaders = @();
   
    if (Test-Path -Path $BackupPath)
    {
        Write-Verbose "Finding all files from path:- $BackupPath";
        $files = @(Get-ChildItem -Path $BackupPath -File -Recurse | Select-Object -ExpandProperty FullName);
        #Write-Output $files;

        Write-Verbose "Looping through all the files found.";
        foreach ($bkpFile in $files)
        {
            Write-Verbose "   Reading Header of file '$bkpFile'";
            $header = (Invoke-Sqlcmd -ServerInstance $Destination_SQLInstance -Query "restore headeronly from disk = '$bkpFile'");

            $headerInfo = [Ordered]@{ 
                                    'BackupFile' = $bkpFile;
                                    'BackupTypeDescription' = $header.BackupTypeDescription;
                                    'ServerName' = $header.ServerName;
                                    'UserName' = $header.UserName;
                                    'DatabaseName' = $header.DatabaseName;
                                    'DatabaseCreationDate' = $header.DatabaseCreationDate;
                                    'BackupSize' = $header.BackupSize;
                                    'FirstLSN' = $header.FirstLSN;
                                    'LastLSN' = $header.LastLSN;
                                    'CheckpointLSN' = $header.CheckpointLSN;
                                    'DatabaseBackupLSN' = $header.DatabaseBackupLSN;
                                    'BackupStartDate' = $header.BackupStartDate;
                                    'BackupFinishDate' = $header.BackupFinishDate;
                                    'CompatibilityLevel' = $header.CompatibilityLevel;
                                    'Collation' = $header.Collation;
                                    'IsCopyOnly' = $header.IsCopyOnly;
                                    'RecoveryModel' = $header.RecoveryModel;
                                   }
            $obj = New-Object -TypeName psobject -Property $headerInfo;
            $fileHeaders += $obj;
        }
    }
    else
    {
        Write-Error "Invalid Backup Path '$BackupPath' provided";
    }

    Write-Verbose "Checking if specific source databases are provided";
    if ($SourceDatabase -ne $null)
    {
        Write-Verbose "Checking if databases are to be Skipped.";
        if ($Skip_Databases) 
        {
            Write-Verbose "Skip_Databases is set to TRUE";
            Write-Verbose "Removing databases based on parameter value `$SourceDatabase";
            $fileHeaders = ($fileHeaders | Where-Object {$SourceDatabase -notcontains $_.DatabaseName} | Sort-Object -Property DatabaseName, BackupStartDate);
        }
        else
        {
            Write-Verbose "Filtering databases based on parameter value `$SourceDatabase";
            $fileHeaders = ($fileHeaders | Where-Object {$SourceDatabase -contains $_.DatabaseName} | Sort-Object -Property DatabaseName, BackupStartDate);
        }
    }
    
    Write-Verbose "Perform action based on value of `$RestoreCategory parameter";
    if ($RestoreCategory -eq 'LatestAvailable')
    {
        Write-Verbose "Filtering backups based on `$RestoreCategory = '$RestoreCategory'";
    }

    #Write-Output $fileHeaders;

    $latestBackups = @();
    $latestBackups_Full = @();
    $latestBackups_Diff = @();
    $latestBackups_TLog = @();

    $databases = @($fileHeaders | Select-Object DatabaseName -Unique | Select-Object -ExpandProperty DatabaseName);
    foreach ( $dbName in $databases )
    {
        $lastestFullBackupDate = $null; # reset variable value
        $lastestDiffBackupDate = $null; # reset variable value
        $fullBackupHeader = $null; # reset variable value

        # Get Full Backup details
        $lastestFullBackupDate = ($fileHeaders | Where-Object {$dbName -contains $_.DatabaseName -and $_.BackupTypeDescription -eq 'Database'} | Measure-Object -Property BackupStartDate -Maximum).Maximum;
        $fullBackupHeader = ($fileHeaders | Where-Object {$dbName -contains $_.DatabaseName -and $_.BackupTypeDescription -eq 'Database' -and $_.BackupStartDate -eq $lastestFullBackupDate});
        $latestBackups_Full += $fullBackupHeader;

        #Write-Verbose "Latest full backup for database [$dbName] is of '$($lastestFullBackupDate.ToString())'";

        if ($fullBackupHeader.IsCopyOnly -eq 1)
        {
            Write-Verbose "Latest Full Backup of database [$dbName] is COPY_ONLY";
        }
        else
        {
            # Get Diff Backup details on top of Full Backup
            if ($lastestFullBackupDate -ne $null) 
            {
                $lastestDiffBackupDate = ($fileHeaders | Where-Object {$dbName -contains $_.DatabaseName -and $_.BackupTypeDescription -eq 'DATABASE DIFFERENTIAL' -and $_.BackupStartDate -ge $lastestFullBackupDate} | Measure-Object -Property BackupStartDate -Maximum).Maximum;
                $latestBackups_Diff += ($fileHeaders | Where-Object {$dbName -contains $_.DatabaseName -and $_.BackupTypeDescription -eq 'DATABASE DIFFERENTIAL' -and $_.BackupStartDate -eq $lastestDiffBackupDate});
            }

            if ($fullBackupHeader.RecoveryModel -ne 'SIMPLE')
            {
                if ($lastestDiffBackupDate -eq $null) 
                {
                    $lastestDiffBackupDate = $lastestFullBackupDate;
                }

                # Get TLog Backup details on top of Differential Backup
                if ($lastestDiffBackupDate -ne $null) 
                {
                    $latestBackups_TLog += ($fileHeaders | Where-Object {$dbName -contains $_.DatabaseName -and $_.BackupTypeDescription -eq 'TRANSACTION LOG' -and $_.BackupStartDate -ge $lastestDiffBackupDate});
                }
            }
        }        
    }

    $latestBackups += $latestBackups_Full;
    $latestBackups += $latestBackups_Diff;
    $latestBackups += $latestBackups_TLog;
    
    #$filelistFromBackupFiles = @();
    [int]$fileCounter_Total = 1;
    [int]$fileCounter_Database = 1;
    Write-Verbose "Looping through all the databases one by one to generate RESTORE statement.";
    foreach ( $dbName in $databases )
    {
        $fileCounter_Database = 1;
        Write-Verbose "   Generating RESTORE statement for database [$dbName]";
        $backupFilesForDatabase = $latestBackups | Where-Object {$dbName -contains $_.DatabaseName} | Sort-Object BackupStartDate;
        $bkpCountsForDB = @($backupFilesForDatabase).Count;
        Write-Verbose "   `$bkpCountsForDB for [$dbName] database is $bkpCountsForDB";

        $tsql4Database = $null;
        $tsql4Database = @"


PRINT '$fileCounter_Total) Restoring database [$dbName]'

"@;
        foreach ($file in $backupFilesForDatabase)
        {
            $tsql4Database += @"
    PRINT '   File no: $fileCounter_Database'
RESTORE DATABASE [$dbName] FROM DISK ='$($file.BackupFile)'
    WITH 
"@;
            Write-Verbose "      Reading filelist for file '$($file.BackupFile)'";
            $query = "restore filelistonly from disk = '$($file.BackupFile)'";
            $list = Invoke-Sqlcmd -ServerInstance $Destination_SQLInstance -Query $query;
            $list = ($list | Sort-Object FileId);

            # If differtial or TLog, with MOVE option is not required
            if($fileCounter_Database -eq 1)
            {
                foreach ($f in $list)
                {
                    $physicalName = $f.PhysicalName; #F:\Mssqldata\Data\UserTracking_data.mdf
                    $r = $physicalName -match "^(?'PathPhysicalName'.*[\\\/])(?'BasePhysicalNameWithExtension'(?'BasePhysicalNameWithoutExtension'.+)(?'Extension'\.[a-zA-Z]+$))";

                    $BasePhysicalNameWithExtension = $Matches['BasePhysicalNameWithExtension']; #UserTracking_data.mdf
                    $Extension = $Matches['Extension']; #.mdf
                    $PathPhysicalName = $Matches['PathPhysicalName']; #F:\Mssqldata\Data\
                    $BasePhysicalNameWithoutExtension = $Matches['BasePhysicalNameWithoutExtension']; #UserTracking_data
                
                    if ($f.Type -eq 'D') 
                    {
                        $PhysicalPath_New = $DestinationPath_Data + $BasePhysicalNameWithExtension;
                    }
                    else 
                    {
                        $PhysicalPath_New = $DestinationPath_Log + $BasePhysicalNameWithExtension;
                    }

                    $tsql4Database += @"

                MOVE '$($f.LogicalName)' TO '$PhysicalPath_New',
"@;
                
                }
            }
            
            #if its last backup file to apply
            if ($bkpCountsForDB -eq $fileCounter_Database)
            {
                $tsql4Database += @"

            STATS = 3
GO
"@;
            }
            else 
            {
                $tsql4Database += @"

            NORECOVERY, STATS = 3
GO
"@;
            }

                $fileCounter_Database += 1;
                $tsql4Database | Out-File -Append $ResultFile;
        }

            $fileCounter_Total += 1;
    }

    Write-Verbose "Opening SSMS with generated script.";
    if ($Destination_SQLInstance -eq $null)
    {
        $Destination_SQLInstance = $InventoryInstance;
    }
    ssms.exe $ResultFile -S $Destination_SQLInstance -E;
}
