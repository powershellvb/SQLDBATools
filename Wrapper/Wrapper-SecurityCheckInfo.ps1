$env:PSModulePath = $env:PSModulePath + ";" + "C:\Program Files\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules\;C:\Program Files\MVPSI\Modules\";
Import-Module SQLDBATools -DisableNameChecking -Force;

# Fetch ServerInstances from Inventory
$tsqlInventory = @"
select InstanceName from Info.Instance
"@;

$ServerInstances = @(Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $tsqlInventory | 
                        Select-Object -ExpandProperty InstanceName);

#Run-CommandMultiThreaded -ObjectList $ServerInstances -Command "Collect-SecurityCheckInfo" -InputParam ServerInstance -MaxThreads 26;
$Result = Get-SecurityCheckInfo -ServerInstance $ServerInstances;
#$Result | ft -AutoSize

$dtable = $Result | Out-DataTable;    

$cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
$cn.Open();

$bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
$bc.DestinationTableName = "Staging.SecurityCheckInfo";
$bc.WriteToServer($dtable);
$cn.Close();