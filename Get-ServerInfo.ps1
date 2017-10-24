Function Get-ServerInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName')]
        [String[]]$ComputerName = $env:COMPUTERNAME
    )

    $Result = @();

    foreach ($comp in $ComputerName)
    {
        $os = Get-WmiObject -Class win32_operatingsystem -ComputerName $comp
        $cs = Get-WmiObject -Class win32_computersystem -ComputerName $comp
        $bt = (Get-CimInstance -ClassName win32_operatingsystem  -ComputerName $comp | select lastbootuptime);

        $props = [Ordered]@{ 'ComputerName'=$comp;
                    'OS'=$os.Caption;
                    'SPVersion'=$os.CSDVersion;
                    'LastBootTime'=$bt.LastBootUpTime;
                    #'Mfgr'=$cs.manufacturer;
                    'Model'=$cs.Model;
                    'RAM(MB)'=$cs.totalphysicalmemory/1MB -AS [int];
                    'CPU'=$cs.NumberOfLogicalProcessors;
                  }
        
        $obj = New-Object -TypeName psobject -Property $props;
        #Write-Output $obj
        $Result += $obj;
    }
    Write-Output $Result;
}