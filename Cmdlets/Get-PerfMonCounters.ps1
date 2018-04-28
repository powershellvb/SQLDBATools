Function Get-PerfMonCounters
{
    [CmdletBinding()]
    Param(
        [Alias('ComputerName','MachineName')]
        [String[]]$ServerName = $env:COMPUTERNAME,
        [String]$InstanceName
    )
    
    # Loop through each Server provided in Parameter
    foreach( $srv in $ServerName)
    {
        Write-Host "Getting counters for server: $srv" -BackgroundColor Green;
        # If instance name is provided, then get counters for that instance, else fetch all instances
        if ($InstanceName.Length -eq 0)
        {
            Write-Host "No instance name provided. So will return counters for all instances.";
            $srvInstances = Get-ChildItem SQLSERVER:\SQL\$srv | Select-Object -ExpandProperty PSChildName;
        }
        else
        {
            $srvInstances = $InstanceName;
        }

        # Loop through each instance selected
        foreach( $inst in $srvInstances)
        {
            Write-Host "    Getting counters for instance: $inst" -BackgroundColor Gray;
            if ($inst -eq 'DEFAULT') 
            {
                # Get counters for DEFAULT instance
                $counterPrefix = 'SQLServer:'
            }
            else 
            {
                # Get Counters for Named instance
                $counterPrefix = "MSSQL`$$($inst):"
                #Get-Counter -ComputerName $srv -ListSet "MSSQL`$$($inst):*" | Select-Object CounterSetName, Paths | ft -AutoSize
            }

            # Prepare list of PerfMon Counters
            $counterList = @(
                # counters to Analyze Memory Pressure
                "\Memory\Available MBytes",#
                "\Memory\Pages/sec",#
                "\Memory\Page Faults/sec",#
                "\Memory\Pages Input/sec",#
                "\Memory\Pages Output/sec",#
                "\Paging File(_Total)\% Usage",
                "\Paging File(_Total)\% Usage Peak",
                "\$($counterPrefix)Buffer Manager\Buffer cache hit ratio",#
                "\$($counterPrefix)Buffer Manager\Page Life Expectancy",#
                "\$($counterPrefix)Buffer Manager\Checkpoint Pages/sec",#
                "\$($counterPrefix)Buffer Manager\Lazy writes/sec",#
                "\$($counterPrefix)Memory Manager\Memory Grants Pending",#
                "\$($counterPrefix)Memory Manager\Target Server memory (KB)",#
                "\$($counterPrefix)Memory Manager\Total Server Memory (KB)" ,#
                "\Process(sqlservr)\Private Bytes",

                # counters to Disk IO
                "\PhysicalDisk(*)\% Disk Time",
                "\PhysicalDisk(*)\Avg. Disk Queue Length",
                "\PhysicalDisk(*)\Avg. Disk sec/Read",
                "\PhysicalDisk(*)\Avg. Disk sec/Write",
                "\PhysicalDisk(*)\Current Disk Queue Length",
                "\PhysicalDisk(*)\Disk Bytes/sec",
                "\PhysicalDisk(*)\Disk Transfers/sec",
                
                # counters to Analyze Processor
                "\Processor(_Total)\% Privileged Time",
                "\Processor(_Total)\% Processor Time",
                "\$($counterPrefix)SQL Statistics\Batch Requests/sec",
                "\$($counterPrefix)SQL Statistics\SQL Compilations/sec",
                "\$($counterPrefix)SQL Statistics\SQL Re-Compilations/sec",
                "\System\Context Switches/sec",
                "\System\Processor Queue Length"

                # counters to Analyze Network

            );

            #Write-Host "Selected counters are: $counterList";
            
            $counterResult = Get-Counter -SampleInterval 5 -MaxSamples 3 -Counter $counterList;
            foreach( $counter in $counterResult )
            {
                $counterData += $counter.CounterSamples
            }
        } # End loop for instances
    } # End loop for Servers
    
    # Show the result as Table
    $counterData | Format-Table TimeStamp, Path, InstanceName, CookedValue -AutoSize -Wrap;
}