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
        $Result = @();
    }
    PROCESS 
    {
        if ($_ -ne $null)
        {
            $ComputerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }
        foreach ($Computer in $ComputerName)
        {
            $Disks = @();
            $Volumes = @();
            $Partitions = @();
            $DiskVolumeInfo = @();

           $Volumes =  Get-WmiObject -Class win32_volume -ComputerName $Computer -Filter "DriveType=3" | Where-Object {$_.Name -notlike '\\?\*'} |                    
                    Select-Object -Property @{l='ComputerName';e={$_.PSComputerName}}, 
                                            @{l='VolumeName';e={$_.Name}}, 
                                            @{l='Capacity(GB)';e={$_.Capacity / 1GB -AS [INT]}},
                                            @{l='BlockSize(KB)';e={$_.BlockSize / 1KB -AS [INT]}},
                                            @{l='Used Space(GB)';e={($_.Capacity - $_.FreeSpace)/ 1GB -AS [INT]}},
                                            @{l='Used Space(%)';e={((($_.Capacity - $_.FreeSpace) / $_.Capacity) * 100) -AS [INT]}},
                                            @{l='FreeSpace(GB)';e={$_.FreeSpace / 1GB -AS [INT]}},
                                            Label;

            

            $Disks = Get-WmiObject -Class win32_DiskDrive -ComputerName $Computer | 
                                Select-Object -Property @{l='Is_SAN_Disk';e={if(($_.PNPDeviceID).Split('\')[0] -in @('SCSI')){'No'}else{'Yes'}}}, @{l='DiskID';e={[int32]($_.Index)}},@{l='DiskModel';e={$_.Model}},@{l='LUN';e={$_.SCSILogicalUnit}};

            $Partitions = Get-WmiObject -Class win32_LogicalDiskToPartition -ComputerName $Computer | 
                                Select-Object @{l='DiskID';e={if($_.Antecedent -match "Win32_DiskPartition.DeviceID=`"Disk\s#(?'DiskID'\d{1,3}),\sPartition\s#(?'PartitionNo'\d{1,3})") {$Matches['DiskID']} else {$null} }}, 
                                              @{l='PartitionNo';e={if($_.Antecedent -match "Win32_DiskPartition.DeviceID=`"Disk\s#(?'DiskID'\d{1,3}),\sPartition\s#(?'PartitionNo'\d{1,3})") {$Matches['PartitionNo']} else {$null} }}, 
                                              @{l='VolumeName';e={if($_.Dependent -match "Win32_LogicalDisk.DeviceID=`"(?'VolumeName'[a-zA-Z]:)`"") {$Matches['VolumeName']+'\'} else {$null} }}
                            
            $VolPart = Join-Object -Left $Volumes -Right $Partitions -LeftJoinProperty VolumeName -RightJoinProperty VolumeName -Type AllInLeft -RightProperties @{l='DiskID';e={[int32]($_.DiskID)}},PartitionNo;
            $DiskVolumeInfo = Join-Object -Left $VolPart -Right $Disks  -LeftJoinProperty DiskID -RightJoinProperty DiskID -Type AllInLeft -RightProperties Is_SAN_Disk, LUN, DiskModel

            foreach ($diskInfo in $DiskVolumeInfo)
            {
                $props = [Ordered]@{ 'ComputerName'=$diskInfo.ComputerName;
                                    'VolumeName'= $diskInfo.VolumeName;
                                    'Capacity(GB)'= $diskInfo.'Capacity(GB)';
                                    'Block Size(KB)'=$diskInfo.'BlockSize(KB)';
                                    'Used Space(GB)'= $diskInfo.'Used Space(GB)';
                                    'Used Space(%)'= $diskInfo.'Used Space(%)';
                                    'FreeSpace(GB)'= $diskInfo.'FreeSpace(GB)';
                                    'Label'=$diskInfo.Label;
                                    'Is_SAN_Disk' = $diskInfo.Is_SAN_Disk;
                                    'DiskID'=$diskInfo.DiskID;
                                    'LUN'=$diskInfo.LUN;
                                    'DiskModel'=$diskInfo.DiskModel;
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