Function Script-SQLDatabaseRestore
{
<#
.SYNOPSIS
    Script out TSQL RESTORE code for backups during Database Restore Activity
.DESCRIPTION
    This function accepts backup path, data and log directory for restore operation on destination sql instance, and create RESTORE script for database restore/migration activity.
    It can be used for performing database restore operation with latest available backups on BackupPath.
    Can be used to restore database for Point In Time.
    Can be used for restoring database with new name on Destination SQL Instance.
.PARAMETER BackupPath
    The directory or path where database backups are kept. It can find backup files even under child folders. Say, we provide BackupPth  = 'E:\Backups', and backups for [Test] database are under 'E:\Backups\Test' folder. So the function can consider even child items as well.
.PARAMETER RestoreCategory
    Based on selected RestoreCategory, this function can generated TSQL Restore code for either for latest application Full, Diff & TLog, or only for either Full or Diff. This function only provides functionality of Point In Time database restore.
.PARAMETER StopAtTime
    Provide this parameter value when RestoreCategory of 'PointInTime' is selected. The parameter value accepts datetime value in format 'yyyy-MM-dd hh:mm:ss'.
.PARAMETER Destination_SQLInstance
    Instance name of target sql server instance. For example SQL-A\sql2012 instance
.PARAMETER ExecuteDirectly_DonotScriptout
    With this switch, the created TSQL Restore code is directly executed against Destination_SQLInstance.
.PARAMETER Overwrite
    With this switch, the TSQL RESTORE code generated will be generated with REPLACE option.
.PARAMETER NoRecovery
    With this switch, the TSQL RESTORE code generated will be generated with NORECOVERY option.
.PARAMETER DestinationPath_Data
    Parameter to accept Data files path or directory on target/destination SQL Server Instance.
.PARAMETER DestinationPath_Log
    Parameter to accept Log files path or directory on target/destination SQL Server Instance.
.PARAMETER SourceDatabase
    Accepts multiple database names separated by comma (,). Should not be used when RESTORE script is to be generated for all databases.
    When database names specified here, then RESTORE tsql code is generated only for those database.
    When used with '-Skip_Databases' switch, then the RESTORE script is NOT generated for databases mentioned.
    Accepts single database name when used with parameter '-RestoreAs'.
.PARAMETER RestoreAs
    Accepts new name for single database when '-SourceDatabase' it has to be restored as new New on Destination SQL Instance.
.EXAMPLE
    C:\PS> Script-SQLDatabaseRestore -BackupPath \\SQLBackups\ProdSrv01 -Destination_SQLInstance ProdSrv02 -DestinationPath_Data F:\mssqldata\Data -DestinationPath_Log E:\Mssqldata\Log -RestoreCategory LatestAvailable
    Generates RESTORE tsql code for all database with latest Full/Diff/TLog backups from path '\\SQLBackups\ProdSrv01'.
.EXAMPLE
    C:\PS> Script-SQLDatabaseRestore -BackupPath \\SQLBackups\ProdSrv01 -Destination_SQLInstance ProdSrv02 -DestinationPath_Data F:\mssqldata\Data -DestinationPath_Log E:\Mssqldata\Log -RestoreCategory LatestAvailable -SourceDatabase Cosmo,DBA
    Generates RESTORE tsql code for [Cosmo] and [DBA] databases with latest Full/Diff/TLog backup from path '\\SQLBackups\ProdSrv01'.
.EXAMPLE
    C:\PS> Script-SQLDatabaseRestore -BackupPath \\SQLBackups\ProdSrv01 -Destination_SQLInstance ProdSrv02 -DestinationPath_Data F:\mssqldata\Data -DestinationPath_Log E:\Mssqldata\Log -RestoreCategory LatestAvailable -Skip_Databases -SourceDatabase Cosmo, DBA
    Generates RESTORE tsql code for all database except [Cosmo] and [DBA] with latest Full/Diff/TLog backups from path '\\SQLBackups\ProdSrv01'.
.EXAMPLE
    C:\PS> Script-SQLDatabaseRestore -BackupPath \\SQLBackups\ProdSrv01 -Destination_SQLInstance ProdSrv02 -DestinationPath_Data F:\mssqldata\Data -DestinationPath_Log E:\Mssqldata\Log -RestoreAs Cosmo_Temp -RestoreCategory LatestAvailable -SourceDatabase Cosmo
    Generates RESTORE tsql code for [Cosmo] database to be restored as [Cosmo_Temp] on destination with latest Full/Diff/TLog backup from path '\\SQLBackups\ProdSrv01'.
.EXAMPLE
    C:\PS> Script-SQLDatabaseRestore -BackupPath \\SQLBackups\ProdSrv01 -Destination_SQLInstance ProdSrv02 -DestinationPath_Data F:\mssqldata\Data -DestinationPath_Log E:\Mssqldata\Log -RestoreCategory LatestAvailable -SourceDatabase Cosmo, DBA -StopAtTime "2018-04-12 23:15:00"
   Generates RESTORE tsql code for [Cosmo] and [DBA] databases upto time '2018-04-12 23:15:00' using Full/Diff/TLog backups from path '\\SQLBackups\ProdSrv01'.
.LINK
    https://github.com/imajaydwivedi/SQLDBATools
.NOTES
    Author: Ajay Dwivedi
    EMail:  ajay.dwivedi2007@gmail.com
    Date:   June 28, 2010 
    Documentation: https://github.com/imajaydwivedi/SQLDBATools   
#>
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
        [ValidateSet("LatestAvailable", "LatestFullOnly", "LatestFullAndDiffOnly","PointInTime")]
        [String]$RestoreCategory = "LatestAvailable",

        [Parameter( Mandatory=$false, HelpMessage="Enter DateTime in 24 hours format (yyyy-MM-dd hh:mm:ss)")]
        [String]$StopAtTime = $null,

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

        [Parameter( Mandatory=$false,
                    ParameterSetName="BackupsFromPath")]
        [Parameter( Mandatory=$true,
                    ParameterSetName="RestoreAs_BackupFromPath" )]
        [Parameter( Mandatory=$false,
                    ParameterSetName="FromBackupHistory")]
        [Parameter( Mandatory=$true,
                    ParameterSetName="RestoreAs_BackupFromHistory" )]
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
    if ([string]::IsNullOrEmpty($StopAtTime) -eq $false) 
    {
        # StopAt in String format
        try 
        {   
            Write-Verbose "`$StopAtTime = '$StopAtTime'";

            $format = "yyyy-MM-dd HH:mm:ss";
            Write-Verbose "`$format = '$format'";

            $StopAt_Time = [DateTime]::ParseExact($StopAtTime, $format, $null);
            Write-Verbose "`$StopAt_Time = '$StopAt_Time'";

            $StopAt_String = ($StopAt_Time).ToString('MMM dd, yyyy hh:mm:ss tt');
            Write-Verbose "`$StopAt_String = '$StopAt_String'";
        }
        catch 
        {
            Write-Error "Invalid datetime format specified for `$StopAt_Time parameter. Kindly use format:  (yyyy-MM-dd hh:mm:ss)";
            return;
        }
    }
    
    if ([string]::IsNullOrEmpty($StopAtTime) -eq $false -and $RestoreCategory -ne 'PointInTime')
    {
        Write-Error "Value for `$StopAtTime parameter is not required since `$RestoreCategory is not equal to 'PointInTime'";
        return;
    }
    
    if ($RestoreCategory -eq 'PointInTime' -and [string]::IsNullOrEmpty($StopAtTime) -eq $true)
    {
        Write-Error "Value for `$StopAtTime parameter is Mandatory for `$RestoreCategory = 'PointInTime'";
        return;
    }
    
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
        return;
    }

    Write-Verbose "Checking if specific source databases are provided";
    if ([String]::IsNullOrEmpty($SourceDatabase) -eq $false)
    {
        # if 'RestoreAs_BackupFromPath' or 'RestoreAs_BackupFromHistory' options are selected
        if( [String]::IsNullOrEmpty($RestoreAs) -eq $false -and $SourceDatabase.Count -ne 1)
        {
            Write-Error "Kindly provide only single database name for parameter `$SourceDatabase";
            return;
        }

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
        # No action to be taken for RestoreCategory = "LatestAvailable"
        Write-Verbose "Filtering backups based on `$RestoreCategory = '$RestoreCategory'";
    }
    elseif ($RestoreCategory -eq 'LatestFullOnly')
    {
        Write-Verbose "Filtering backups based on `$RestoreCategory = '$RestoreCategory'";
        $fileHeaders = ($fileHeaders | Where-Object {$_.BackupTypeDescription -eq 'Database'} | Sort-Object -Property DatabaseName, BackupStartDate -Descending);
    }
    elseif ($RestoreCategory -eq 'LatestFullAndDiffOnly') #"LatestFullOnly", "LatestFullAndDiffOnly","PointInTime"
    {
        Write-Verbose "Filtering backups based on `$RestoreCategory = '$RestoreCategory'";
        $fileHeaders = ($fileHeaders | Where-Object {$_.BackupTypeDescription -eq 'Database' -or $_.BackupTypeDescription -eq 'DATABASE DIFFERENTIAL'} | Sort-Object -Property DatabaseName, BackupStartDate);
    }
    elseif ($RestoreCategory -eq 'PointInTime')
    {
        $databases = @($fileHeaders | Select-Object DatabaseName -Unique | Select-Object -ExpandProperty DatabaseName);

        Write-Verbose "Filtering backups based on `$RestoreCategory = '$RestoreCategory'";
        $pit_Backups_FullorDiff = @();
        $pit_Backups_TLog = @();
       
        # get full and diff backups upto @StopAtTime
        $pit_Backups_FullorDiff = ($fileHeaders | Where-Object {'DATABASE','DATABASE DIFFERENTIAL' -contains $_.BackupTypeDescription -and $_.BackupStartDate -le $StopAt_Time} | Sort-Object -Property DatabaseName, BackupStartDate);

        # get tlog backups to recover for @StopAtTime
        foreach ( $dbName in $databases )
        {
            $pit_LastTLogStartDate = $null;
            $pit_LastTLogStartDate = ($fileHeaders | Where-Object {$dbName -eq $_.DatabaseName -and $_.BackupTypeDescription -eq 'TRANSACTION LOG' -and $_.BackupStartDate -ge $StopAt_Time} | Measure-Object -Property BackupStartDate -Minimum).Minimum;
            $pit_Backups_TLog += ($fileHeaders | Where-Object {$dbName -eq $_.DatabaseName -and $_.BackupTypeDescription -eq 'TRANSACTION LOG' -and $_.BackupStartDate -le $pit_LastTLogStartDate} | Sort-Object -Property DatabaseName, BackupStartDate);
        }

        $fileHeaders = $pit_Backups_FullorDiff;
        $fileHeaders += $pit_Backups_TLog;
        $fileHeaders = $fileHeaders | Sort-Object DatabaseName, BackupStartDate;
    }

    #Write-Output $fileHeaders;

    $latestBackups = @();
    $latestBackups_Full = @();
    $latestBackups_Diff = @();
    $latestBackups_TLog = @();

    # reset names of $databases
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
        if([String]::IsNullOrEmpty($RestoreAs) -eq $false) {
            $dbName_New = $RestoreAs;
        }else {
            $dbName_New = $dbName;
        };
        Write-Verbose "   Generating RESTORE statement for database [$dbName]";

        $backupFilesForDatabase = $latestBackups | Where-Object {$dbName -contains $_.DatabaseName} | Sort-Object BackupStartDate;
        $bkpCountsForDB = @($backupFilesForDatabase).Count;
        Write-Verbose "   `$bkpCountsForDB for [$dbName] database is $bkpCountsForDB";

        $tsql4Database = $null;
        $tsql4Database = @"


