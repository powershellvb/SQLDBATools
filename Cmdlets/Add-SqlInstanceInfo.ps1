Function Add-SqlInstanceInfo
{
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Mandatory=$True,
                   Position=1)]
        [Alias('ServerName','MachineName')]
        [String]$ComputerName,

        [parameter(HelpMessage="Choose 'No' when adding multiple servers at same time")]
        [ValidateSet("Yes","No")]
        [String]$CallTSQLProcedure = "Yes"
    )

    # Switch to validate if Server to be added in Inventory
    $AddSwitch = $false;

    if ([String]::IsNullOrEmpty($ComputerName) -or (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -eq $false)
    {
        $MessageText = "Supplied value '$ComputerName' for ComputerName parameter is invalid, or server is not accessible.";
        Write-Host $MessageText -ForegroundColor Red;
        Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Add-SqlInstanceInfo' -CommandText "Add-SqlInstanceInfo -ComputerName '$ComputerName'" -ErrorText $MessageText -Remark $null;
        
        return;
    }
    else 
    {
        # collect sql instance information
        Write-Verbose "Finding all instances on '$ComputerName' server";
        $sqlInfo = Get-SQLInstanceInfo -ComputerName $ComputerName -LogErrorInInventory;
        $instNames = @($sqlInfo | Select-Object -ExpandProperty InstanceName);

        if($instNames.Count -eq 0)
        {
            $MessageText = "Get-SQLInstanceInfo -ComputerName '$ComputerName'   did not work.";
            Write-Host $MessageText -ForegroundColor Red;
            Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Add-SqlInstanceInfo' -CommandText "Get-SQLInstanceInfo -ComputerName '$ComputerName'" -ErrorText $MessageText -Remark $null;
            return;
        }

        $sqlInstances = @();

        #loop through each instance
        foreach($inst in $instNames)
        {
            Write-Verbose "  Checking if sql instance '$inst' is already present in Inventory";
            $sqlQuery = @"
    select 1 as IsPresent from [$InventoryDatabase].[info].[Instance] where InstanceName = '$inst'
"@;
            $Tables = $null;
            try 
            {
                $Tables = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Query $sqlQuery -ErrorAction Stop;
               
                if ($Tables -ne $null) {
                    Write-Host "SQL Instance '$inst' already present in Inventory" -ForegroundColor Green;
                } else {
                    Write-Verbose "SQL Instance '$inst' not on Inventory. Proceeding to add it..";
                    $sqlInstances += $sqlInfo | Where-Object {$_.InstanceName -eq $inst};
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
    }

    # If every condition is valid to add server
    if ($AddSwitch) 
    {
        $sqlInstanceInfo = $sqlInstances | Select-Object FQN, ServerName, InstanceName, InstallDataDirectory, Version, 
                                                        Edition, ProductKey, IsClustered, IsCaseSensitive, IsHadrEnabled, 
                                                        IsDecommissioned, IsPowerShellLinked, 
                                                        @{l='CollectionTime';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}};

        if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
        {
            Write-Host "VERBOSE: Showing data from `$sqlInstanceInfo : " -ForegroundColor Yellow;
            $sqlInstanceInfo | fl;
        }

        Write-Host "Adding instances from server $ComputerName to Inventory." -ForegroundColor Cyan;        
        try
        {
            $dtable = $sqlInstanceInfo | Out-DataTable;

            if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
            {
                Write-Host "VERBOSE: Showing data from `$dtable : " -ForegroundColor Yellow;
                $dtable | fl;
            }
        
            $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
            $cn.Open();

            $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
            $bc.DestinationTableName = "Staging.InstanceInfo";
            $bc.WriteToServer($dtable);
            $cn.Close();

            Write-Host "Details for instances from $ComputerName saved in Staging tables" -ForegroundColor Green;
        }
        catch
        {
            "Error occurred while writing SqlInstanceInfo into Staging table" | Write-Host -ForegroundColor Red;
            Write-Host ($Error) -BackgroundColor Red;
            Write-Host ($ErrorMessage) -BackgroundColor Red;

            $ErrorMessage = $_.Exception.Message;
            $FailedItem = $_.Exception.ItemName;

            # Output Error in file
            @"
            Error occurred while running 
            Add-SqlInstanceInfo -ComputerName $ComputerName -Verbose
            $ErrorMessage
"@ | Out-Host;
            Write-Host "Error occurred in while trying to run Add-SqlInstanceInfo for server [$ComputerName]." -BackgroundColor Red;
        }
            
        # Populate Main table from Staging
        $sqlQuery = @"
    EXEC [Staging].[usp_ETL_SqlInstanceInfo];
"@;
        if ($CallTSQLProcedure -eq 'Yes') 
        {
            Write-Verbose "Calling TSQL Procedure to move SQL Instance Info from Stage to Main tables..";
            Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery;
            Write-Verbose "SQL Instance Details for server $ComputerName moved from Staging table to main table.";
        }
    }
}

#Add-SqlInstanceInfo -ComputerName $env:COMPUTERNAME;
