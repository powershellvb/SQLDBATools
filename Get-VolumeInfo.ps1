Function Get-VolumeInfo
{
    Param (
            [Alias('ServerName','MachineName')]
            [String[]]$ComputerName = $env:COMPUTERNAME
          )

    BEGIN {
    $diskInfo = @();
    }
    PROCESS {
        if ($_ -ne $null)
        {
            $ComputerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }
        foreach ($Computer in $ComputerName)
        {
            $diskInfo +=  Get-WmiObject -Class win32_volume -ComputerName $Computer -Filter "DriveType=3" | Where-Object {$_.Name -notlike '\\?\*'} |
            Select-Object -Property @{l='ComputerName';e={$_.PSComputerName}}, 
                                    @{l='VolumeName';e={$_.Name}}, 
                                    @{l='Capacity(GB)';e={$_.Capacity / 1GB -AS [INT]}},
                                    @{l='Used Space(GB)';e={($_.Capacity - $_.FreeSpace)/ 1GB -AS [INT]}},
                                    @{l='Used Space(%)';e={((($_.Capacity - $_.FreeSpace) / $_.Capacity) * 100) -AS [INT]}},
                                    @{l='FreeSpace(GB)';e={$_.FreeSpace / 1GB -AS [INT]}},
                                    Label
        }
    }
    END {
        Write-Output $diskInfo;
    }
}