$env:PSModulePath = $env:PSModulePath + ";" + "C:\Users\adwivedi\Documents\WindowsPowerShell\Modules;C:\Windows\system32\WindowsPowerShell\v1.0\Modules\;C:\Program Files\MVPSI\Modules\";

Import-Module SQLDBATools -DisableNameChecking;
#Import-Module dbatools -DisableNameChecking;

$ExecutionLogsFile = "$SQLDBATools_ResultsDirectory\Logs\Get-AlwaysOnIssues\___ExecutionLogs.txt";
#New-Item $ExecutionLogsFile -Force

$instancesquery ="SELECT ListenerName FROM Info.AlwaysOnListener";
$instances = Execute-SqlQuery -Query $instancesquery -ServerInstance $InventoryInstance -Database $InventoryDatabase #-ConnectionTimeout 0 -QueryTimeout 0

$servers = @($instances | select -ExpandProperty ListenerName);

$replicaHealthQuery = @"
SELECT	cl.cluster_name
		,ag.dns_name as ag_Listener
		,ar.replica_server_name
		,ars.role_desc
		,ar.failover_mode_desc
		,ars.synchronization_health_desc
		,ars.operational_state_desc
		,CASE ars.connected_state
			WHEN 0
				THEN 'Disconnected'
			WHEN 1
				THEN 'Connected'
			ELSE ''
			END AS ConnectionState
        ,getdate() as CollectionTime
FROM sys.dm_hadr_availability_replica_states ars
INNER JOIN sys.availability_replicas ar ON ars.replica_id = ar.replica_id
	AND ars.group_id = ar.group_id
CROSS JOIN
	sys.dm_hadr_cluster AS cl
CROSS JOIN
	sys.availability_group_listeners AS ag
"@;

TRY {
    if (Test-Path $ExecutionLogsFile) {
        Remove-Item $ExecutionLogsFile;
    }

    "Following SQL Instances are processed in order:-
" | Out-File -Append $ExecutionLogsFile;

    #Set-Location 'C:\Users\adwivedi\Documents\WindowsPowerShell\Modules\SQLDBATools';
    $Result = @();
    foreach($AOServer in $servers)
    {
        $rs = Invoke-Sqlcmd -Query $replicaHealthQuery -ServerInstance $AOServer -Database master;
        $Result += $rs;
    }
    
    
    $dtable = $Result #| Out-DataTable;    
        
    $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
    $cn.Open();

    $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
    $bc.DestinationTableName = "Staging.AOReplicaInfo";
    $bc.WriteToServer($dtable);
    $cn.Close();
    
    
}
CATCH {
            $ErrorMessage = $_.Exception.Message;
            $FailedItem = $_.Exception.ItemName;
            $errorFile = "$SQLDBATools_ResultsDirectory\Logs\Get-AlwaysOnIssues\$AOServer.txt";

            # Create if Error Log path does not exist
            if (!(Test-Path "$SQLDBATools_ResultsDirectory\Logs\Get-AlwaysOnIssues")) {
                New-Item "$SQLDBATools_ResultsDirectory\Logs\Get-AlwaysOnIssues" -ItemType directory;
            }

            # Drop old error log file
            if (Test-Path $errorFile) {
                Remove-Item $errorFile;
            }

            # Output Error in file
            @"
Error occurred AO Listener $AOServer
$ErrorMessage
"@ | Out-File $errorFile;
            Write-Verbose "Error occurred in while trying to get Replica Info for AO Listener [$AOServer]. Kindly check logs at $errorFile";
}
