$sqlQuery = @"
SELECT s.FQDN
FROM Info.Server as s
OUTER APPLY
	( SELECT COUNT(i.InstanceName) AS InstanceCounts FROM info.Instance as i WHERE i.FQDN = s.FQDN) as i
where InstanceCounts = 0
"@;

$Servers = @(Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery | Select-Object -ExpandProperty FQDN);

foreach($computerName in $Servers)
{
    #Get-ServerInfo -ComputerName $computerName;
    #Add-ServerInfo -ComputerName $computerName -CallTSQLProcedure No -EnvironmentType Prod
    #Get-ServerInfo -ComputerName $computerName
    Add-SQLInstanceInfo -ComputerName $computerName;
}

#Get-SQLInstanceInfo TRISTAR.corporate.local