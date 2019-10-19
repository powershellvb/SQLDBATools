Function Get-ServerInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        #[Alias('ServerName')]
        [String[]]$ServerName
    )

    BEGIN 
    {
        $Result = @();
    }
    PROCESS 
    {
        if ($_ -ne $null)
        {
            $ServerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }

        Write-Verbose "ServerName(s) passed: $($ServerName -join ', ')";
        foreach ($Svr in $ServerName)
        {
            # Switch to get ensure if ServerInfo is to be discovered
            $Discover = $true;
            if($PrintUserFriendlyMessage) {
                Write-Host "Finding details for `$Svr = '$Svr'." -ForegroundColor Yellow;
            }
            if ([String]::IsNullOrEmpty($Svr) -or (Test-Connection -ComputerName $Svr -Count 1 -Quiet) -eq $false)
            {
                Write-Host "Supplied value '$Svr' for ServerName parameter is invalid, or server is not accessible." -ForegroundColor Red;
                $Discover = $false;
            }
            else {
                $Svr = (Get-FullQualifiedDomainName -ComputerName $Svr);
                if([String]::IsNullOrEmpty($Svr)) {
                    Write-Host "$Svr  Server is not reachable." -ForegroundColor Red;
                    $Discover = $false;
                }
            }
            
            if($Discover)
            {
                # Find if Server is part of Failover Cluster
                Write-Verbose "Check ClusterInfo for server [$Svr]";
                $ClusterInfo = Get-ClusterInfo -ServerName $Svr;
                if(![String]::IsNullOrEmpty($ClusterInfo)) 
                {
                    $Servers = $ClusterInfo;
                    <#
                    $WSFC = ($ClusterInfo | Where-Object {$_.Role -eq 'WSFC'})[0].Name;
                    $Command = {
                        $ClusterName = $args[0];
                        $OwnerNode = (Get-ClusterGroup -Cluster $ClusterName | Where-Object {$_.IsCoreGroup -eq $false} | Get-ClusterResource | Where-Object {$_.ResourceType -eq 'Network Name'}).OwnerNode;
                        #Write-Output $OwnerNode.Name
                    }

                    $OwnerNode = Invoke-Command -ComputerName $WSFC -ScriptBlock $Command -ArgumentList $WSFC;
                    #>
                } else {
                    $InfoProp = $null;
                    $InfoProp = [Ordered]@{
                        'Name' = $Svr;
                        'Role' = 'StandaloneServer';
                        'OrderId' = 1;
                    }
                    $InfoPropObj = New-Object -TypeName PSObject -Property $InfoProp;
                    $Servers = $InfoPropObj;
                }

                $cs = $null;
                $os = $null;
                foreach($Machine in $Servers)
                {
                    $Comp = $Machine.Name;
                    $FQDN = (Get-FullQualifiedDomainName -ComputerName $Comp);
                    $IsStandaloneServer = 0;
                    $IsSqlClusterNode = 0;
                    $IsAgNode = 0;
                    $IsWSFC = 0;
                    $IsSqlCluster = 0;
                    $IsAG = 0;
                    if($Machine.Role -notin  ('SqlCluster','AG','StandaloneServer')) {
                        $ParentServerName = ($ClusterInfo | Where-Object {$_.Role -in ('SqlCluster','AG','StandaloneServer')})[0].Name;
                    }else{
                        $ParentServerName = $null;
                    }
                    
                    $Powerplan = (Get-PowerPlanInfo -ComputerName $Comp).Powerplan;

                    if($Machine.Role -eq 'StandaloneServer') {
                        $IsStandaloneServer = 1;
                    } elseif($Machine.Role -eq 'SqlClusterNode') {
                        $IsSqlClusterNode = 1
                    } elseif($Machine.Role -eq 'AgNode') {
                        $IsAgNode = 1
                    } elseif($Machine.Role -eq 'WSFC') {
                        $IsWSFC = 1
                    } elseif($Machine.Role -eq 'SqlCluster') {
                        $IsSqlCluster = 1
                    } elseif($Machine.Role -eq 'AG') {
                        $IsAG = 1
                    }


                    try 
                    {
                        $cs = Get-WmiObject -Class win32_computersystem -ComputerName $Comp -ErrorAction SilentlyContinue #| Select-Object Name, Domain, Model, totalphysicalmemory, NumberOfLogicalProcessors;
                        $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $Comp -ErrorAction SilentlyContinue #| Select-Object LastBootUpTime, Caption, CSDVersion;
                    }
                    catch {
                        $Discover = $false;
                        Write-Host "(Get-ServerInfo)=> Get-WmiObject : Access is denied. " -ForegroundColor Red;
                    }


                    #$bt = (Get-CimInstance -ClassName win32_operatingsystem  -ComputerName $comp -ErrorAction SilentlyContinue | select lastbootuptime);
            
                    if($Discover)
                    {
                        #IsVM, Manufacturer, Model
                        $mType = Get-MachineType -ComputerName $Comp;
                        if($mType.Type -eq 'Physical'){$IsVm = 0}else{$IsVm = 1};
                        $Manufacturer = $mType.Manufacturer;

                        if ($os.LastBootUpTime) 
                        {
                            $upTime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime);
                            $lastBoot = $os.ConvertToDateTime($os.LastBootUpTime);
                        }

                        $ping = New-Object System.Net.NetworkInformation.Ping;
                        $ips = $($ping.Send("$Comp").Address).IPAddressToString;
                        
                        $HostName = (Get-FullQualifiedDomainName -ComputerName $cs.Name);

                        $pServerName = if($FQDN  -match "^(?'ServerName'[0-9A-Za-z_-]+)\.*?.*"){$Matches['ServerName']}else{$null}
                        if($ips.Length -le 6 -and $pServerName -eq $env:COMPUTERNAME ) {
                            $ip = get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {![string]::IsNullOrEmpty($_.IPAddress)} | Select-Object -ExpandProperty IPAddress | Where-Object {$_.IndexOf('::') -eq -1}
                            $ips = if($ip -is [array]) {$ip[0]} else {$ip}
                        }

                        $Cpu = $cs.NumberOfLogicalProcessors;
                        if([string]::IsNullOrEmpty($Cpu)) {
                            $CPUInfo = Get-WmiObject Win32_Processor -ComputerName $Comp #Get CPU Information ;
                            $Cpu = $CPUInfo.Count ;
                        }

                        $RAM = $cs.totalphysicalmemory/1MB -AS [int];
                        if([string]::IsNullOrEmpty($RAM)) {
                            $RAM = Get-WmiObject CIM_PhysicalMemory -ComputerName $Comp | Measure-Object -Property capacity -Sum | % {[math]::round(($_.sum / 1MB),2)} 
                        }

                        $props = [Ordered]@{ 
                                    'ServerName' = $pServerName;
                                    'FQDN' = $FQDN;
                                    'IPAddress'= $ips;
                                    'Domain'=$cs.Domain;
                                    'IsStandaloneServer' = $IsStandaloneServer;
                                    'IsSqlClusterNode' = $IsSqlClusterNode;
                                    'IsAgNode' = $IsAgNode;
                                    'IsWSFC' = $IsWSFC;
                                    'IsSqlCluster' = $IsSqlCluster;
                                    'IsAG' = $IsAG;
                                    'ParentServerName' = $ParentServerName;
                                    'OS'=$os.Caption;
                                    'SPVersion'=$os.CSDVersion;
                                    'LastBootTime'= $lastBoot;
                                    'UpTime'= [String]$uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes" ;
                                    'IsVM' = $IsVm;
                                    'Manufacturer' = $Manufacturer;
                                    'Model'=$cs.Model;
                                    'RAM(MB)'=$RAM;
                                    'CPU'=$Cpu;
                                    'Powerplan' = $Powerplan;
                                    'OSArchitecture' = $os.OSArchitecture;
                                  }

                        $obj = New-Object -TypeName psobject -Property $props;
                        $Result += $obj;
                    }
                } # end foreach
            }
        }
    }
    END 
    {
        Write-Output $Result;
    }
