$sqlQuery = @"
Corporate.Local
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
