Function Add-DatabaseInfo
{
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName')]
        [String]$SQLInstance = $env:COMPUTERNAME
    )

    $ExecutionLogsFile = "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo\___ExecutionLogs.txt";
    
    if ($SQLInstance -eq "")
    {
        Write-Error 'Invalid Value for SQLInstance parameter';
    }
    else {
        
        # Making entry into General Logs File
        #"$SQLInstance " | Out-File -Append $ExecutionLogsFile;

        $ComputerName = $SQLInstance.Split('\')[0];
        $errorFile = "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo\$($ServerInstance -replace '\\','__').txt";
        Push-Location;

        try {

            # http://www.itprotoday.com/microsoft-sql-server/bulk-copy-data-sql-server-powershell
            $backupInfo = Get-DatabaseBackupInfo_SMO -SQLInstance $SQLInstance;

            if ($backupInfo -eq $null)
            {
                $MessageText = "Get-DatabaseBackupInfo_SMO -SQLInstance '$SQLInstance'   did not work.";
                Write-Verbose $MessageText;
                Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Collect-DatabaseBackupInfo' -CommandText "Get-DatabaseBackupInfo_SMO -SQLInstance '$SQLInstance'" -ErrorText $MessageText -Remark $null;
                return;
            }

            $dtable = $backupInfo | Out-DataTable;    
        
            $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
            $cn.Open();

            $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
            $bc.DestinationTableName = "Staging.DatabaseBackups";
            $bc.WriteToServer($dtable);
            $cn.Close();
        }
        catch {
            $ErrorMessage = $_.Exception.Message;
            $FailedItem = $_.Exception.ItemName;
            
            # Create if Error Log path does not exist
            if (Test-Path "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo") {
                New-Item "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo" -ItemType directory;
            }

            # Drop old error log file
            if (Test-Path $errorFile) {
                Remove-Item $errorFile;
            }

            # Output Error in file
            @"
Error occurred while running 
Collect-DatabaseBackupInfo -SQLInstance $SQLInstance -Verbose
$ErrorMessage
"@ | Out-File $errorFile;
            Write-Verbose "Error occurred in while trying to get BackupInfo for server [$ServerInstance]. Kindly check logs at $errorFile";
        }
        
        Pop-Location;
    }    
}

