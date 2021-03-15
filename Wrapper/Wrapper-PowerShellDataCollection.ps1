Import-Module SQLDBATools -DisableNameChecking;

#Set-Variable -Name InventoryInstance -Value 'BAN-1ADWIVEDI-L' -Scope Global;
#Set-Variable -Name InventoryDatabase -Value 'DBServers_master' -Scope Global;

#$InventoryInstance = 'BAN-1ADWIVEDI-L';
#$InventoryDatabase = 'DBServers_master';

$instancesquery ="select [Server/Instance Name] as InstanceName from [dbo].[Production]";
$instances = Invoke-Sqlcmd -Query $instancesquery -ServerInstance $InventoryInstance -Database $InventoryDatabase #-ConnectionTimeout 0 -QueryTimeout 0
$servers = @($instances | select -ExpandProperty InstanceName);

#$servers = @($env:COMPUTERNAME);

#$servers
#cd C:\temp\Collect-DatabaseBackupInfo;
#Remove-Item "c:\temp\PowerShellDataCollection\Collect-DatabaseBackupInfo.txt" -ErrorAction Ignore;

Push-Location;

$stime = Get-Date;
Set-Location 'C:\Users\adwivedi\Documents\WindowsPowerShell\Modules\SQLDBATools';
Run-CommandMultiThreaded `
    -MaxThreads 3 `
    -Command Collect-DatabaseBackupInfo `
    -ObjectList ($servers) `
    -InputParam SQLInstance -Verbose

$etime = Get-Date

$timeDiff = New-TimeSpan -Start $stime -End $etime ;
write-host $timeDiff;

Pop-Location;