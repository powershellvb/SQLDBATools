Clear-Host;
Script-SQLDatabaseRestore -BackupPath '\\Tul1cipedb3\g$\Backup' `
                    -RestoreCategory LatestAvailable `
                    -Destination_SQLInstance $InventoryInstance `
                    -DestinationPath_Data 'F:\mssqldata\Data' `
                    -DestinationPath_Log 'E:\Mssqldata\Log'`
                    -Verbose
                    #-SourceDatabase 'EIDR_Dedup' 

<#
$PhysicalPath = 'F:\Mssqldata\Data\UserTracking_data.mdf'
$r = $PhysicalPath -match "^(?'PathPhysicalName'.*[\\\/])(?'BasePhysicalNameWithExtension'(?'BasePhysicalNameWithoutExtension'.+)(?'Extension'\.[a-zA-Z]+$))";

$BasePhysicalNameWithExtension = $Matches['BasePhysicalNameWithExtension'] #UserTracking_data.mdf
$Extension = $Matches['Extension'] #.mdf
$PathPhysicalName = $Matches['PathPhysicalName'] #F:\Mssqldata\Data\
$BasePhysicalNameWithoutExtension = $Matches['BasePhysicalNameWithoutExtension'] #UserTracking_data
$PhysicalPath_New = $DestinationPath_Data + $BasePhysicalNameWithExtension
#>