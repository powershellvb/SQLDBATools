Function Get-ServerInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName')]
        [String[]]$ComputerName

        <#
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
        #>
    )

    BEGIN 
    {
        $Result = @();
    }
    PROCESS 
    {
        if ($_ -ne $null)
        {
            $ComputerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }

        Write-Verbose "ServerName(s) passed: $($ComputerName -join ', ')";
        foreach ($Comp in $ComputerName)
        {
            # Switch to get ensure if ServerInfo is to be discovered
            $Discover = $true;

            Write-Host "Finding details for `$Comp = '$Comp'." -ForegroundColor Yellow;
            if ([String]::IsNullOrEmpty($Comp) -or (Test-Connection -ComputerName $Comp -Count 1 -Quiet) -eq $false)
            {
                Write-Host "Supplied value '$Comp' for ComputerName parameter is invalid, or server is not accessible." -ForegroundColor Red;
                $Discover = $false;
            }
            else {
                $Comp = (Get-FullQualifiedDomainName -ComputerName $Comp);
                if([String]::IsNullOrEmpty($Comp)) {
                    Write-Host "  Server is not reachable." -ForegroundColor Red;
                    $Discover = $false;
                }
            }
            
            if($Discover)
            {
                try 
                {
                    $cs = Get-WmiObject -Class win32_computersystem -ComputerName $comp -ErrorAction SilentlyContinue |
                                Select-Object Name, Domain, Model, totalphysicalmemory, NumberOfLogicalProcessors;
                    $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $comp -ErrorAction SilentlyContinue |
                                Select-Object LastBootUpTime, Caption, CSDVersion;
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


                    $props = [Ordered]@{ 'ComputerName'=$comp;
                                'FQN' = $Comp;
                                'HostName'=$HostName;
                                'IPAddress'= $ips;
                                'Domain'=$cs.Domain;
                                'OS'=$os.Caption;
                                'SPVersion'=$os.CSDVersion;
                                'LastBootTime'=$lastBoot;
                                'UpTime'= [String]$uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes" ;
                                'IsVM' = $IsVm;
                                'Manufacturer' = $Manufacturer;
                                'Model'=$cs.Model;
                                'RAM(MB)'=$cs.totalphysicalmemory/1MB -AS [int];
                                'CPU'=$cs.NumberOfLogicalProcessors;
                              }

                    $obj = New-Object -TypeName psobject -Property $props;
                    $Result += $obj;

                    # Check if the $ComputerName is virtual Name
                    if ($Comp -ne $HostName)
                    {
                        #IsVM, Manufacturer, Model
                        $mType = Get-MachineType -ComputerName $Comp;
                        if($mType.Type -eq 'Physical'){$IsVm = 0}else{$IsVm = 1};
                        $Manufacturer = $mType.Manufacturer;

                        $ping = New-Object System.Net.NetworkInformation.Ping;
                        $ips = $($ping.Send("$Comp").Address).IPAddressToString;

                        $props = [Ordered]@{ 'ComputerName'=$HostName;
                                            'FQN' = $HostName;
                                            'HostName'=$HostName;
                                            'IPAddress'= $ips;
                                            'Domain'=$cs.Domain;
                                            'OS'=$os.Caption;
                                            'SPVersion'=$os.CSDVersion;
                                            'LastBootTime'=$lastBoot;
                                            'UpTime'= [String]$uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes" ;
                                            'IsVM' = $IsVm;
                                            'Manufacturer' = $Manufacturer;
                                            'Model'=$cs.Model;
                                            'RAM(MB)'=$cs.totalphysicalmemory/1MB -AS [int];
                                            'CPU'=$cs.NumberOfLogicalProcessors;
                                          }

                        $obj = New-Object -TypeName psobject -Property $props;
                        $Result += $obj;
                    }
                }
            }
        }
    }
    END 
    {
        Write-Output $Result;
    }
<#
    .SYNOPSIS 
      Displays OS, Service Pack, LastBoot Time, Model, RAM & CPU for computer(s) passed in pipeline or as value.
    .DESCRIPTION
      Displays OS, Service Pack, LastBoot Time, Model, RAM & CPU for computer(s) passed in pipeline or as value.
    .PARAMETER  ComputerName
      List of computer or machine names. This list can be passed either as computer name or through pipeline.
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