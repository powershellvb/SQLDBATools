<# 
Remove-Module SQLDBATools -ErrorAction SilentlyContinue;
Import-Module SQLDBATools -DisableNameChecking;
Get-Command -Module FailoverClusters
Import-Module FailoverClusters
#>

# https://www.mssqltips.com/sqlservertip/3154/monitor-a-sql-server-cluster-using-powershell/

# Fetch ServerInstances from Inventory
$tsqlInventory = @"
select I.FQDN, InstanceName from Info.Server as S inner join Info.Instance as I on I.ServerID = S.ServerID
"@;

$Servers = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $tsqlInventory;
$FailedServers = @();
$SuccessServers = @();
foreach($cn in $Servers)
{
    $ComputerName = $cn.FQDN;
    $ServerInstance = $cn.InstanceName;
    
    
    Test-WSMan -ComputerName ComputerName -ErrorAction SilentlyContinue -ErrorVariable ErrorTestWSMan | Out-Null;
    if($ErrorTestWSMan) {
        $FailedServers += (New-Object -TypeName psobject -Property @{'ComputerName' = $ComputerName});
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Database master -InputFile 'C:\temp\EnablePSRemoting.sql' -ErrorAction SilentlyContinue;
    } else {
        $SuccessServers += (New-Object -TypeName psobject -Property @{'ComputerName' = $ComputerName});
    }
    
}

$FailedServers | Out-GridView -Title "PSRemoting Failed Server";
$SuccessServers | Out-GridView -Title "PSRemoting Success Servers";

foreach($ComputerName in ($FailedServers|Select-Object -ExpandProperty ComputerName))
{
    
    <#
    $Remark = @"
1. https://www.howtogeek.com/117192/how-to-run-powershell-commands-on-remote-computers/
2. https://stackoverflow.com/questions/11330874/get-wmiobject-the-rpc-server-is-unavailable-exception-from-hresult-0x800706
netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes
"@;
    Add-CollectionError -ComputerName $ComputerName -Cmdlet 'Test-WSMan' -CommandText "Test-WSMan -ComputerName $ComputerName" -ErrorText "PSRemoting is disabled on server" -Remark $Remark;
    #>
}

<#
Get-ClusterNode -Name $ComputerName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Select-Object *;

# Get Clusters in Domain
$Clusters = Get-Cluster -Domain corporate.local | Select-Object -ExpandProperty Name;
$ClusterNodes = @();

foreach($ClusterName in $Clusters )
{
    $node = $null;
    try {
        $node = Get-ClusterNode -Cluster $ClusterName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
                    Select-Object @{l='FailoverClusterName';e={$ClusterName}}, @{l='ClusterNodeName';e={$_.Name}}, Id, State
    }
    catch {
        $eMessage = $_.Exception.Message;
        $eItem = $_.Exception.ItemName;
        $Message = @"
-----------------------------
($ClusterName) => 
ItemName => $eItem
ErrorMessage => $eMessage
-----------------------------
"@;
        Write-Host $Message -ForegroundColor Red;
        
    }
    $ClusterNodes += $node;
}

$ClusterNodes | ft -AutoSize

#>
