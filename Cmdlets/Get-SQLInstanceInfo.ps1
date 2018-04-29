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
        [String[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory=$false)]
        [Switch]$LogErrorInInventory
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
        foreach($machine in $ComputerName)
        {
            # Reset with each loop
            $Discover = $true;
            Write-Host "Starting:- Searching for instances on $machine" -ForegroundColor Yellow;

            if ([String]::IsNullOrEmpty($machine) -or (Test-Connection -ComputerName $machine -Count 1 -Quiet) -eq $false)
            {
                $MessageText = "(Get-SQLInstanceInfo)=> Supplied value '$machine' for ComputerName parameter is invalid, or server is not accessible.";
                Write-Host $MessageText -ForegroundColor Red;
                Continue;
            }
            else
            {
                $fqn = (Get-FullQualifiedDomainName -ComputerName $machine);
                if([String]::IsNullOrEmpty($machine)) 
                {
                    Write-Host "(Get-FullQualifiedDomainName)=> Server '$machine' is not reachable." -ForegroundColor Red;
                    Continue;
                }
            }

            $instances = @(Get-ChildItem SQLSERVER:\SQL\$fqn | Select-Object -ExpandProperty PSChildName);
            if($instances.Count -eq 0)
            {
                $MessageText = "(SQLPSProvider Error)=> Get-ChildItem SQLSERVER:\SQL\$fqn  could not fetch details.";
                Write-Host $MessageText -ForegroundColor Red;
                if($LogErrorInInventory) {
                    Add-CollectionError -ComputerName $fqn -Cmdlet 'Get-SQLInstanceInfo' -CommandText "Get-SQLInstanceInfo -ComputerName '$fqn'" -ErrorText $MessageText -Remark $null;
                }
                Continue;
            }

            $KeysForAllInstances = Get-SqlServerProductKeys -Servers $fqn | Select-Object @{l='SQLInstance';e={$_.'SQL Instance'}}, @{l='ProductKey';e={$_.'Product Key'}};
            if($KeysForAllInstances.Count -eq 0)
            {
                $MessageText = "(Get-SqlServerProductKeys)=> Get-SqlServerProductKeys -Servers $fqn  could not fetch details.";
                Write-Host $MessageText -ForegroundColor Red;
            }

            if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
            {
                Write-Host "VERBOSE: Instance(s) for machine $machine :- $($instances -join ', ')" -ForegroundColor Cyan;
            }

            # Loop through each instance of $machine
            foreach($instance in $instances)
            {
                # If Instance name is DEFAULT, then take machine name, else Append
                if ($instance -eq "DEFAULT")
                { $sqlInstance = $fqn }
                else { 
                    $sqlInstance = $fqn + "\" + $instance 
                }

                Write-Host "  Fetching details for instance '$sqlInstance'" -ForegroundColor Yellow;

                    # Create server object using SMO
                    $Server = New-Object Microsoft.SqlServer.Management.Smo.Server($sqlInstance);
                    $productKey = ($KeysForAllInstances | Where-Object {$_.SQLInstance -eq $sqlInstance}).ProductKey;

                    # If Instance name is DEFAULT, then take machine name, else Append
                    if ($instance -eq "DEFAULT")
                    { $sqlInstance = $fqn.Split(".")[0] }
                    else { 
                        $sqlInstance = $fqn.Split(".")[0] + "\" + $instance 
                    }

                    if([String]::IsNullOrEmpty($Server.Edition)) 
                    {
                        $MessageText = "(SMO Error)=> New-Object Microsoft.SqlServer.Management.Smo.Server($sqlInstance)  could not fetch details.";
                        Write-Host $MessageText -ForegroundColor Red;
                        if($LogErrorInInventory) {
                            Add-CollectionError -ComputerName $fqn -Cmdlet 'Get-SQLInstanceInfo' -CommandText "Get-SQLInstanceInfo -ComputerName '$fqn'" -ErrorText $MessageText -Remark $null;
                        }
                        Continue;
                    }

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