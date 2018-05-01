Function Fetch-ServerInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName','ServerInstance','SqlInstance')]
        [String]$ComputerName
    )

    $fqdn = Get-FullQualifiedDomainName -ComputerName $ComputerName;

    $sqlQuery = @"
select s.ServerID, s.ServerName, s.EnvironmentType, s.DNSHostName, s.FQDN, s.IPAddress, 
		s.Domain, s.OperatingSystem, s.SPVersion, s.IsVM, s.Manufacturer, s.Model, s.RAM, 
		s.CPU, s.CollectionTime, s.GeneralDescription,
		i.InstanceID, i.InstanceName, i.InstallDataDirectory, i.Version, i.Edition, i.ProductKey, 
		i.IsClustered, i.IsCaseSensitive, i.IsHadrEnabled, i.IsDecommissioned, i.IsPowerShellLinked
from Info.Server as s
left join
	Info.Instance as i
	on i.FQDN = s.FQDN
where s.FQDN = '$fqdn'
or i.InstanceName = '$ComputerName'
go
"@;

    try 
    {
        $qResult = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery -ErrorAction SilentlyContinue;
        $qResult | Write-Output;
    }
    catch 
    {
        Write-Host "Error($sqlInstance): Failure while executing SQL code from file $mailProfileTSQLScriptFile" -ForegroundColor Red;
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        @"

$FailedItem => 
    $ErrorMessage
====================================
"@
    }
     
}