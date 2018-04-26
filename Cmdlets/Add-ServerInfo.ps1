Function Add-ServerInfo
{
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Mandatory=$True,
                   Position=1)]
        [Alias('ServerName','MachineName')]
        [String]$ComputerName,

        [ValidateSet('Prod','QA','Test','Dev')]
        [Parameter(Mandatory=$True,Position=2)]
        [String]$EnvironmentType,

        [parameter(HelpMessage="Choose 'No' when adding multiple servers at same time")]
        [ValidateSet("Yes","No")]
        [String]$CallServerInfoTSQLProcedure = "Yes"
    )

    # Switch to validate if Server to be added in Inventory
    $AddSwitch = $false;

    if ([String]::IsNullOrEmpty($ComputerName) -or (Test-Connection -ComputerName $ComputerName) -eq $false)
    {
        Write-Error 'Either supplied value for ComputerName parameter is invalid, or server is not accessible.';
    }
    else 
    {
        Write-Verbose "  Checking if '$ComputerName' is already present in Inventory";
        $sqlQuery = @"
select 1 as IsPresent from [$InventoryDatabase].[info].[Server] where ServerName = '$ComputerName'
"@;
        $Tables = $null;
        try 
        {
            $Tables = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Query $sqlQuery -ErrorAction Stop;
               
            if ($Tables -ne $null) {
                Write-Host "Server $ComputerName already present in Inventory" -ForegroundColor Green;
            } else {
                $AddSwitch = $true;
            }
        }
        catch 
        {
            "Error occurred while running sql $sqlQuery" | Write-Host -ForegroundColor Red;
            Write-Host ($Error);
            Write-Host ($ErrorMessage);
        }
    }

    # If every condition is valid to add server
    if ($AddSwitch) 
    {
        # http://www.itprotoday.com/microsoft-sql-server/bulk-copy-data-sql-server-powershell
        Write-Verbose "  Calling Get-ServerInfo -ComputerName $ComputerName";
        $serverInfo = Get-ServerInfo -ComputerName $ComputerName | Select-Object ComputerName, @{l='EnvironmentType';e={$EnvironmentType}}, HostName,IPAddress,Domain,OS,SPVersion,Model,'RAM(MB)',CPU,@{l='CollectionTime';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}};
           
        if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) { $serverInfo | ft -AutoSize; }
            
        foreach ($i in $serverInfo)
        {
            $ComputerName = $i.ComputerName;
            try 
            {
                if ($AddSwitch) 
                {
                    Write-Host "Adding server $ComputerName to Inventory";
                
                    $dtable = $i | Out-DataTable; 
        
                    $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
                    $cn.Open();

                    $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
                    $bc.DestinationTableName = "Staging.ServerInfo";
                    $bc.WriteToServer($dtable);
                    $cn.Close();

                    Write-Verbose "Details for server $ComputerName saved in Staging tables";
                }
            }
            catch 
            {
                "Error occurred while writing ServerInfo into Staging table" | Write-Host -ForegroundColor Red;
                Write-Host ($Error);
                Write-Host ($ErrorMessage);

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

        # Populate Main table from Staging
        $sqlQuery = @"
    EXEC [dbo].[usp_ETL_ServerInfo];
"@;
        if ($CallServerInfoTSQLProcedure -eq 'Yes') 
        {
            Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery;
            Write-Verbose "Details for server $ComputerName moved from Staging table to main table.";
        }
    }
}


