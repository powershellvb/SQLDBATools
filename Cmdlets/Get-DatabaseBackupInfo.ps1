Function Get-DatabaseBackupInfo {
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','SQLInstance')]
        [String]$ServerInstance = $env:COMPUTERNAME
    )
    
    if ($ServerInstance -eq "")
    {
        Write-Error 'Invalid Value for ServerInstance parameter';
    }
    else {
        
        $errorFile = "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo\$($ServerInstance -replace '\\','__')__ERROR.txt";
        
        # If not a named instance
        if ($ServerInstance -notlike '%\%') {
            $ServerInstance = "$ServerInstance\DEFAULT";
        }

        Push-Location;
        try {
            # Get Database properties
            Get-ChildItem -Force SQLSERVER:\SQL\$ServerInstance\Databases -ErrorAction Stop | Where-Object {$_.Name -ne 'tempdb'; $_.Refresh()} |  
            Select-Object @{Label="ServerName"; Expression={ $_.Parent -replace '[[\]]',''}}, 
                        @{l='DatabaseName';e={$_.Name}}, 
                        @{l='DatabaseCreationDate';e={IF ($_.CreateDate -eq "01/01/0001 00:00:00") {$null} else {($_.CreateDate).ToString("yyyy-MM-dd HH:mm:ss")}}}, 
                        RecoveryModel, 
                        @{l='LastFullBackupDate';e={IF ($_.LastBackupDate -eq "01/01/0001 00:00:00") {$null} else {($_.LastBackupDate).ToString("yyyy-MM-dd HH:mm:ss")}}}, 
                        @{l='LastDifferentialBackupDate';e={IF ($_.LastDifferentialBackupDate -eq "01/01/0001 00:00:00") {$null} else {($_.LastDifferentialBackupDate).ToString("yyyy-MM-dd HH:mm:ss")}}},  
                        @{l='LastLogBackupDate';e={IF ($_.LastLogBackupDate -eq "01/01/0001 00:00:00") {$null} else {($_.LastLogBackupDate).ToString("yyyy-MM-dd HH:mm:ss")}}},
                        @{l='CollectionTime';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}}
        }
        catch {
            $ErrorMessage = $_.Exception.Message;
            $FailedItem = $_.Exception.ItemName;
            
            # Create if Error Log path does not exist
            if ( (Test-Path "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo") -eq $false) {
                New-Item "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo" -ItemType directory;
            }

            # Drop old error log file
            if (Test-Path $errorFile) {
                Remove-Item $errorFile;
            }

            $ErrorMessage | Out-File $errorFile;
            Write-Verbose "Error occurred while trying to get BackupInfo for server [$ServerInstance]. Kindly check logs at $errorFile";
        }
               
        Pop-Location;
    }    
}