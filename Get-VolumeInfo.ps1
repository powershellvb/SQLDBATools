Function Get-VolumeInfo
{
  <#
    .SYNOPSIS 
      Displays all disk drives for computer(s) passed in pipeline or as value
    .DESCRIPTION
      This function return list of disk drives including mounted volumes with details like total size, free space, % used space etc.
    .PARAMETER  ComputerName
      List of computer or machine names. This list can be passed either as computer name or through pipeline.
    .EXAMPLE
      $servers = 'Server01','Server02';
      Get-VolumeInfo $servers | ft -AutoSize;

      Ouput:-
ComputerName  VolumeName Capacity(GB) Used Space(GB) Used Space(%) FreeSpace(GB)
------------  ---------- ------------ -------------- ------------- -------------
Server01      G:\                 559            417            75           142
Server01      C:\                  68             60            88             8
Server01      E:\                 931            273            29           658
Server01      F:\                4488           2662            59          1826
Server02      C:\                 136             61            45            75
Server02      E:\                 279             77            28           202
Server02      F:\                1003            863            86           140
Server02      G:\                 674            483            72           191
      
      Server names passed as parameter. Returns all the disk drives for computers Server01 & Server02.
    .EXAMPLE
      $servers = 'Server01','Server02';
      $servers | Get-VolumeInfo | ft -AutoSize;

      Output:-
ComputerName  VolumeName Capacity(GB) Used Space(GB) Used Space(%) FreeSpace(GB)
------------  ---------- ------------ -------------- ------------- -------------
Server01      G:\                 559            417            75           142
Server01      C:\                  68             60            88             8
Server01      E:\                 931            273            29           658
Server01      F:\                4488           2662            59          1826
Server02      C:\                 136             61            45            75
Server02      E:\                 279             77            28           202
Server02      F:\                1003            863            86           140
Server02      G:\                 674            483            72           191
      
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
        Write-Host "Inside Begin Block";
        $Result = @();
    }
    PROCESS 
    {
        Write-Host "Inside PROCESS Block";
        if ($_ -ne $null)
        {
            $ComputerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }
        foreach ($Computer in $ComputerName)
        {
           $diskDrives =  Get-WmiObject -Class win32_volume -ComputerName $Computer -Filter "DriveType=3" | Where-Object {$_.Name -notlike '\\?\*'} |
            Select-Object -Property @{l='ComputerName';e={$_.PSComputerName}}, 
                                    @{l='VolumeName';e={$_.Name}}, 
                                    @{l='Capacity(GB)';e={$_.Capacity / 1GB -AS [INT]}},
                                    @{l='Used Space(GB)';e={($_.Capacity - $_.FreeSpace)/ 1GB -AS [INT]}},
                                    @{l='Used Space(%)';e={((($_.Capacity - $_.FreeSpace) / $_.Capacity) * 100) -AS [INT]}},
                                    @{l='FreeSpace(GB)';e={$_.FreeSpace / 1GB -AS [INT]}},
                                    Label;
            foreach ($diskInfo in $diskDrives)
            {
                $props = [Ordered]@{ 'ComputerName'=$diskInfo.ComputerName;
                                    'VolumeName'= $diskInfo.VolumeName;
                                    'Capacity(GB)'= $diskInfo.'Capacity(GB)';
                                    'Used Space(GB)'= $diskInfo.'Used Space(GB)';
                                    'Used Space(%)'= $diskInfo.'Used Space(%)';
                                    'FreeSpace(GB)'= $diskInfo.'FreeSpace(GB)';
                                  };

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