function Get-DbaRestoreScript {
<#
.SYNOPSIS
This function return tsql RESTORE DATABASE/LOG code for performing restore operation
.DESCRIPTION
This function accepts source and target servers, and generates copy and database restore scripts
.PARAMETER SourceSqlInstance
Name of source SqlInstance
.PARAMETER TargetSqlInstance
Name of destination server where backups are to be restored
.PARAMETER Database
Names of databases for scripting RESTORE code
.PARAMETER ExcludeDatabase
Names of databases that are to be skipped
.PARAMETER EstimateBackupSize
With this switch, result will have latest full and diff backup size along with duration from source
.PARAMETER EstimateRestoreSpaceRequirement
With this switch, result will have database data and log file space requirement
.PARAMETER OnlyCopyCommand
With this switch, result will generate only robocopy commands
.PARAMETER OnlyRestoreCommand
With this switch, the result will generate only RESTORE commands
.PARAMETER BackupCopySizeThreshold_GB
Size threshold of Backup files after which it should be called Large backup. Default is 25 GB.
.PARAMETER Type
Choose the depth of backup restore. Available options are Full, Diff and Log. Default is Log
.PARAMETER RecentOnly
With this switch, script will choose latest backup between history & copied target file.
.PARAMETER OverwriteExistingFileDirectories
With this switch, script will choose data/log file location on target according to MappingExcel ignoring the existing path on Target if db is already present.
.PARAMETER MappingExcel
Full path for Excel file having at least 3 sheets namely 'RestoreAs', 'TargetCopiedFileLocation' and 'DbDriveMapping'
.PARAMETER PointInTime
With this parameter, the RESTORE scripts generated will perform Point-In-Time recovery of databases
.PARAMETER Recover
With this switch, the Restore script generated would bring the databases online
.PARAMETER GenerateSampleMappingExcel
With this switch, the result will generate a sample 'MappingExcel' file
.EXAMPLE
Get-DbaRestoreScript -SourceSqlInstance testvm01 -TargetSqlInstance testvm02
This command generates robocopy and restore scripts for all user databases from testvm01 to testvm02
.EXAMPLE
Get-DbaRestoreScript -SourceSqlInstance testvm01 -TargetSqlInstance testvm02 -Database @('Staging','[Mosaic],RCM_rovicore_20130710_NoMusic1a_en-US','DBA, ADI, Amazon','Babel') -MappingExcel C:\Temp\MappingExcel.xlsx
This command reads sheets 'RestoreAs', 'TargetCopiedFileLocation' and 'DbDriveMapping' from MappingExcel, and generates copy & restore script for copying databases from testvm01 to testvm02
.EXAMPLE
Get-DbaRestoreScript -SourceSqlInstance testvm01 -EstimateRestoreSpaceRequirement
This command returns collection of databases with its common attributes and information of sizes for total/full/diff backups along with data & log file size.
.EXAMPLE
$Databases = @('Staging','[Mosaic],RCM_rovicore_20130710_NoMusic1a_en-US','DBA, ADI, Amazon','Babel');
Get-DbaRestoreScript -SourceSqlInstance testvm01 -Database $Databases -GenerateSampleMappingExcel -MappingExcel C:\Temp\MappingExcel.xlsx

This command generates MappingExcel.xlsx for databases with sheets 'RestoreAs', 'TargetCopiedFileLocation' and 'DbDriveMapping' on C:\Temp\. If the excel already exists, the sheets data would be overwritten.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
.LINK
https://www.mssqltips.com/sqlservertip/3209/understanding-sql-server-log-sequence-numbers-for-backups/
.LINK
https://youtu.be/v4r2lhIFii4
.NOTES
Author: Ajay Dwivedi
EMail:  ajay.dwivedi2007@gmail.com
Date:   Oct 25, 2019
Documentation: https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='None')]
    Param(
        [Parameter(Mandatory=$true,Position=0)][ValidateNotNullOrEmpty()]
        [String]$SourceSqlInstance,
        [String]$TargetSqlInstance,
        [String[]]$Database,
        [String[]]$ExcludeDatabase,
        [Switch]$EstimateBackupSize, #done
        [Switch]$EstimateRestoreSpaceRequirement, #done
        [Switch]$OnlyCopyCommand,
        [Int]$BackupCopySizeThreshold_GB = 25,
        [Switch]$ExecuteCopyCommand,
        [Switch]$OnlyRestoreCommand,
        [Switch]$ExecuteRestoreCommand,
        [ValidateSet("Full", "Diff", "Log")][Alias('RestoreType')]
        [String]$Type = 'Log',
        [Switch]$OverwriteExistingFileDirectories,
        [String]$MappingExcel,
        [Parameter(HelpMessage="Enter DateTime in 24 hours format (yyyy-MM-dd hh:mm:ss)")]
        [String]$PointInTime,
        [Switch]$Recover,
        [Switch]$GenerateSampleMappingExcel #done
    )
    BEGIN {
        Write-Verbose "Inside BEGIN block"
        $srcObj = Connect-DbaInstance -SqlInstance $SourceSqlInstance;
        if(-not [String]::IsNullOrEmpty($TargetSqlInstance)) {
            $tgtObj = Connect-DbaInstance -SqlInstance $TargetSqlInstance;
        }

        $SourceServerName = $SourceSqlInstance.Split('\')[0];
        $SourceServerNodeName = Invoke-Command -ComputerName $SourceServerName -ScriptBlock {$env:COMPUTERNAME};
        
        $TargetServerName = $TargetSqlInstance.Split('\')[0];
        if(-not [string]::IsNullOrEmpty($TargetServerName)) {
            $TargetServerNodeName = Invoke-Command -ComputerName $TargetServerName -ScriptBlock {$env:COMPUTERNAME};
        }

        Write-Verbose "Validate Parameter Sets";
        if($GenerateSampleMappingExcel -and ([String]::IsNullOrEmpty($PointInTime) -eq $false -or $RecentOnly -or $OnlyRestoreCommand -or $OnlyCopyCommand -or $EstimateRestoreSpaceRequirement -or $EstimateBackupSize) ) {
            Write-Error "Parameter 'GenerateSampleMappingExcel' is not valid with below parameters:-`n
PointInTime, RecentOnly, OnlyRestoreCommand, OnlyCopyCommand, EstimateRestoreSpaceRequirement, EstimateBackupSize";
            return;
        }        
    }
    PROCESS {
        Write-Verbose "Get-DbaRestoreScript called";        
        
        # Validate $StopAtTime
        if ([string]::IsNullOrEmpty($StopAtTime) -eq $false) {
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
        } # Validate $StopAtTime

        # Get Databases using TSQL
        if($true) {
            Write-Verbose "Inside block: Get Databases using TSQL";
            # Format $Database input
            if([String]::IsNullOrEmpty($Database) -eq $false) {
                #$Database = @('StackOverflow2010','DBA_Snapshot','Staging,Staging2,StagingFiltered','[Mosaic],[MosaicFiltered],RCM_rovicore_20130710_NoMusic1a_en-US')

                # Create array of databases removing single quotes, square brackets, other other wrong formats
                $DatabaseList = @();
                foreach($dbItem in $Database) {
                    $arrayItems = $dbItem.Split(',');
                    foreach($arrItem in $arrayItems) {
                        $arrItem = $arrItem.Replace("'",''); # remove single quotes
                        $arrItem = ($arrItem.Replace('[','')).Replace(']',''); # remove square brackets
                        $arrItem = $arrItem.Trim(); # remove Space
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
                        $arrItem = $arrItem.Trim(); # remove Space
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

            # TSQL - Get Database MetaData From Source SqlInstance
            $srcDatabases_tsql = @"
select d.name, d.compatibility_level, d.state_desc, d.recovery_model_desc
from sys.databases as d
where d.database_id > 4
$(if($Database.Count -gt 0){" and d.name in ($DatabaseCommaList)"})
$(if($ExcludeDatabase.Count -gt 0){"where d.name not in ($ExcludeDatabaseCommaList)"});
"@;
            Write-Verbose "Find Databases to Query";
            #$rSrcDatabases = @();
            $rSrcDatabases = Invoke-DbaQuery -SqlInstance $srcObj -Database 'master' -Query $srcDatabases_tsql -Verbose:$false;
            $rTgtDatabases = Invoke-DbaQuery -SqlInstance $tgtObj -Database 'master' -Query $srcDatabases_tsql -Verbose:$false;

            #Write-Debug "Before Throwing Error";
            $srcDatabasesNamesOnly = @($rSrcDatabases.name);            
            if( ($Database.Count -ne $srcDatabasesNamesOnly.Count) -and (-not [string]::IsNullOrEmpty($Database)) ) {
                $missingDatabases = (Compare-Object -ReferenceObject $Database -DifferenceObject ($rSrcDatabases | Select -ExpandProperty name)).InputObject;
            
                Write-Host "Below databases are not present on Source:`n$($missingDatabases -join "`n")`n" -ForegroundColor Red;
                return;
            }
        } # Get Databases using TSQL

        # Get-BackupHistory
        if($true) {
            #Write-Debug "Before Get-BackupHistory";
            Write-Verbose "Find backup history for databases using Get-BackupHistory";
            $BackupsAllDbs = Get-BackupHistory -SqlInstance $SourceSqlInstance -Database $($rSrcDatabases | Select -ExpandProperty name) -BackupType $(if($EstimateBackupSize){'Diff'}else{$Type}) -StopAtTime $PointInTime;
        } # Get-BackupHistory

        # $EstimateBackupSize
        if($EstimateBackupSize) {
            Write-Verbose "Estimate Backup Size";
            Write-Output $($BackupsAllDbs | Where-Object {$_.BackupTypeDescription -in @('Database','Differential database')});
            return;
        } # $EstimateBackupSize

        # Create Database Object
        if($true){
            Write-Verbose "Create database object with all properties"
            [System.Collections.ArrayList]$srcDatabaseObjects = @();
            
            $dbFilesTarget_tsql = @"
select db_name(mf.database_id) as DbName, mf.file_id, mf.type_desc, mf.name, mf.physical_name
from sys.master_files mf
where mf.database_id > 4
$(if($Database.Count -gt 0){" and DB_NAME(mf.database_id) in ($DatabaseCommaList)"})
$(if($ExcludeDatabase.Count -gt 0){"and DB_NAME(mf.database_id) not in ($ExcludeDatabaseCommaList)"});
"@;
            $rDbFiles_Tgt = Invoke-DbaQuery -SqlInstance $tgtObj -Database $rDb.name -Query $dbFilesTarget_tsql -ErrorAction SilentlyContinue;
            
            # TSQL - Get Database Files for Source SqlInstance
            $dbFiles_tsql = @"
select	df.type_desc, df.name, df.physical_name, df.state_desc, df.size, df.max_size, df.growth
from sys.database_files as df
"@;
                        
            # Loop through each Database
            foreach($rDb in $rSrcDatabases) {
                Write-Verbose "  process [$($rDb.name)] database.."

                # TSQL - Get database files
                $rDbFiles = Invoke-DbaQuery -SqlInstance $srcObj -Database $rDb.name -Query $dbFiles_tsql;

                # Filter Backup Files for database
                if(-not [String]::IsNullOrEmpty($BackupsAllDbs)) {
                    $rDbBackups = $BackupsAllDbs | Where-Object {$PSItem.DatabaseName -eq $rDb.name} | Sort-Object -Property BackupTypeDescription, BackupStartDate;
                    $MethodBlock = {
                        if($this.BackupTypeDescription -in @('Database','Differential database')) {
                            $this.BackupFile | Split-Path -Leaf;
                        }
                    }
                    $rDbBackups | Add-Member -MemberType ScriptMethod -Name tostring -Value $MethodBlock -Force;
                } # Filter Backup Files for database
                
                # Create Size object
                if($true){
                    $DataFilesSizePages = ($rDbFiles | Where-Object {$_.type_desc -eq 'ROWS'} | Measure-Object -Property size -Sum).Sum;
                    $DataFileSize = [PSCustomObject]@{
                                        Pages = $DataFilesSizePages;
                                        Bytes = [math]::Round($DataFilesSizePages * 8.0 * 1024,2);
                                        KiloByte = [math]::Round($DataFilesSizePages * 8.0,2);
                                        MegaByte = [math]::Round(($DataFilesSizePages * 8.0) / 1024,2);
                                        GigaByte = [math]::Round(($DataFilesSizePages * 8.0) / 1024 / 1024,2);
                                        TeraByte = [math]::Round(($DataFilesSizePages * 8.0) / 1024 / 1024 / 1024,2);
                                    }
            
                    $LogFilesSizePages = ($rDbFiles | Where-Object {$_.type_desc -eq 'LOG'} | Measure-Object -Property size -Sum).Sum;
                    $LogFileSize = [PSCustomObject]@{
                                        Pages = $LogFilesSizePages;
                                        Bytes = [math]::Round($LogFilesSizePages * 8.0 * 1024,2);
                                        KiloByte = [math]::Round($LogFilesSizePages * 8.0,2);
                                        MegaByte = [math]::Round(($LogFilesSizePages * 8.0) / 1024,2);
                                        GigaByte = [math]::Round(($LogFilesSizePages * 8.0) / 1024 / 1024,2);
                                        TeraByte = [math]::Round(($LogFilesSizePages * 8.0) / 1024 / 1024 / 1024,2);
                                    }

                    $SizePages = $DataFilesSizePages + $LogFilesSizePages;
                    $Size = [PSCustomObject]@{
                                    Pages = $SizePages;
                                    Bytes = [math]::Round($SizePages * 8.0 * 1024,2);
                                    KiloByte = [math]::Round($SizePages * 8.0,2);
                                    MegaByte = [math]::Round(($SizePages * 8.0) / 1024,2);
                                    GigaByte = [math]::Round(($SizePages * 8.0) / 1024 / 1024,2);
                                    TeraByte = [math]::Round(($SizePages * 8.0) / 1024 / 1024 / 1024,2);
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
                    $DataFileSize | Add-Member -MemberType ScriptMethod -Name tostring -Value $MethodBlock -Force;
                    $LogFileSize | Add-Member -MemberType ScriptMethod -Name tostring -Value $MethodBlock -Force;
                    $Size | Add-Member -MemberType ScriptMethod -Name tostring -Value $MethodBlock -Force;
                } # Create Size object

                # Create psobject
                $obj = [PSCustomObject]@{
                            DbName  = $rDb.name;
                            Size = $Size;
                            DataFileSize = $DataFileSize;
                            LogFileSize = $LogFileSize;
                            Files = $rDbFiles;
                            Compatibility_level = $rDb.compatibility_level;
                            State_Desc = $rDb.state_desc;
                            Recovery_Model_Desc = $rDb.recovery_model_desc;
                            Backups = $(if(-not [String]::IsNullOrEmpty($rDbBackups)) {$rDbBackups}else{"Not Applicable"});
                        } # Create psobject

                $srcDatabaseObjects.Add($obj) | Out-Null;
            } # Loop through each Database

            
            Write-Verbose "  Add FullBackupSize & DiffBackupSize properties to database object";
            $srcDatabaseObjects | ForEach-Object -Begin {} -Process {
                $FullBackupSize = ($_.Backups | Where-Object {$_.BackupTypeDescription -eq 'Database'}).BackupSize;
                $DiffBackupSize = ($_.Backups | Where-Object {$_.BackupTypeDescription -eq 'Differential database'}).BackupSize;
                $_ | Add-Member -NotePropertyName FullBackupSize -NotePropertyValue $FullBackupSize;
                $_ | Add-Member -NotePropertyName DiffBackupSize -NotePropertyValue $DiffBackupSize;
            } -End {};
            
            $srcDatabases = ($srcDatabaseObjects | Select-Object DbName, Size, DataFileSize, LogFileSize, FullBackupSize, DiffBackupSize, Compatibility_level, State_Desc, Recovery_Model_Desc, Files, Backups);
        } # Create Database Object

        # Logic for GenerateSampleMappingExcel
        if($GenerateSampleMappingExcel) {
            #Write-Debug "Inside GenerateSampleMappingExcel";

            if([String]::IsNullOrEmpty($MappingExcel)) {
                Write-Verbose "Generate Sample Mapping Excel";
                $MappingExcel = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), 'xlsx');
            }

            $Sheet_RestoreAs = @();
            $Sheet_RestoreAs_Prop01 = [Ordered]@{DbName = 'DummySRC';RestoreAs = 'DummyTGT'}
            $Sheet_RestoreAs_Obj01 = New-Object -TypeName psobject -Property $Sheet_RestoreAs_Prop01;
            $Sheet_RestoreAs_Prop02 = [Ordered]@{DbName = 'TestSRC';RestoreAs = 'TestTGT'}
            $Sheet_RestoreAs_Obj02 = New-Object -TypeName psobject -Property $Sheet_RestoreAs_Prop02;
            $Sheet_RestoreAs += $Sheet_RestoreAs_Obj01;
            $Sheet_RestoreAs += $Sheet_RestoreAs_Obj02;
            $Sheet_RestoreAs | Export-Excel -Path $MappingExcel -WorksheetName 'RestoreAs' -ClearSheet;

            # Initialize blank Arrays
            [System.Collections.ArrayList]$Sheet_TargetCopiedFileLocation = @();
            [System.Collections.ArrayList]$Sheet_DbDriveMapping = @();

            foreach($db in $srcDatabases) {
                if($db.FullBackupSize.GigaByte -gt $BackupCopySizeThreshold_GB) {
                    $Sheet_TargetCopiedFileLocation_Prop = [PSCustomObject]@{DbName = $db.DbName;BackupPath = 'G:\MSSQLData\DbRefreshActivity\'}
                    $Sheet_TargetCopiedFileLocation.Add($Sheet_TargetCopiedFileLocation_Prop) | Out-Null;
                }

                $Sheet_DbDriveMapping_Prop = [PSCustomObject]@{DbName = $db.DbName;DataDrive = 'S:\'; LogDrive = 'S:\'}
                $Sheet_DbDriveMapping.Add($Sheet_DbDriveMapping_Prop) | Out-Null;
            }

            $Sheet_TargetCopiedFileLocation | Export-Excel -Path $MappingExcel -WorksheetName 'TargetCopiedFileLocation' -ClearSheet;
            $Sheet_DbDriveMapping | Export-Excel -Path $MappingExcel -WorksheetName 'DbDriveMapping' -ClearSheet;

            Write-Host "Excel '$MappingExcel' is created";
            return;
        } # Logic for GenerateSampleMappingExcel

        if($EstimateRestoreSpaceRequirement) {
            Write-Verbose "Estimate Restore Space Requirement";
            Write-Output $srcDatabases;
            return;
        }

        # Generate Copy Commands for Full/Diff backups
        if($true) {
            #Write-Debug "Generate Copy Commands";
            Write-Verbose "Inside Generate Copy Commands for Full/Diff backups";
            
            if(-not [String]::IsNullOrEmpty($MappingExcel) -and $(Test-Path $MappingExcel)) {
                Write-Verbose "Import MappingExcel data";
                $Sheet_RestoreAs = Import-Excel -Path $MappingExcel -WorksheetName 'RestoreAs';
                $Sheet_TargetCopiedFileLocation = Import-Excel -Path $MappingExcel -WorksheetName 'TargetCopiedFileLocation';
                $Sheet_DbDriveMapping = Import-Excel -Path $MappingExcel -WorksheetName 'DbDriveMapping';
            }

            # Join BackupFiles with Sheet_TargetCopiedFileLocation
            if($true) {
                Write-Verbose "Join BackupFiles with Sheet_TargetCopiedFileLocation"
                $TargetCopyFileLocation_Default = 'C:';
                #if($TargetCopyFileLocation_Default.Length -le 3) {
                 #   $TargetCopyFileLocation_Default = "$TargetCopyFileLocation_Default\";
                #}
                $UniqueTargetPaths = $Sheet_TargetCopiedFileLocation | Select-Object -Property @{l='BackupPath';e={($_.BackupPath).TrimEnd('\')}} -Unique;
                $BackupFiles = $srcDatabases.Backups | Where-Object {$_.BackupSize.GigaByte -gt $BackupCopySizeThreshold_GB} | Select-Object DatabaseName, BackupTypeDescription, BackupSize, @{l='FileName';e={Split-Path -Path $_.BackupFile -Leaf}}, @{l='FileDirectory';e={Split-Path -Path $_.BackupFile}};
                foreach($bkpFile in $BackupFiles) {
                    $TargetCopyFileLocation = ($Sheet_TargetCopiedFileLocation | Where-Object {$_.DbName -eq $bkpFile.DatabaseName}).BackupPath
                    if(-not [string]::IsNullOrEmpty($TargetCopyFileLocation)) {
                        $bkpFile | Add-Member -NotePropertyName TargetCopyFileLocation -NotePropertyValue $($TargetCopyFileLocation.TrimEnd('\'));
                    }else {
                        $bkpFile | Add-Member -NotePropertyName TargetCopyFileLocation -NotePropertyValue $TargetCopyFileLocation_Default;
                    }
                }                
            } # Join BackupFiles with Sheet_TargetCopiedFileLocation

            # Generate CopyCommand Collection
            if($true) {
                $UniqueBackupDirectories = $BackupFiles | Select-Object -Property @{l='FileDirectory';e={($_.FileDirectory).TrimEnd('\')}} -Unique;
                [System.Collections.ArrayList]$CopyCommands = @();
                $UniqueBackupDirectories_FileDirectories = $UniqueBackupDirectories.FileDirectory;
                $UniqueTargetPaths_BackupPath = $UniqueTargetPaths.BackupPath;
                if([string]::IsNullOrEmpty($UniqueTargetPaths_BackupPath)) {
                    $UniqueTargetPaths_BackupPath = $TargetCopyFileLocation_Default;
                }
                foreach($cpPath in $UniqueBackupDirectories_FileDirectories) {
                    foreach($pstPath in $UniqueTargetPaths_BackupPath) {
                        # find backup files present on $cpPath to be copied on $pstPath
                        $files2Copy = ($BackupFiles | Where-Object {$_.FileDirectory -eq $cpPath -and $_.TargetCopyFileLocation -eq $pstPath} | Select-Object @{l='FileName';e={"`"$($_.FileName)`""}}).FileName -join ' ';
                        #$pstNetworkPath = "\\$TargetServerName\"+$pstPath.Replace(':','$');

                        if(-not [String]::IsNullOrEmpty($files2Copy)) {
                            $CopyCommand = "robocopy \\$SourceServerNodeName\$($cpPath.Replace(':','$')) $(if($pstPath.Length -lt 3){"$pstPath\"}else{$pstPath}) /it $files2Copy";
                            $TargetPathDrive = "$(Split-Path -Path $pstPath -Qualifier)\";
                            $CopyCommandObj = [PSCustomObject]@{
                                                    SourcePath = $cpPath;
                                                    TargetPath = $pstPath;
                                                    TargetPathDrive = $TargetPathDrive;
                                                    CopyCommand = $CopyCommand;
                                                }
                            $CopyCommands.Add($CopyCommandObj) | Out-Null;
                        }
                    } # Loop through each Target Directory
                } # Loop Through each Backup Directory
            } # Generate CopyCommand Collection
        } # Generate Copy Commands for Full/Diff backups

        # Return $CopyCommands
        if($OnlyCopyCommand) {
            Write-Verbose "Return `$CopyCommands";
            Write-Output $CopyCommands;
            #Write-Debug "Before exit";
            return;
        } # Return $CopyCommands

        # Generate Restore Commands
        if($true) {
            Write-Verbose "Inside Generate Copy Commands for Full/Diff backups";
            if(-not [String]::IsNullOrEmpty($MappingExcel) -and $(Test-Path $MappingExcel)) {
                if([String]::IsNullOrEmpty($Sheet_DbDriveMapping)) {
                    Write-Verbose "Import MappingExcel data";
                    $Sheet_RestoreAs = Import-Excel -Path $MappingExcel -WorksheetName 'RestoreAs';
                    $Sheet_TargetCopiedFileLocation = Import-Excel -Path $MappingExcel -WorksheetName 'TargetCopiedFileLocation';
                    $Sheet_DbDriveMapping = Import-Excel -Path $MappingExcel -WorksheetName 'DbDriveMapping';
                }
            }

            $LargeBackupDbNames = ($BackupsAllDbs | Where-Object {$_.BackupTypeDescription -eq 'Database' -and $_.BackupSize.GigaByte -gt $BackupCopySizeThreshold_GB}).DatabaseName;
            $SmallBackupDbNames = ($BackupsAllDbs | Where-Object {$_.BackupTypeDescription -eq 'Database' -and $_.BackupSize.GigaByte -le $BackupCopySizeThreshold_GB}).DatabaseName;
            
            # Find database Files on Destination
            if($true){
                Write-Verbose "Find database Files on Destination";                
                $rSrcDatabases_CommaList = (($rSrcDatabases | Select-Object @{l='name';e={"'$($_.name)'"}}).name -join ',');

                # TSQL - Get Database Files for Source SqlInstance
                $dbFiles_tsql = @"
select	DB_NAME(df.database_id) as DatabaseName, df.type_desc, df.name, df.physical_name, df.state_desc, df.size, df.max_size, df.growth
from sys.master_files as df
where DB_NAME(df.database_id) in ($rSrcDatabases_CommaList);
"@;
                $rTgtDatabaseFiles = Invoke-DbaQuery -SqlInstance $tgtObj -Database master -Query $dbFiles_tsql;
            }
            
            Write-Verbose "Creating loop counter variables..";
            # Creating loop counter variables..
            if($true) {
                $fileCounter_Database = 1;
                $fileCounterTotal_Database = 1;
                $dbCounter = 1;
                $dbCounter_Total = $rSrcDatabases.Count;
                [System.Collections.ArrayList]$RestoreCommands = @();
                $tsqlRestoreDatabaseFiles = '';
            } # Creating loop counter variables..

            # Loop through each backup file to add Restore Script object
            foreach($bkpFile in $BackupsAllDbs) {
                #Write-Debug "Generate Restore Commands";
                Write-Verbose "Processing backup file '$($bkpFile.BackupFile)'";
                if([String]::IsNullOrEmpty($dbName)) {
                    $dbName = $bkpFile.DatabaseName;
                    $tsqlRestoreDatabaseFiles = '';
                }

                # reset counters for next database
                if($dbName -ne $bkpFile.DatabaseName) {
                    #Write-Debug "Creating RestoreCommand Object"
                    $NewDataFilePath = $finalDbFiles | Where-Object {$_.type_desc -eq 'ROWS'} | Select-Object -ExpandProperty physical_name_new -First 1;
                    $NewDataFileDirectory = Split-Path -Path $NewDataFilePath;
                    $NewDataFileDrive = "$(Split-Path -Path $NewDataFilePath -Qualifier)\";
                    $restoreObj = [PSCustomObject]@{
                                        DbName = $dbName;
                                        DestinationDirectory = $NewDataFileDirectory;
                                        DestinationDrive = $NewDataFileDrive;
                                        RestoreCommand = $tsqlRestoreDatabaseFiles;
                                    }
                    $RestoreCommands.Add($restoreObj) | Out-Null;

                    $tsqlRestoreDatabaseFiles = '';
                    $dbCounter += 1;
                    $fileCounter_Database = 1;
                    $dbName = $bkpFile.DatabaseName;
                } # reset counters for next database

                $isCopiedLocally = $false;
                $SetFileRecovery = $false;

                # Is backup file copied locally on target
                if($bkpFile.BackupSize.GigaByte -gt $BackupCopySizeThreshold_GB -and $bkpFile.BackupTypeDescription -in @('Database','Differential database')) {
                    Write-Verbose "Verifying if backup file is copied locally on target"
                    $isCopiedLocally = $true;
                    $MappingBackupPath = ($Sheet_TargetCopiedFileLocation | Where-Object {$_.DbName -eq $dbName}).BackupPath;
                    if(-not [string]::IsNullOrEmpty($MappingBackupPath)) {
                        $MappingBackupPath = $(if($MappingBackupPath.EndsWith('\')){$MappingBackupPath}else{"$MappingBackupPath\"});
                    } else {
                        $MappingBackupPath = $(if($TargetCopyFileLocation_Default.EndsWith('\')){$TargetCopyFileLocation_Default}else{"$TargetCopyFileLocation_Default\"});
                    }
                    $backupFilePath = $MappingBackupPath+$(Split-Path -Path $bkpFile.BackupFile -Leaf);
                } # Is backup file copied locally on target
                
                # Is file to be restore from network
                if(-not $isCopiedLocally) {
                    $backupFilePath = $bkpFile.BackupFile_NetworkPath;
                } # Is file to be restore from network
                
                # Set recovery flag if $Recover is used, and there is no other backup to process
                if($Recover) {
                    $RemainingDbBackupsToProcess = $BackupsAllDbs | Where-Object {$_.DatabaseName -eq $dbName -and $_.BackupStartDate -gt $bkpFile.BackupStartDate};
                    if([string]::IsNullOrEmpty($RemainingDbBackupsToProcess)) {
                        $SetFileRecovery = $true;
                    }
                }

                if($bkpFile.BackupTypeDescription -eq 'Database') {
                    Write-Verbose "creating variable for Full backup case";

                    $finalDbFiles = @();
                    $tgtDbFiles = $rTgtDatabaseFiles | Where-Object {$_.DatabaseName -eq $dbName};
                    $tgtDbFilesArray = $tgtDbFiles.name;
                    $srcDbFiles = ($SrcDatabases | Where-Object {$_.DbName -eq $dbName}).Files;
                    $srcDbFilesArray = $srcDbFiles.name;
                    $filesMapping = $Sheet_DbDriveMapping | Where-Object {$_.DbName -eq $dbName};

                    
                    $totalBackupFiles4Database = $BackupsAllDbs | Where-Object {$_.DatabaseName -eq $dbName};
                    if([string]::IsNullOrEmpty($totalBackupFiles4Database.Count)) { $fileCounterTotal_Database = 1 }
                    else {$fileCounterTotal_Database = $totalBackupFiles4Database.Count;}

                    
                    # If db file mapping is provided, then put source files according to mapping
                    if(-not [string]::IsNullOrEmpty($filesMapping)) {
                        Write-Verbose "`tMake variable adjustment according to MappingExcel";

                        $finalDbFiles = $srcDbFiles;
                        $filesMapping_DataString = $filesMapping.DataDrive;
                        $filesMapping_LogString = $filesMapping.LogDrive;
                        
                        # If log location is not mentioned, then use Data location for it
                        if([string]::IsNullOrEmpty($filesMapping_LogString)){$filesMapping_LogString = $filesMapping_DataString}

                        # If only drive letter mentioned
                        if($filesMapping_DataString.Length -le 3) {
                            $filesMapping_DataDrive = if($filesMapping_DataString.EndsWith('\')){$filesMapping_DataString}else{"$filesMapping_DataString\"}
                        }else {
                            $filesMapping_DataDirectory = if($filesMapping_DataString.EndsWith('\')){$filesMapping_DataString}else{"$filesMapping_DataString\"}
                        }
                        if($filesMapping_LogString.Length -le 3) {
                            $filesMapping_LogDrive = if($filesMapping_LogString.EndsWith('\')){$filesMapping_LogString}else{"$filesMapping_LogString\"}
                        }else {
                            $filesMapping_LogDirectory = if($filesMapping_LogString.EndsWith('\')){$filesMapping_LogString}else{"$filesMapping_LogString\"}
                        }

                        Write-Verbose "`t`tAdd new physical_name attribute to `$finalDbFiles"
                        # add new physical_name attribute to $finalDbFiles
                        foreach($file in $finalDbFiles) {
                            $physical_name = $file.physical_name;
                            $physical_name_basefile = (Split-Path -Path $physical_name -Leaf);
                            $physical_name_directory = (Split-Path -Path $physical_name);

                            # get new physical_name
                            if($file.type_desc -eq 'ROWS') {
                                if(-not [string]::IsNullOrEmpty($filesMapping_DataDrive)) {
                                    $physical_name_new = $physical_name -replace "^[A-Za-z]:\\*", $filesMapping_DataDrive;
                                } else {
                                    $physical_name_new = "$filesMapping_DataDirectory\$physical_name_basefile";
                                }
                            }else {
                                if(-not [string]::IsNullOrEmpty($filesMapping_LogDrive)) {
                                    $physical_name_new = $physical_name -replace "^[A-Za-z]:\\*", $filesMapping_LogDrive;
                                } else {
                                    $physical_name_new = "$filesMapping_LogDirectory\$physical_name_basefile";
                                }
                            } # get new physical_name

                            # Add new attribute
                            $file | Add-Member -NotePropertyName physical_name_new -NotePropertyValue $physical_name_new;
                        } # add new physical_name attribute to $finalDbFiles
                    } # If db file mapping is provided, then put source files according to mapping


                    # If db file mapping is not provided, then use path of destination until $OverwriteExistingFileDirectories swith is used
                    if([string]::IsNullOrEmpty($filesMapping)) {
                        Write-Verbose "`tMake variable adjustment when MappingExcel value not found";

                        # Use Target file path if $OverwriteExistingFileDirectories
                        if($OverwriteExistingFileDirectories) {
                            $finalDbFiles = $srcDbFiles;
                        }else {
                            if(-not [string]::IsNullOrEmpty($tgtDbFiles)) {
                                $CmprResult = Compare-Object -ReferenceObject $srcDbFiles -DifferenceObject $tgtDbFiles -IncludeEqual;
                                if($CmprResult.SideIndicator -contains '=>' -or $CmprResult.SideIndicator -contains '<=') {
                                    Write-Host "Database files on '$SourceSqlInstance' and '$TargetSqlInstance' differ for database [$dbName].`nKindly use `$OverwriteExistingFileDirectories switch to overwrite." -ForegroundColor Red;
                                    return
                                }                                
                                $finalDbFiles = $tgtDbFiles;
                            }else {
                                $finalDbFiles = $srcDbFiles;
                            }
                        } # Use Target file path if $OverwriteExistingFileDirectories

                        Write-Verbose "`t`tAdd new physical_name attribute to `$finalDbFiles"
                        # add new physical_name attribute to $finalDbFiles
                        foreach($file in $finalDbFiles) {
                            $physical_name_new = $file.physical_name;
                            # Add new attribute
                            $file | Add-Member -NotePropertyName physical_name_new -NotePropertyValue $physical_name_new;
                        } # add new physical_name attribute to $srcDbFiles                       
                        
                    } # If db file mapping is not provided, then use path of destination until $OverwriteExistingFileDirectories swith is used
                }
                
                #Write-Debug "`$finalDbFiles collection is created";             

                $tsqlSeparater = @"
`n-- =========================================================================
-- =========================================================================
"@;
                
                $tsqlPrintStmt_Database = "`nPRINT '$dbCounter) Restoring database [$dbName]';";
                
                $tsqlSetOffline = @"
`n-- Set database to Offline
USE master;
ALTER DATABASE [$dbName] SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO
"@;
                        
                $tsqlPrintStmt_File = "`n`tPRINT '        File no: $fileCounter_Database of $fileCounterTotal_Database';";
                                    
                $tsqlRestore_Full = @"
`nRESTORE DATABASE [$dbName] FROM DISK = '$backupFilePath'
  WITH $(if($SetFileRecovery){"RECOVERY"}else{"NORECOVERY"}), $(if($OverwriteExistingFileDirectories){"REPLACE, "}else{''})STATS = 5
"@;
                
                $tsqlCreateFolder = "`n-- Create Data/Log folder";
                foreach($file in $finalDbFiles) {
                    $tsqlRestore_Full += "`n`t,MOVE '$($file.name)' TO '$($file.physical_name_new)'";
                    $tsqlCreateFolder += "`nEXEC master.sys.xp_create_subdir '$(Split-Path -Path $file.physical_name_new)';";
                }
                $tsqlCreateFolder += "`nGO`n"
                
                $tsqlRestore_NonFull = @"
`nRESTORE $(if($bkpFile.BackupTypeDescription -eq 'Log'){"LOG"}else{"DATABASE"}) [$dbName] FROM DISK = '$backupFilePath'
  WITH $(if($SetFileRecovery){"RECOVERY"}else{"NORECOVERY"}), STATS = 5;
$(if($bkpFile.BackupTypeDescription -ne 'Log'){"GO"})
"@;

                $tsqlRestore_Full += "`nGO";

                if($bkpFile.BackupTypeDescription -eq 'Database') {
                    $tsqlRestoreFinal = $tsqlCreateFolder + $tsqlPrintStmt_Database + $tsqlPrintStmt_File + $tsqlRestore_Full;
                    if($OverwriteExistingFileDirectories){$tsqlRestoreFinal = $tsqlSetOffline + $tsqlRestoreFinal}
                } else {
                    $tsqlRestoreFinal = $tsqlPrintStmt_File + $tsqlRestore_NonFull;
                }

                if($fileCounter_Database -eq $fileCounterTotal_Database) {
                    $tsqlRestoreFinal += $tsqlSeparater;
                }

                #Write-Verbose "`$tsqlRestoreFinal => ";
                #Write-Host $tsqlRestoreFinal -ForegroundColor Green;
                $tsqlRestoreDatabaseFiles += $tsqlRestoreFinal;

                #Write-Debug "End of Iteration $fileCounter_Database for [$dbName]"

                $fileCounter_Database += 1;
            } # Loop through each backup file to add Restore Script object

            Write-Verbose "Adding last RestoreCommand object in Collection";
            $NewDataFilePath = $finalDbFiles | Where-Object {$_.type_desc -eq 'ROWS'} | Select-Object -ExpandProperty physical_name_new -First 1;
            $NewDataFileDirectory = Split-Path -Path $NewDataFilePath;
            $NewDataFileDrive = "$(Split-Path -Path $NewDataFilePath -Qualifier)\";
            $restoreObj = [PSCustomObject]@{
                                DbName = $dbName;
                                DestinationDirectory = $NewDataFileDirectory;
                                DestinationDrive = $NewDataFileDrive;
                                RestoreCommand = $tsqlRestoreDatabaseFiles;
                            }
            $RestoreCommands.Add($restoreObj) | Out-Null;
        } # Generate Restore Commands

        # Return $OnlyRestoreCommand
        if($OnlyRestoreCommand) {
            Write-Verbose "Return RestoreCommands";
            Write-Output $RestoreCommands;
            return;
        }

        # Output Restore & Copy Commands
        if($true) {
            # Create File for storing copy commands
            $ResultFile_CopyCommands = "C:\temp\DbaRestoreScripts_CopyCommands_$(Get-Date -Format ddMMMyyyyTHHmm).txt";
            # Create File for storing restore commands of Large Dbs
            $ResultFile_RestoreLargeDbs = "C:\temp\DbaRestoreScripts_LargeDatabases_$(Get-Date -Format ddMMMyyyyTHHmm).sql";
            # Create File for storing restore commands of Small Dbs
            $ResultFile_RestoreSmallDbs = "C:\temp\DbaRestoreScripts_SmallDatabases_$(Get-Date -Format ddMMMyyyyTHHmm).sql";

            # Append Copy Commands to Notepad file order by TargetDrive
            if($true) {
                $SessionCounter = 1;
                # Loop through unique Target Path
                $DistinctTargetPathDrives = ($CopyCommands | Sort-Object -Property TargetPathDrive -Unique | Select-Object TargetPathDrive).TargetPathDrive;
                foreach($pth in $DistinctTargetPathDrives) {
                    $CopyCommandHeader = @"
`n<# ##########  PSSession# $SessionCounter -- Copy Backup files on $pth of server $TargetServerName  ####
    # Execute below Commands in Elevated Powershell ISE Session against Target server

"@;
                    $CopyCommandsFiltered = ($CopyCommands | Where-Object {$_.TargetPathDrive -eq $pth} | Sort-Object -Property TargetPath);
                    foreach($cmd in $CopyCommandsFiltered) {
                        $CopyCommandHeader += "$($cmd.CopyCommand)`n";
                    }
                    $CopyCommandHeader += "`n`n";
                    $CopyCommandHeader | Out-File -Append $ResultFile_CopyCommands;
                    $SessionCounter += 1;
                }

                Write-Host "Opening generated copy script file '$ResultFile_CopyCommands' with notepad.";
                if (Test-Path $ResultFile_CopyCommands) {
                    notepad.exe $ResultFile_CopyCommands;
                }else {
                    Write-Host "No file found to be copied locally on Target server..";
                }
            } # Append Copy Commands to Notepad file order by TargetDrive

            # Append Restore Commands of Large Databases to Notepad file order by TargetDrive
            if($true) {
                #Write-Debug "Generate Restore commands in Text File";
                $SessionCounter = 1;
                # Loop through unique Target Path
                $DistinctTargetPathDrives = ($RestoreCommands | Where-Object {$_.DbName -in $LargeBackupDbNames} | Sort-Object -Property DestinationDrive -Unique | Select-Object DestinationDrive).DestinationDrive;
                foreach($pth in $DistinctTargetPathDrives) {
                    $RestoreCommandHeader = @"
`n-- ##########  Session# $SessionCounter -- Restore database on $pth of instance [$TargetSqlInstance]  ####
    -- Execute below TSQL statements in a SSMS against Target server

"@;
                    $RestoreCommandsFiltered = ($RestoreCommands | Where-Object {$_.DbName -in $LargeBackupDbNames -and $_.DestinationDrive -eq $pth} | Sort-Object -Property DestinationDirectory);
                    foreach($cmd in $RestoreCommandsFiltered) {
                        $RestoreCommandHeader += "$($cmd.RestoreCommand)`n";
                    }
                    $RestoreCommandHeader += "`n`n";
                    $RestoreCommandHeader | Out-File -Append $ResultFile_RestoreLargeDbs;
                    $SessionCounter += 1;
                }

                Write-Host "Opening generated restore script file '$ResultFile_RestoreLargeDbs' with notepad.";
                if (Test-Path $ResultFile_RestoreLargeDbs) {
                    notepad.exe $ResultFile_RestoreLargeDbs;
                }else {
                    Write-Host "No backup found to be restored on Target server..";
                }
            } # Append Restore Commands of Large Databases to Notepad file order by TargetDrive

            # Append Restore Commands of Small Databases to Notepad file order by TargetDrive
            if($true) {
                # Filter for Small databases 
                $RestoreCommandsFiltered = ($RestoreCommands | Where-Object {$_.DbName -in $SmallBackupDbNames} | Sort-Object -Property DbName);
                foreach($cmd in $RestoreCommandsFiltered) {
                    $RestoreCommandHeader = "$($cmd.RestoreCommand)`n";
                    $RestoreCommandHeader | Out-File -Append $ResultFile_RestoreSmallDbs;
                }
                
                Write-Host "Opening generated restore script file '$ResultFile_RestoreSmallDbs' with notepad.";
                if (Test-Path $ResultFile_RestoreSmallDbs) {
                    notepad.exe $ResultFile_RestoreSmallDbs;
                }else {
                    Write-Host "No small backup found to be restored on Target server..";
                }
            } # Append Restore Commands of Large Databases to Notepad file order by TargetDrive


        } # Output Restore & Copy Commands
        return

        # Output Source Databases
        Write-Output $srcDatabases;
        
    }
    END {
    }
}