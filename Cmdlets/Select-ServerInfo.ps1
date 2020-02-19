Function Select-ServerInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName','MachineName','SqlInstance')]
        [String]$ServerName
    )

    #$fqdn = Get-FullQualifiedDomainName -ComputerName $ComputerName;

    $sqlQuery = @"
if exists (select * from dbo.Server where ServerName = '$ServerName')
	select s.ServerID, s.ServerName, s.EnvironmentType, s.FQDN, s.IPAddress, 
			s.Domain, s.OS, s.SPVersion, s.IsVM, s.Manufacturer, s.Model, s.RAM, 
			s.CPU, s.CollectionDate, s.GeneralDescription,
			i.InstanceID, i.InstanceName, i.RootDirectory, i.Version, i.Edition, i.ProductKey, 
			[ServerType] = case when i.IsStandaloneInstance = 1 then 'StandAlone'
								when i.AGListener = 1 then 'AGListener'
								when i.IsSQLCluster  = 1 then 'SqlCluster'
								when i.IsAGNode = 1 then 'AG Node'
								else 'NULL'
								end
			,s.ISDecom, i.IsPowershellLinked
	from dbo.Server as s
	left join
		dbo.Instance as i
		on s.ServerID = i.ServerID
	where s.ServerName = '$ServerName'
else
	select 'server not found in inventory' as output;
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