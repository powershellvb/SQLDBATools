Function Get-ServerInfo
{
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
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName')]
        [String[]]$ComputerName = $env:COMPUTERNAME
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

        foreach ($Comp in $ComputerName)
        {
            $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $comp -ErrorAction SilentlyContinue;
            $cs = Get-WmiObject -Class win32_computersystem -ComputerName $comp -ErrorAction SilentlyContinue;
            #$bt = (Get-CimInstance -ClassName win32_operatingsystem  -ComputerName $comp -ErrorAction SilentlyContinue | select lastbootuptime);
        
            if ($os.LastBootUpTime) 
            {
                $upTime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime);
                $lastBoot = $os.ConvertToDateTime($os.LastBootUpTime);
            }

            $props = [Ordered]@{ 'ComputerName'=$comp;
                        'OS'=$os.Caption;
                        'SPVersion'=$os.CSDVersion;
                        'LastBootTime'=$lastBoot;
                        'UpTime'= [String]$uptime.Days + " Days " + $uptime.Hours + " Hours " + $uptime.Minutes + " Minutes" ;
                        #'Mfgr'=$cs.manufacturer;
                        'Model'=$cs.Model;
                        'RAM(GB)'=$cs.totalphysicalmemory/1GB -AS [int];
                        'CPU'=$cs.NumberOfLogicalProcessors;
                      }

            $obj = New-Object -TypeName psobject -Property $props;
            $Result += $obj;
        }
    }
    END 
    {
        Write-Output $Result;
    }
}