<#
    .SYNOPSIS 
      Displays OS, Service Pack, LastBoot Time, Model, RAM & CPU for ServerName(s) passed in pipeline or as value.
    .DESCRIPTION
      Displays OS, Service Pack, LastBoot Time, Model, RAM & CPU for ServerName(s) passed in pipeline or as value.
    .PARAMETER  ServerName
      List of ServerName or machine names. This list can be passed either as ServerName or through pipeline.
    .EXAMPLE
      $servers = 'Server01','Server02';
      Get-ServerInfo $servers | ft -AutoSize;

      Ouput:-
ComputerName  OS                                           SPVersion      LastBootTime         UpTime                      Model                RAM(GB) CPU
------------  --                                           ---------      ------------         ------                      -----                ------- ---
Server01      Microsoft Windows Server 2012 Standard                      4/3/2018 11:15:44 PM 6 Days 6 Hours 30 Minutes   ProLiant DL380p Gen8      80  32
Server02      Microsoft Windows Server 2008 R2 Enterprise  Service Pack 1 3/22/2018 3:58:12 PM 18 Days 13 Hours 48 Minutes ProLiant DL380 G7        144  24

      
      Server names passed as parameter. Returns all the disk drives for computers Server01 & Server02.
    .EXAMPLE
      $servers = 'Server01','Server02';
      $servers | Get-ServerInfo | ft -AutoSize;

      Output:-
ComputerName  OS                                           SPVersion      LastBootTime         UpTime                      Model                RAM(GB) CPU
------------  --                                           ---------      ------------         ------                      -----                ------- ---
Server01      Microsoft Windows Server 2012 Standard                      4/3/2018 11:15:44 PM 6 Days 6 Hours 30 Minutes   ProLiant DL380p Gen8      80  32
Server02      Microsoft Windows Server 2008 R2 Enterprise  Service Pack 1 3/22/2018 3:58:12 PM 18 Days 13 Hours 48 Minutes ProLiant DL380 G7        144  24
      
      Server names passed through pipeline. Returns all the disk drives for computers Server01 & Server02.
    .LINK
      https://github.com/imajaydwivedi/SQLDBATools
#>
}