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

        [Parameter(Mandatory=$false)]
        [String]$ApplicationID = $null,

        [parameter(HelpMessage="Choose 'No' when adding multiple servers at same time")]
        [ValidateSet("Yes","No")]
        [String]$CallTSQLProcedure = "Yes",

        [parameter( Mandatory=$false)]
        [Switch]$AddSqlInstanceInfo = $false,

        [Parameter(Mandatory=$false)]
        [Alias('Description','Remark')]
        $GeneralDescription,

        [Parameter(Mandatory=$false)]
        [Switch]$UpdateInfo = $false

    )

    # Switch to validate if Server to be added in Inventory
    $AddSwitch = $false;

    if ([String]::IsNullOrEmpty($ComputerName) -or (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -eq $false)
    {
        $ErrorText = "Supplied value of '$ComputerName' for ComputerName parameter is invalid, or server is not accessible.";
        if($LogErrorToInventoryTable) {
            Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Add-ServerInfo' -CommandText "Add-ServerInfo -ComputerName '$ComputerName'" `
                                -ErrorText $ErrorText -Remark $null;
        } else {
            Write-Host $ErrorText -ForegroundColor Red;
        }

        Write-Output $null;
        return;
    }
    else 
    {
        $ComputerName = (Get-FullQualifiedDomainName -ComputerName $ComputerName);
        Write-Verbose "`$FQDN = $ComputerName";
        
        Write-Verbose "  Checking if '$ComputerName' is already present in Inventory";
        $sqlQuery = @"
select 1 as IsPresent from [$InventoryDatabase].[dbo].[Server] where FQDN = '$ComputerName'
"@;
        #Write-Host "$sqlQuery";
        $Tables = $null;
        try 
        {
            $Tables = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Query $sqlQuery -ErrorAction Stop;
               
            #if ( ($Tables -ne $null) -and ($UpdateInfo -and $false) ) {
            if ( ![string]::IsNullOrEmpty($Tables)) {
                Write-Host "Server $ComputerName already present in Inventory" -ForegroundColor Green;
                return;
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
    $AddSwitch = $true;
    if ($AddSwitch) 
    {
        # http://www.itprotoday.com/microsoft-sql-server/bulk-copy-data-sql-server-powershell
        Write-Verbose "  Calling Get-ServerInfo -ServerName $ComputerName";

        $serverInfo = Get-ServerInfo -ServerName $ComputerName | Select-Object @{l='ServerName';e={if($_.ServerName  -match "^(?'ServerName'[0-9A-Za-z_-]+)\.*?.*"){$Matches['ServerName']}else{$null}}}, @{l='ApplicationId';e={$ApplicationID}}, @{l='EnvironmentType';e={$EnvironmentType}}, FQDN, IPAddress, Domain, 
                        IsStandaloneServer, IsSqlClusterNode, IsAgNode, IsWSFC, IsSqlCluster, IsAG, 
                        ParentServerName, OS, SPVersion, IsVM, @{l='IsPhysical';e={if($_.IsVM -eq 1){0} else {1} }}, Manufacturer, Model, @{l='RAM';e={$_.'RAM(MB)'}}, CPU, 
                        Powerplan, OSArchitecture, @{l='ISDecom';e={0}}, @{l='DecomDate';e={$null}}, @{l='GeneralDescription';e={[String]$GeneralDescription}}, @{l='CollectionDate';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}}, 
                        @{l='CollectedBy';e={$([Environment]::UserDomainName + "\" + [Environment]::UserName)}}, @{l='UpdatedDate';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}}, 
                        @{l='UpdatedBy';e={$([Environment]::UserDomainName + "\" + [Environment]::UserName)}};

        if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) { $serverInfo | fl }
        if([String]::IsNullOrEmpty($serverInfo)) 
        {
            $MessageText = "Get-WmiObject : Access is denied. Failed in execution of Get-ServerInfo -ServerName $ComputerName";
            if($LogErrorToInventoryTable) {
                Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Add-ServerInfo' -CommandText "Add-ServerInfo -ComputerName '$ComputerName'" `
                                    -ErrorText $MessageText -Remark $null;

            } else {
                Write-Verbose $MessageText;
            }
            
            return;
        }
            
        foreach ($i in $serverInfo)
        {
            
            try 
            {
                if ($AddSwitch) 
                {
                    Write-Host "Adding server $ComputerName to Inventory";
                
                    #$dtable = $i | Out-DataTable;
                    
                    if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
                    {
                        Write-Host "VERBOSE: Showing data from `$dtable : " -ForegroundColor Yellow;
                        $i | fl;
                    } 
                    $i | Write-DbaDataTable -SqlInstance $InventoryInstance -Database $InventoryDatabase -Schema 'Staging' -Table 'ServerInfo';
                    <#
                    $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
                    $cn.Open();

                    $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
                    $bc.DestinationTableName = "Staging.ServerInfo";
                    $bc.WriteToServer($dtable);
                    $cn.Close();
                    #>

                    Write-Verbose "Details for server $ComputerName saved in Staging tables";
                }
            }
            catch 
            {
                $formatstring = "{0} : {1}`n{2}`n" +
                            "    + CategoryInfo          : {3}`n" +
                            "    + FullyQualifiedErrorId : {4}`n"
                $fields = $_.InvocationInfo.MyCommand.Name,
                          $_.ErrorDetails.Message,
                          $_.InvocationInfo.PositionMessage,
                          $_.CategoryInfo.ToString(),
                          $_.FullyQualifiedErrorId

                $returnMessage = $formatstring -f $fields;

                if($LogErrorToInventoryTable) {
                    Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Add-ServerInfo' -CommandText "Add-ServerInfo -ComputerName '$ComputerName'" `
                                        -ErrorText $returnMessage -Remark $null;

                } else {
                    Write-Verbose $returnMessage;
                }

                <#
                "Error occurred while writing ServerInfo into Staging table" | Write-Host -ForegroundColor Red;
                Write-Host ($returnMessage) -ForegroundColor Red;

                $ErrorMessage = $_.Exception.Message;
                $FailedItem = $_.Exception.ItemName;

                # Output Error in file
                @"
    Error occurred while running 
    Add-ServerInfo -ComputerName $ComputerName -Verbose
    $returnMessage
"@ | Out-Host;
                #>
                Write-Host "Error occurred in while trying to get Add-ServerInfo for server [$ComputerName].";
                return
            }
        }

        # Populate Main table from Staging
        $sqlQuery = @"
    EXEC [Staging].[usp_ETL_ServerInfo];
"@;
        if ($CallTSQLProcedure -eq 'Yes') 
        {
            try {
                Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery;
                Write-Verbose "Details for server $ComputerName moved from Staging table to main table.";
            }
            catch {
                $formatstring = "{0} : {1}`n{2}`n" +
                            "    + CategoryInfo          : {3}`n" +
                            "    + FullyQualifiedErrorId : {4}`n"
                $fields = $_.InvocationInfo.MyCommand.Name,
                          $_.ErrorDetails.Message,
                          $_.InvocationInfo.PositionMessage,
                          $_.CategoryInfo.ToString(),
                          $_.FullyQualifiedErrorId

                $returnMessage = $formatstring -f $fields;

                if($LogErrorToInventoryTable) {
                    Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Add-ServerInfo' -CommandText "Add-ServerInfo -ComputerName '$ComputerName'" `
                                        -ErrorText $returnMessage -Remark $null;

                } else {
                    Write-Verbose $returnMessage;
                }
            }
        }
    }

    # Add SQL Instances
    if($AddSqlInstanceInfo)
    {
        Add-SqlInstanceInfo -ComputerName $ComputerName -CallTSQLProcedure Yes;
    }
<#
    .SYNOPSIS 
      Displays OS, Service Pack, LastBoot Time, Model, RAM & CPU for computer(s) passed in pipeline or as value.
    .DESCRIPTION
      Displays OS, Service Pack, LastBoot Time, Model, RAM & CPU for computer(s) passed in pipeline or as value.
    .PARAMETER  ComputerName
      List of computer or machine names. This list can be passed either as computer name or through pipeline.
    .EXAMPLE
      $servers = 'Server01','Server02';
      Get-ServerInfo $servers | ft -AutoSize;

      Ouput:-
ComputerName  OS                                           SPVersion      LastBootTime         UpTime                      Model                RAM(GB) CPU
------------  --                                           ---------      ------------         ------                      -----                ------- ---
Server01      Microsoft Windows Server 2012 Standard                      4/3/2018 11:15:44 PM 6 Days 6 Hours 30 Minutes   ProLiant DL380p Gen8      80  32
Server02      Microsoft Windows Server 2008 R2 Enterprise  Service Pack 1 3/22/2018 3:58:12 PM 18 Days 13 Hours 48 Minutes ProLiant DL380 G7        144  24

      
      Server names passed as parameter. Returns all the disk drives for computers Server01 & Server02.
    .EXAMPLE
      $servers = 'Server01','Server02';
      $servers | Get-ServerInfo | ft -AutoSize;

      Output:-
ComputerName  OS                                           SPVersion      LastBootTime         UpTime                      Model                RAM(GB) CPU
------------  --                                           ---------      ------------         ------                      -----                ------- ---
Server01      Microsoft Windows Server 2012 Standard                      4/3/2018 11:15:44 PM 6 Days 6 Hours 30 Minutes   ProLiant DL380p Gen8      80  32
Server02      Microsoft Windows Server 2008 R2 Enterprise  Service Pack 1 3/22/2018 3:58:12 PM 18 Days 13 Hours 48 Minutes ProLiant DL380 G7        144  24
      
      Server names passed through pipeline. Returns all the disk drives for computers Server01 & Server02.
    .LINK
      https://github.com/imajaydwivedi/SQLDBATools
  #>
}


