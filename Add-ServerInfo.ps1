Function Add-ServerInfo
{
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName')]
        [String]$ComputerName = $env:COMPUTERNAME,

        [ValidateSet('Prod','QA','Test','Dev')]
        [Parameter(mandatory=$true)]
        [String]$EnvironmentType,

        [ValidateSet('Yes','No')]
        [String]$CallServerInfoTSQLProcedure = 'Yes'
    )

    if ($ComputerName -eq "")
    {
        Write-Error 'Invalid Value for ComputerName parameter';
    }
    else {
        
        try {
            # http://www.itprotoday.com/microsoft-sql-server/bulk-copy-data-sql-server-powershell
            $serverInfo = Get-ServerInfo -ComputerName $ComputerName | Select-Object ComputerName, @{l='EnvironmentType';e={$EnvironmentType}}, HostName,IPAddress,Domain,OS,SPVersion,Model,'RAM(MB)',CPU,@{l='CollectionTime';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}};
            
            $serverInfo | ft -AutoSize | Write-Verbose;
            
            foreach ($i in $serverInfo)
            {
                $ComputerName = $i.ComputerName;
                $sqlQuery = @"
select 1 as IsPresent from [$InventoryDatabase].[info].[ServerInfo] where ServerName = '$ComputerName'
--select 1 as IsPresent from [$InventoryDatabase].dbo.Instance where Name = '$ComputerName'
"@;
                $Tables = $null;
                $Tables = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Query $sqlQuery;
                if ($Tables -ne $null) {
                    Write-Host "Server $ComputerName already added in Inventory";
                    Write-Verbose $sqlQuery;
                }
                else {
                    Write-Host "Adding server $ComputerName to Inventory";
                
                    $dtable = $i | Out-DataTable;    
        
                    $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
                    $cn.Open();

                    $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
                    $bc.DestinationTableName = "Staging.ServerInfo";
                    $bc.WriteToServer($dtable);
                    $cn.Close();
               }
            }

            # Populate Main table from Staging
            $sqlQuery = @"
EXEC [dbo].[usp_ETL_ServerInfo];
"@;
            if ($CallServerInfoTSQLProcedure -eq 'Yes') {
                Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase] -Query $sqlQuery;
            }
            
        }
        catch {
            $ErrorMessage = $_.Exception.Message;
            $FailedItem = $_.Exception.ItemName;

            # Output Error in file
            @"
Error occurred while running 
Add-ServerInfo -ComputerName $ComputerName -Verbose
$ErrorMessage
"@ | Out-Host;
            Write-Host "Error occurred in while trying to get Add-ServerInfo for server [$ComputerName].";
        }
    }    
}


