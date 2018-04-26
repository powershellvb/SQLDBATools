#Get-ProcessForDBA
function Get-ProcessForDBA
{
   <#
    .SYNOPSIS 
      Displays memory and other important information for all processes of Server name(s) passed as parameter.
    .DESCRIPTION
      Displays ComputerName, ProcessId, ProcessName, Description, StartTime, Threads, Memory(MB), Path, Company, Product for all processes of Server name(s) passed as parameter.
    .PARAMETER  ComputerName
      List of computer or machine names. This list can be passed either as computer name or through pipeline.
    .PARAMETER  CPU
      When this switch is used, then CPU is also provided in resultset.
    .EXAMPLE
      Get-ProcessForDBA -ComputerName $env:COMPUTERNAME | Format-Table -AutoSize;

      Ouput:-
ComputerName       Id ProcessName                     Description                                                         StartTime             Threads                            Memory(MB) Path                                 
------------       -- -----------                     -----------                                                         ---------             -------                            ---------- ----                                 
BAN-2ADWIVEDI-L  7924 AccelerometerSt                 Hp Accelerometer System Tray                                        4/19/2018 8:30:18 AM  {7928}                             3.94140625 C:\Program Files (x86)\Hewlett-Pac...
BAN-2ADWIVEDI-L  2672 armsvc                          Adobe Acrobat Update Service                                        4/19/2018 8:27:29 AM  {2676, 2700, 2708, 2900...}        4.51953125 C:\Program Files (x86)\Common File...
BAN-2ADWIVEDI-L  8868 audiodg                                                                                             4/20/2018 3:07:09 PM  {15488, 15696, 6148, 9876...}     33.44140625                                      
BAN-2ADWIVEDI-L  7652 Balloon32                       McAfee Data Protection Notification                                 4/19/2018 8:30:18 AM  {7656, 7664, 7668}                     5.5625 C:\Program Files\McAfee\Endpoint E...
BAN-2ADWIVEDI-L  5164 CcmExec                         Host Process for Microsoft Configuration Manager                    4/19/2018 8:29:41 AM  {3492, 3512, 2272, 5504...}        53.3828125 C:\Windows\CCM\CcmExec.exe           
BAN-2ADWIVEDI-L  1500 chrome                          Google Chrome                                                       4/19/2018 7:54:34 PM  {14684, 14108, 11772, 2860...}  4729.66015625 C:\Program Files (x86)\Google\Chro...
BAN-2ADWIVEDI-L  4832 CmRcService                     Configuration Manager Remote Control Service                        4/19/2018 8:29:41 AM  {4680, 5516, 3708, 5440...}        9.43359375 C:\Windows\CCM\RemCtrl\CmRcService...
BAN-2ADWIVEDI-L  2188 conhost                         Console Window Host                                                 4/19/2018 8:27:28 AM  {2196}                            27.06640625 C:\Windows\system32\conhost.exe      
BAN-2ADWIVEDI-L   620 csrss                           Client Server Runtime Process                                       4/19/2018 8:27:16 AM  {652, 656, 660, 664...}           130.1015625 C:\Windows\system32\csrss.exe        
BAN-2ADWIVEDI-L  2800 CxMonSvc                        CxMonSvc                                                            4/19/2018 8:27:29 AM  {2804, 2816, 2820, 2824...}        14.0234375 C:\Windows\CxSvc\CxMonSvc.exe        
BAN-2ADWIVEDI-L  2888 CxUtilSvc                       Utility Service                                                     4/19/2018 8:27:30 AM  {2892, 2904, 2908, 2164...}        5.57421875 C:\Windows\CxSvc\CxUtilSvc.exe       
BAN-2ADWIVEDI-L   968 CylanceSvc                      Cylance Native Agent                                                4/19/2018 8:27:17 AM  {972, 996, 1000, 1004...}          70.1171875 C:\Program Files\Cylance\Desktop\C...
BAN-2ADWIVEDI-L  7964 CylanceUI                       Cylance Protect                                                     4/19/2018 8:30:19 AM  {7968, 7996, 8000, 8004...}         3.2109375 C:\Program Files\Cylance\Desktop\C...
BAN-2ADWIVEDI-L  6132 devmonsrv                       Bluetooth Device Monitor                                            4/19/2018 8:29:40 AM  {5340, 5344, 5608, 5576...}                 9 C:\Program Files (x86)\Intel\Bluet...
BAN-2ADWIVEDI-L 16120 dnscrypt-proxy                  Cisco DNS Proxy                                                     4/21/2018 10:29:38 AM {13388}                            5.57421875 C:\Program Files (x86)\OpenDNS\Umb...
BAN-2ADWIVEDI-L  7240 dwm                             Desktop Window Manager                                              4/19/2018 8:30:15 AM  {7244, 7260, 7264, 12656...}      48.80859375 C:\Windows\system32\Dwm.exe          
BAN-2ADWIVEDI-L  7596 EpePcMonitor                    McAfee Drive Encryption Monitor                                     4/19/2018 8:30:17 AM  {7600, 7604, 7608, 7644...}           7.71875 C:\Program Files\McAfee\Endpoint E...
BAN-2ADWIVEDI-L  4248 ERCService                      Umbrella RC Service                                                 4/19/2018 8:27:35 AM  {4252, 4296, 4300, 4316...}        46.0078125 C:\Program Files (x86)\OpenDNS\Umb...
BAN-2ADWIVEDI-L  2948 EvtEng                          Intel(R) PROSet/Wireless Event Log Service                          4/19/2018 8:27:30 AM  {2952, 2964, 2968, 2976...}       27.71484375 c:\Program Files\Intel\WiFi\bin\Ev...
BAN-2ADWIVEDI-L  7276 explorer                        Windows Explorer                                                    4/19/2018 8:30:15 AM  {7280, 7288, 7316, 7320...}         103.53125 C:\Windows\Explorer.EXE              

      Returns information about processes on current machine.
    .EXAMPLE
      PS C:\> Get-ProcessForDBA -ComputerName $env:COMPUTERNAME | Where-Object {$_.Description -like "*sql*"} | ft -AutoSize

ComputerName      Id ProcessName Description                                StartTime            Threads                          Memory(MB) Path
------------      -- ----------- -----------                                ---------            -------                          ---------- ----                                                                                 
BAN-2ADWIVEDI-L 5552 fdhost      SQL Full Text host                         4/19/2018 8:27:41 AM {5556, 5620, 5628, 5632...}       5.9609375 C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\fdhost.exe      
BAN-2ADWIVEDI-L 3944 fdlauncher  SQL Full-text Filter Daemon Launch Service 4/19/2018 8:27:39 AM {4192, 5132, 4396, 13796}        4.43359375 C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\fdlauncher.exe  
BAN-2ADWIVEDI-L 4848 SQLAGENT    SQLAGENT - SQL Server Agent                4/19/2018 8:27:39 AM {4852, 5000, 5028, 5036...}        17.34375 C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\SQLAGENT.EXE    
BAN-2ADWIVEDI-L 3728 sqlbrowser  SQL Browser Service EXE                    4/19/2018 8:27:32 AM {3732, 3760, 3768, 3772...}       5.3828125 C:\Program Files (x86)\Microsoft SQL Server\90\Shared\sqlbrowser.exe                 
BAN-2ADWIVEDI-L 3400 sqlservr    SQL Server Windows NT - 64 Bit             4/19/2018 8:27:31 AM {3404, 3664, 3700, 3956...}     274.9453125 C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Binn\sqlservr.exe    
BAN-2ADWIVEDI-L 3796 sqlwriter   SQL Server VSS Writer - 64 Bit             4/19/2018 8:27:32 AM {3800, 3812, 3836, 14248...}      7.0546875 C:\Program Files\Microsoft SQL Server\90\Shared\sqlwriter.exe                        
BAN-2ADWIVEDI-L 6312 Ssms        SQL Server Management Studio               4/20/2018 8:34:13 AM {7648, 12620, 15436, 14308...} 985.37890625 C:\Program Files (x86)\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Ssms.exe 

      
      Returns information about processes with keywork *sql* in their description on current machine.

    .EXAMPLE
      PS C:\> Get-ProcessForDBA -ComputerName $env:COMPUTERNAME | Out-GridView

      Gets all processes from current computer in Grid View.

    .LINK
      https://github.com/imajaydwivedi/SQLDBATools
  #>
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName')]
        [String[]]$ComputerName = $env:COMPUTERNAME,

        [parameter( Mandatory=$false)]
        [Switch]$CPU = $false
    )

    BEGIN 
    {
        $processDetails = @();
    }
    PROCESS 
    {

        foreach ($Comp in $ComputerName)
        {
            Write-Host "Finding Process details for ComputerName: $Comp" -ForegroundColor Green;
            $processes = Get-Process -ComputerName $Comp;
            # If -Verbose switch is used
            if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) { $processes | Select-Object * | Out-GridView; }
            # Get Process Names
            $processNames = @($processes | Select-Object Name -Unique | Select-Object -ExpandProperty Name);
            # To match the CPU usage to for example Process Explorer you need to divide by the number of cores
            $cpu_cores = (Get-WMIObject Win32_ComputerSystem -ComputerName $Comp).NumberOfLogicalProcessors;
            if($CPU) {
                $Counters = (Get-Counter "\Process(*)\ID Process" -ComputerName $Comp -ErrorAction SilentlyContinue).CounterSamples;
                # If -Verbose switch is used
                if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) { $Counters | ft -AutoSize; }
            }

            foreach($proc in $processNames)
            {
                Write-Verbose "
            Finding details of process '$proc'";
                # Get Process Details
                $p = $processes | Where-Object {$_.Name -eq $proc} | Select-Object MachineName, Id, ProcessName, Description, StartTime, Threads, @{l='WS';e={if([String]::IsNullOrEmpty($_.WorkingSet64)) {$_.WorkingSet}else{$_.WorkingSet64}}}, @{l='VM';e={if([String]::IsNullOrEmpty($_.VirtualMemorySize64)){$_.VirtualMemorySize}else{$_.VirtualMemorySize64}}}, CPU, Path, Company, Product -First 1;
                # Get Sum of Workingset Memory for Process
                $processMemoryMB = ($processes | Where-Object {$_.Name -eq $proc} | Measure-Object WS -Sum).Sum/1MB;
                # Get Sum of Virtual Memory for Process
                $virtualMemoryMB = ($processes | Where-Object {$_.Name -eq $proc} | Measure-Object VM -Sum).Sum/1MB;
                #Write-Verbose "`$processMemory = $processMemory";
                $MachineName = if($p.MachineName -eq '.'){$Comp}else{$p.MachineName};

                $cpuPercentage = 0;
                $pIds = @($processes | Where-Object {$_.Name -eq $proc} | Select-Object -ExpandProperty Id);
                Write-Verbose "    Process Ids for process '$proc' are $($pIds -join ',')";
                if($CPU -and $pIds.Count -ne 0) 
                {
                    Write-Verbose "  Calculating CPU(%) for process $proc";
                    foreach ($proc_pid in $pIds)
                    {
                        # This is to find the exact counter path, as you might have multiple processes with the same name
                        $proc_path = ($Counters | Where-Object {$_.RawValue -eq $proc_pid}).Path;
                        # We now get the CPU percentage
                        if ([String]::IsNullOrEmpty($proc_path) -eq $false) 
                        {
                            $prod_percentage_cpu = [Math]::Round(((Get-Counter ($proc_path -replace "\\id process$","\% Processor Time")).CounterSamples.CookedValue) / $cpu_cores);
                            $cpuPercentage += $prod_percentage_cpu;
                        } else 
                        {
                            Write-Verbose "    Counter for `$proc_pid = $proc_pid is not found";
                        }
                    }
                }

                if ([String]::IsNullOrEmpty($cpuPercentage)) {
                    Write-Verbose "No CPU utilization found for process $proc.";
                    $cpuPercentage = 0;
                }

                $prop = [Ordered]@{
                            'ComputerName'= $MachineName;
                            'Id' = $p.Id;
                            'ProcessName' = $p.ProcessName;
                            'Description' = $p.Description;
                            'StartTime' = $p.StartTime;
                            'Threads' = $p.Threads;
                            'Memory(MB)' = $processMemoryMB;
                            'VirtualMemory(MB)' = [bigint]$virtualMemoryMB;
                            'VirtualMemory(GB)' = [bigint]$virtualMemoryMB/1024;
                            'CPU(%)' = [int]$cpuPercentage;
                            'Path' = $p.Path;
                            'Company' = $p.Company;
                            'Product' = $p.Product;
                        }
                $obj = New-Object -TypeName psobject -Property $prop;
                $processDetails += $obj;
            }
        }
    }
    END 
    {
        if ($CPU) {
            $processDetails | Sort-Object -Property 'Memory(MB)' -Descending | Select-Object ComputerName,Id,ProcessName,Description,StartTime,Threads,'Memory(MB)','VirtualMemory(MB)','VirtualMemory(GB)','CPU(%)',Path,Company,Product | Write-Output;
        } else {
            $processDetails | Sort-Object -Property 'Memory(MB)' -Descending | Select-Object ComputerName,Id,ProcessName,Description,StartTime,Threads,'Memory(MB)','VirtualMemory(MB)','VirtualMemory(GB)',Path,Company,Product | Write-Output;
        }
    }
}
