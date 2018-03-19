#$env:PSModulePath = $env:PSModulePath + ";" + "C:\Users\adwivedi\Documents\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules\;C:\Program Files\MVPSI\Modules\";

Import-Module SQLDBATools -DisableNameChecking;

$ExecutionLogsFile = "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo\___ExecutionLogs.txt";

$instancesquery ="SELECT Name as InstanceName FROM [dbo].[Instance] WHERE IsDecommissioned = 0 AND IsPowerShellLinked = 0";
$instances = Execute-SqlQuery -Query $instancesquery -ServerInstance $InventoryInstance -Database $InventoryDatabase;
$servers = @($instances | select -ExpandProperty InstanceName);

if (Test-Path $ExecutionLogsFile) {
        Remove-Item $ExecutionLogsFile;
}

    "Following SQL Instances are processed in order:-
" | Out-File -Append $ExecutionLogsFile;

    $stime = Get-Date;
    Set-Location 'C:\Users\adwivedi\Documents\WindowsPowerShell\Modules\SQLDBATools';
    <#
    Run-CommandMultiThreaded `
        -MaxThreads 26 `
        #-MaxResultTime 120 `
        -Command Collect-DatabaseBackupInfo `
        -ObjectList ($servers) `
        -InputParam SQLInstance -Verbose
    #>
    foreach($SQLInstance in $servers)
    {
         # Making entry into General Logs File
        "$SQLInstance " | Out-File -Append $ExecutionLogsFile;

        TRY {
            Collect-DatabaseBackupInfo -SQLInstance $SQLInstance;
        }
        CATCH {
             throw "Something went wrong";
             return 1;
        }
    }

    $etime = Get-Date

    $timeDiff = New-TimeSpan -Start $stime -End $etime ;
    
    
