Function Add-CollectionError
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [Alias('ServerName','MachineName')]
        [String]$ComputerName,
	
        [Parameter(Mandatory=$true)]
        [Alias('Function')]
        [String]$Cmdlet,

	    [Parameter(Mandatory=$false)]
        [Alias('Command')]
        [String]$CommandText,

	    [Parameter(Mandatory=$true)]
        [String]$ErrorText,

	    [Parameter(Mandatory=$false)]
        [Alias('OtherInfo')]
        [String]$Remark
    )

    #Add switch
    $AddSwitch = $true;
    if([String]::IsNullOrEmpty($Remark)) 
    {
        $Remark = @"
Caller ServerName:- $($env:COMPUTERNAME).
Caller UserName:- $([Environment]::UserDomainName + "\" + [Environment]::UserName).

"@;
    }
    else
    {
        $Remark = @"
Caller ServerName:- $($env:COMPUTERNAME).
Caller UserName:- $([Environment]::UserDomainName + "\" + [Environment]::UserName).

"@ + $Remark;
    }

    # Check $AddSwitch value
    if($AddSwitch)
    {
        $CollectionTime = [DateTime]((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"));

        $props = [Ordered]@{
                    'ServerName' = $ComputerName;
                    'Cmdlet' = $Cmdlet;
                    'Command' = $CommandText;
                    'Error' = $ErrorText;
                    'Remark' = $Remark;
                    'CollectionTime' = $CollectionTime;
                }

        $obj = New-Object -TypeName psobject -Property $props;

        try
        {
            $dtable = $obj | Out-DataTable;
        
            $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
            $cn.Open();

            $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
            $bc.DestinationTableName = "$InventoryErrorLogsTable";
            $bc.WriteToServer($dtable);
            $cn.Close();

            Write-Host "Added Entry into Error Logs table [$InventoryInstance].[$InventoryDatabase].$InventoryErrorLogsTable" -ForegroundColor Yellow;
        }
        catch
        {
            Write-Host "Error occurred while adding Error Logs entry in table [$InventoryInstance].[$InventoryDatabase].$InventoryErrorLogsTable" -ForegroundColor Red;
        }             
    }
}

# Add-CollectionError -ComputerName $env:COMPUTERNAME -Cmdlet 'Add-ServerInfo' -CommandText "Add-ServerInfo -ComputerName $($env:COMPUTERNAME)" -ErrorText 'Access Denied' -Remark 'Dummy'