Clear-Host;
Script-SQLDatabaseRestore   -BackupPath "$InventoryBackupPath\Backup" `
                            -RestoreCategory LatestAvailable `
                            -Destination_SQLInstance "$InventoryInstance" `
                            -DestinationPath_Data "F:\mssqldata\Data" `
                            -DestinationPath_Log "E:\Mssqldata\Log" `
                            -SourceDatabase Cosmo `
                            -RestoreAs Cosmo_Temp `
                            -Verbose