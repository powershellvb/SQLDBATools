$env:PSModulePath = $env:PSModulePath + ";" + "C:\Users\adwivedi\Documents\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules\;C:\Program Files\MVPSI\Modules\";
Import-Module SQLDBATools -DisableNameChecking;

$tQuery = @"
    select InstanceName  from Info.Instance
"@;

$Servers = Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $tQuery | Select-Object -ExpandProperty InstanceName;

$Services = $Servers | Run-CommandMultiThreaded -Command "Get-Service" `
                            -InputParam 'ComputerName'

$Services | Where-Object {$_.Name -like '*sql*' } | Select-Object MachineName, Name, DisplayName, Status, StartType | ft -AutoSize