Function Add-SqlInstanceInfo
{
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Mandatory=$True,
                   Position=1)]
        #[Alias('ServerName','MachineName')]
        [String]$ServerName,

        [parameter(HelpMessage="Choose 'No' when adding multiple servers at same time")]
        [ValidateSet("Yes","No")]
        [String]$CallTSQLProcedure = "Yes",

        [Parameter(Mandatory=$false)]
        [ValidateSet($true, $false)]
        [String]$HasOtherHASetup = $false,

        [Parameter(Mandatory=$false)]
        [String]$HARole = $null,

        [Parameter(Mandatory=$false)]
        [String]$HAPartner = $null,

        [Parameter(Mandatory=$false)]
        [String]$CollectedBy = "$($env:USERDOMAIN)\$($env:USERNAME)",

        [Parameter(Mandatory=$false)]
        [String]$Remark1 = $null,

        [Parameter(Mandatory=$false)]
        [String]$Remark2 = $null
    )

    # Switch to validate if Server to be added in Inventory
    $AddSwitch = $false;

    if ([String]::IsNullOrEmpty($ServerName) -or (Test-Connection -ComputerName $ServerName -Count 1 -Quiet) -eq $false)
    {
        $MessageText = "Supplied value '$ServerName' for ServerName parameter is invalid, or server is not accessible.";
        if($Global:PrintUserFriendlyMessage) {
            Write-Host $MessageText -ForegroundColor Red;
        }
        if($Global:LogErrorToInventoryTable) {
            Add-CollectionError -ComputerName $ServerName -Cmdlet 'Add-SqlInstanceInfo' -CommandText "Add-SqlInstanceInfo -ComputerName '$ComputerName'" -ErrorText $MessageText -Remark $null;
        }
        
        return;
    }
    else 
    {
        # collect sql instance information
        Write-Verbose "Finding all instances on '$ServerName' server";
        $sqlInfo = Get-SQLInstanceInfo -ServerName $ServerName;
        
        $instNames = @($sqlInfo | Select-Object -ExpandProperty InstanceName);

        if($instNames.Count -eq 0)
        {
            $MessageText = "Get-SQLInstanceInfo -ServerName '$ServerName'   did not work. No SqlInstance found on server.";
            if($Global:PrintUserFriendlyMessage) {
                Write-Host $MessageText -ForegroundColor Red;
            }
            if($Global:LogErrorToInventoryTable) {
                Add-CollectionError -ComputerName $ServerName -Cmdlet 'Add-SqlInstanceInfo' -CommandText "Get-SQLInstanceInfo -ComputerName '$ServerName'" -ErrorText $MessageText -Remark $null;
            }

            return;
        }

        $sqlInstances = @();
        
        #loop through each instance
        foreach($inst in $instNames)
        {
            Write-Verbose "  Checking if sql instance '$inst' is already present in Inventory";
            $sqlQuery = @"
    select 1 as IsPresent from [$InventoryDatabase].[dbo].[Instance] where SqlInstance = '$($inst.SqlInstance)'
"@;
            $Tables = $null;
            try 
            {
                $Tables = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Query $sqlQuery -ErrorAction Stop;
               
                if ($Tables -ne $null) {
                    if($Global:PrintUserFriendlyMessage) {
                        Write-Host "SQL Instance '$inst' already present in Inventory" -ForegroundColor Green;
                    }
                } else {
                    Write-Verbose "SQL Instance '$inst' not on Inventory. Proceeding to add it..";
                    $sqlInfo | Add-Member -NotePropertyName 'HasOtherHASetup' -NotePropertyValue $HasOtherHASetup;
                    $sqlInfo | Add-Member -NotePropertyName 'HARole' -NotePropertyValue $HARole;
                    $sqlInfo | Add-Member -NotePropertyName 'HAPartner' -NotePropertyValue $HAPartner;
                    $sqlInfo | Add-Member -NotePropertyName 'IsPowershellLinked' -NotePropertyValue 1;
                    $sqlInfo | Add-Member -NotePropertyName 'IsDecom' -NotePropertyValue 0;
                    $sqlInfo | Add-Member -NotePropertyName 'DecomDate' -NotePropertyValue $null;
                    $sqlInfo | Add-Member -NotePropertyName 'CollectionDate' -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss");
                    $sqlInfo | Add-Member -NotePropertyName 'CollectedBy' -NotePropertyValue $CollectedBy;
                    $sqlInfo | Add-Member -NotePropertyName 'UpdatedDate' -NotePropertyValue $null;
                    $sqlInfo | Add-Member -NotePropertyName 'UpdatedBy' -NotePropertyValue $null;
                    $sqlInfo | Add-Member -NotePropertyName 'Remark1' -NotePropertyValue $Remark1;
                    $sqlInfo | Add-Member -NotePropertyName 'Remark2' -NotePropertyValue $Remark2;

                    if($Global:PrintUserFriendlyMessage) {
                        Write-Host "Showing data of `$sqlInfo:" -ForegroundColor Yellow;
                        $sqlInfo
                    }

                    $sqlInstances += ($sqlInfo | Where-Object {$_.InstanceName -eq $inst});
                    $AddSwitch = $true;
                }
            }
            catch 
            {
                $returnMessage = $null;
                $formatstring = "{0} : {1}`n{2}`n" +
                            "    + CategoryInfo          : {3}`n" +
                            "    + FullyQualifiedErrorId : {4}`n"
                $fields = $_.InvocationInfo.MyCommand.Name,
                          $_.ErrorDetails.Message,
                          $_.InvocationInfo.PositionMessage,
                          $_.CategoryInfo.ToString(),
                          $_.FullyQualifiedErrorId

                $returnMessage = $formatstring -f $fields;

                $returnMessage = @"

$ErrorText
$($_.Exception.Message)


"@ + $returnMessage;
                if($LogErrorToInventoryTable) {
                    Add-CollectionError -ComputerName $FQDN `
                                        -Cmdlet 'Add-SqlInstanceInfo' `
                                        -CommandText "Error occurred while running sql $sqlQuery" `
                                        -ErrorText $returnMessage;
                } 
                if ($Global:PrintUserFriendlyMessage) {
                    Write-Host $returnMessage -ForegroundColor Red;
                }
            }
        }
    }

    # If every condition is valid to add server
    if ($AddSwitch) 
    {
        <#
        $sqlInstanceInfo = $sqlInstances | Select-Object FQN, ServerName, InstanceName, InstallDataDirectory, Version, 
                                                        Edition, ProductKey, IsClustered, IsCaseSensitive, IsHadrEnabled, 
                                                        IsDecommissioned, IsPowerShellLinked, 
                                                        @{l='CollectionTime';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}};
        #>
        $sqlInstanceInfo = $sqlInstances

        if($Global:PrintUserFriendlyMessage) {
            Write-Host "Adding instances from server $ServerName to Inventory." -ForegroundColor Cyan;  
        }
             
        try
        {
            $dtable = $sqlInstanceInfo | Out-DataTable;

            if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
            {
                Write-Host "VERBOSE: Showing data from `$dtable : " -ForegroundColor Yellow;
                $dtable | fl;
                $dtable | gm -MemberType Property
            }
            $sqlInstanceInfo | Write-DbaDataTable -SqlInstance $InventoryInstance -Database $InventoryDatabase -Schema 'Staging' -Table 'InstanceInfo';
            <#
            $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
            $cn.Open();

            $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
            $bc.DestinationTableName = "Staging.InstanceInfo";
            $bc.WriteToServer($dtable);
            $cn.Close();

            #>
            Write-Host "Details for instances from $ServerName saved in Staging tables" -ForegroundColor Green;
        }
        catch 
        {
            $returnMessage = $null;
            $formatstring = "{0} : {1}`n{2}`n" +
                        "    + CategoryInfo          : {3}`n" +
                        "    + FullyQualifiedErrorId : {4}`n"
            $fields = $_.InvocationInfo.MyCommand.Name,
                        $_.ErrorDetails.Message,
                        $_.InvocationInfo.PositionMessage,
                        $_.CategoryInfo.ToString(),
                        $_.FullyQualifiedErrorId

            $returnMessage = $formatstring -f $fields;

            $returnMessage = @"

$ErrorText
$($_.Exception.Message)


"@ + $returnMessage;
            if($LogErrorToInventoryTable) {
                Add-CollectionError -ComputerName $ServerName `
                                    -Cmdlet 'Add-SqlInstanceInfo' `
                                    -CommandText "SqlBulkCopy failed to write data into Staging.SqlInstanceInfo" `
                                    -ErrorText $returnMessage;
            } 
            if ($Global:PrintUserFriendlyMessage) {
                Write-Host $returnMessage -ForegroundColor Red;
            }
        }
        
            
        # Populate Main table from Staging
        $sqlQuery = @"
    EXEC [Staging].[usp_ETL_SqlInstanceInfo];
"@;
        if ($CallTSQLProcedure -eq 'Yes') 
        {
            Write-Verbose "Calling TSQL Procedure to move SQL Instance Info from Stage to Main tables..";
            Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery;
            Write-Verbose "SQL Instance Details for server $ServerName moved from Staging table to main table.";
        }
    }
}

#Add-SqlInstanceInfo -ServerName $env:COMPUTERNAME;
