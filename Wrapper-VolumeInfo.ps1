$env:PSModulePath = $env:PSModulePath + ";" + "C:\Users\adwivedi\Documents\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules\;C:\Program Files\MVPSI\Modules\";

Import-Module SQLDBATools -DisableNameChecking;

$ExecutionLogsFile = "$SQLDBATools_ResultsDirectory\Logs\Get-VolumeInfo\___ExecutionLogs.txt";
if (!(Test-Path "$SQLDBATools_ResultsDirectory\Logs\Get-VolumeInfo")) {
    Write-Verbose "Path "+"$SQLDBATools_ResultsDirectory\Logs\Get-VolumeInfo does not exist. Creating it.";
    New-Item -ItemType "directory" -Path "$SQLDBATools_ResultsDirectory\Logs\Get-VolumeInfo";
}


$instancesquery = @"
select ServerName from [info].[Server];
--SELECT Name as InstanceName FROM [Info].[Instance] WHERE IsDecommissioned = 0
"@;

$machines = Execute-SqlQuery -Query $instancesquery -ServerInstance $InventoryInstance -Database $InventoryDatabase;
$servers = @($machines | select -ExpandProperty ServerName);


TRY {
    if (Test-Path $ExecutionLogsFile) {
        Remove-Item $ExecutionLogsFile;
    }

    "Following SQL Instances are processed in order:-
" | Out-File -Append $ExecutionLogsFile;

    $stime = Get-Date;
    Set-Location 'C:\Users\adwivedi\Documents\WindowsPowerShell\Modules\SQLDBATools';
    Run-CommandMultiThreaded `
        -MaxThreads 26 `
        -MaxResultTime 240 `
        -Command Collect-VolumeInfo `
        -ObjectList ($servers) `
        -InputParam ComputerName -Verbose

    $etime = Get-Date

    $timeDiff = New-TimeSpan -Start $stime -End $etime ;
    
    return 0;
}
CATCH {
    $ErrorMessage = $_.Exception.Message;
    $FailedItem = $_.Exception.ItemName;
    @"
Error occurred while running 
Wrapper-VolumeInfo
$ErrorMessage
"@ | Out-host;

     throw "Something went wrong";
     return 1;
}