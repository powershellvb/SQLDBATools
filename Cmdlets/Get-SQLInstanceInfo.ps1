Function Get-SQLInstanceInfo
{
    <#
        .SYNOPSIS
            Retrieves SQL Server instance general information.

        .DESCRIPTION
            Retrieves SQL Server instance general information based on ComputerName parameter value.

        .NOTES
            Name: Discover-SQLInstances
            Author: Ajay Dwivedi

        .EXAMPLE
            Get-SQLInstanceInfo -ComputerName $env:COMPUTERNAME

            Description
            -----------
            Retrieves SQL Server instance general information based on ComputerName parameter value.

        .LINK
            https://www.mssqltips.com/sqlservertip/2013/find-sql-server-instances-across-your-network-using-windows-powershell/
    #>

    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName')]
        [String[]]$ComputerName = $env:COMPUTERNAME
    )
    BEGIN 
    {
        $Check = $false;
        $Result = @();
        $instances = @();
    }
    PROCESS
    {
        # Loop through each machines
        Write-Verbose "Looping through `$ComputerName '$($ComputerName -join ', ')'";
        foreach($machine in $ComputerName)
        {
            $fqn = (Get-FullQualifiedDomainName -ComputerName $machine);
            $instances = @(Get-ChildItem SQLSERVER:\SQL\$machine | Select-Object -ExpandProperty PSChildName);
            $KeysForAllInstances = Get-SqlServerProductKeys -Servers $machine | Select-Object @{l='SQLInstance';e={$_.'SQL Instance'}}, @{l='ProductKey';e={$_.'Product Key'}};

            if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
            {
                Write-Host "VERBOSE: Instance(s) for machine $machine :- $($instances -join ', ')" -ForegroundColor Cyan;
            }
            # Loop through each instance of $machine
            foreach($instance in $instances)
            {
                # If Instance name is DEFAULT, then take machine name, else Append
                if ($instance -eq "DEFAULT")
                { $sqlInstance = $machine }
                else
                { 
                    $sqlInstance = $machine + "\" + $instance }

                    # Create server object using SMO
                    $Server = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlInstance);
                    $productKey = ($KeysForAllInstances | Where-Object {$_.SQLInstance -eq $sqlInstance}).ProductKey;

                    $genInfo = $Server | Select-Object @{l='FQN';e={$fqn}},
                                                        @{l='ServerName';e={$machine}},
                                                        @{l='SQLInstance';e={$sqlInstance}},
                                                        @{l='InstanceName';e={$instance}},
                                                        @{l='ClusterName';e={if([String]::IsNullOrEmpty($ClusterName)) {$null}else{$_.ClusterName}}}, 
                                                        Edition, InstallDataDirectory, Version, 
                                                        @{l='IsClustered';e={if($_.IsClustered -eq $true){1}else{0}}}, 
                                                        @{l='IsCaseSensitive';e={if($_.IsCaseSensitive -eq $true){1}else{0}}},
                                                        @{l='IsHadrEnabled';e={if([String]::IsNullOrEmpty($_.IsHadrEnabled)){0}else{1}}};

                    $props = [Ordered]@{
                                    'FQN' = $genInfo.FQN;
                                    'ServerName' = $genInfo.ServerName;
                                    #'NetworkName' = $genInfo.SQLInstance;
                                    'InstanceName' = $genInfo.SQLInstance;
                                    #'BaseName' = $genInfo.InstanceName;
                                    #'ClusterName' = $genInfo.ClusterName;
                                    'InstallDataDirectory' = $genInfo.InstallDataDirectory;
                                    'Version' = $genInfo.Version;
                                    'Edition' = $genInfo.Edition;
                                    'ProductKey' = $productKey;
                                    'IsClustered' = $genInfo.IsClustered;
                                    'IsCaseSensitive' = $genInfo.IsCaseSensitive;
                                    'IsHadrEnabled' = $genInfo.IsHadrEnabled;
                                    'IsDecommissioned' = 0;
                                    'IsPowerShellLinked' = 1;
                                }

                    $obj = New-Object -TypeName psobject -Property $props;
                    $Result += $obj;
            }
        }
    }
    END
    {
        Write-Output $Result;
    }
}

#Get-SQLInstanceInfo -ComputerName $env:COMPUTERNAME