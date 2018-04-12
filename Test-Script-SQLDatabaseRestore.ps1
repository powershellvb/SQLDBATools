Clear-Host;
Script-SQLDatabaseRestore -BackupPath '\\Tul1cipedb3\g$\Backup' `
                    -RestoreCategory LatestAvailable `
                    -Destination_SQLInstance $InventoryInstance `
                    -DestinationPath_Data 'F:\mssqldata\Data' `
                    -DestinationPath_Log 'E:\Mssqldata\Log'`
                    -SourceDatabase 'EIDR_Dedup'`
                    -Replace `
                    -NoRecovery
                    #-Replace

                    #-Verbose
                    #-SourceDatabase 'EIDR_Dedup' 