PRINT '$fileCounter_Total) Restoring database [$dbName_New]'

"@;
        foreach ($file in $backupFilesForDatabase)
        {
            $tsql4Database += @"
    PRINT '   File no: $fileCounter_Database'
RESTORE DATABASE [$dbName_New] FROM DISK ='$($file.BackupFile)'
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

                    # When database has to be restored with New Name. Then change physicalName of files
                    if ([String]::IsNullOrEmpty($RestoreAs) -eq $false)
                    {
                        $BasePhysicalNameWithExtension_New = $BasePhysicalNameWithExtension.Replace("$dbName","$RestoreAs");
                        if($BasePhysicalNameWithExtension_New -eq $BasePhysicalNameWithExtension) {
                            $BasePhysicalNameWithExtension_New = $RestoreAs +'_'+ $BasePhysicalNameWithExtension_New;
                        }
                    }
                    else {
                        $BasePhysicalNameWithExtension_New = $BasePhysicalNameWithExtension;
                    }
                
                    if ($f.Type -eq 'D') 
                    {
                        $PhysicalPath_New = $DestinationPath_Data + $BasePhysicalNameWithExtension_New;
                    }
                    else 
                    {
                        $PhysicalPath_New = $DestinationPath_Log + $BasePhysicalNameWithExtension_New;
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

			$(if($Overwrite -and $fileCounter_Database -eq 1){'REPLACE, '})$(if($NoRecovery){'NORECOVERY, '})$(if($fileCounter_Database -ne 1 -and $RestoreCategory -eq 'PointInTime'){'STOPAT = '''+$StopAt_String+''', '})STATS = 3 
GO
"@;
            }
            else 
            {
                $tsql4Database += @"

			$(if($Overwrite -and $fileCounter_Database -eq 1){'REPLACE, '})NORECOVERY, STATS = 3
GO
"@;
            }

                $fileCounter_Database += 1;
                $tsql4Database | Out-File -Append $ResultFile;
        }

            $fileCounter_Total += 1;
    }

    Write-Host "Opening generated script file '$ResultFile' with SSMS.";
    if ($Destination_SQLInstance -eq $null)
    {
        $Destination_SQLInstance = $InventoryInstance;
    }
    #ssms.exe $ResultFile -S $Destination_SQLInstance -E;
    notepad.exe $ResultFile;
}
