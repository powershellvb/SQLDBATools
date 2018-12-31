Function Get-DatabaseBackupInfo_SMO
{
  <#
    .SYNOPSIS 
      Returns database details like db name, creation date, recovery model, last backup details for Full, differential and Log.
    .DESCRIPTION
      Returns database details like db name, creation date, recovery model, last backup details for Full, differential and Log.
    .PARAMETER  ServerInstance
      Name of SQL Server instance. This name can be passed either as parameter or pipeline value.
    .EXAMPLE
      $serverName = 'Server01';
      Get-DatabaseBackupInfo_SMO $serverName | ft -AutoSize;

      Ouput:-
ServerName    DatabaseName DatabaseCreationDate RecoveryModel LastFullBackupDate  LastDifferentialBackupDate LastLogBackupDate   CollectionTime     
----------    ------------ -------------------- ------------- ------------------  -------------------------- -----------------   --------------     
Server01      AMGMusicMore 2016-08-03 04:58:25           Full 2018-01-08 15:35:21                            2018-04-10 06:00:01 2018-04-10 16:54:15
Server01      babel        2016-08-02 16:36:37           Full 2018-01-08 15:53:06                                                2018-04-10 16:54:19
Server01      CMS          2016-06-16 03:43:22           Full 2018-01-08 15:53:09                                                2018-04-10 16:54:23
Server01      DBA          2017-01-30 13:52:03           Full 2018-02-12 01:08:11                                                2018-04-10 16:54:27
Server01      master       2003-04-08 09:13:36         Simple                                                                    2018-04-10 16:54:31
Server01      MDW          2017-12-18 03:14:44           Full 2018-01-08 15:53:12                                                2018-04-10 16:54:34
Server01      model        2003-04-08 09:13:36           Full 2018-01-08 15:53:14                                                2018-04-10 16:54:38
Server01      msdb         2010-04-02 17:35:08         Simple                                                                    2018-04-10 16:54:42
Server01      Pandey       2016-08-12 06:32:41           Full 2018-01-08 15:53:16                            2018-04-10 06:00:01 2018-04-10 16:54:46
Server01      repl_test    2016-08-04 01:49:31           Full 2018-01-08 15:53:18                                                2018-04-10 16:54:50
Server01      SQLDBATools  2018-02-21 04:10:58           Full 2018-04-09 00:59:18                                                2018-04-10 16:54:54
Server01      Staging2     2016-08-31 07:58:05         Simple 2016-08-30 22:36:10                                                2018-04-10 16:54:57
Server01      testing      2017-07-20 08:15:21           Full 2018-01-08 15:53:20                                                2018-04-10 16:55:02
      
      Server name passed as parameter. Returns backup information for sql server instance Server01.

    .EXAMPLE
      $serverName = 'Server01';
      $serverName | Get-DatabaseBackupInfo_SMO | ft -AutoSize;

      Output:-
ServerName    DatabaseName DatabaseCreationDate RecoveryModel LastFullBackupDate  LastDifferentialBackupDate LastLogBackupDate   CollectionTime     
----------    ------------ -------------------- ------------- ------------------  -------------------------- -----------------   --------------     
Server01      AMGMusicMore 2016-08-03 04:58:25           Full 2018-01-08 15:35:21                            2018-04-10 06:00:01 2018-04-10 16:54:15
Server01      babel        2016-08-02 16:36:37           Full 2018-01-08 15:53:06                                                2018-04-10 16:54:19
Server01      CMS          2016-06-16 03:43:22           Full 2018-01-08 15:53:09                                                2018-04-10 16:54:23
Server01      DBA          2017-01-30 13:52:03           Full 2018-02-12 01:08:11                                                2018-04-10 16:54:27
Server01      master       2003-04-08 09:13:36         Simple                                                                    2018-04-10 16:54:31
Server01      MDW          2017-12-18 03:14:44           Full 2018-01-08 15:53:12                                                2018-04-10 16:54:34
Server01      model        2003-04-08 09:13:36           Full 2018-01-08 15:53:14                                                2018-04-10 16:54:38
Server01      msdb         2010-04-02 17:35:08         Simple                                                                    2018-04-10 16:54:42
Server01      Pandey       2016-08-12 06:32:41           Full 2018-01-08 15:53:16                            2018-04-10 06:00:01 2018-04-10 16:54:46
Server01      repl_test    2016-08-04 01:49:31           Full 2018-01-08 15:53:18                                                2018-04-10 16:54:50
Server01      SQLDBATools  2018-02-21 04:10:58           Full 2018-04-09 00:59:18                                                2018-04-10 16:54:54
Server01      Staging2     2016-08-31 07:58:05         Simple 2016-08-30 22:36:10                                                2018-04-10 16:54:57
Server01      testing      2017-07-20 08:15:21           Full 2018-01-08 15:53:20                                                2018-04-10 16:55:02
      
      Server name passed through pipeline. Returns backup information for sql server instance Server01.

    .LINK
      https://github.com/imajaydwivedi/SQLDBATools
  #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','SQLInstance')]
        [String]$ServerInstance = $env:COMPUTERNAME
    )

    BEGIN 
    {
        $Result = @();
    }

    PROCESS 
    {
    
        if ($ServerInstance -eq "")
        {
            Write-Error 'Invalid Value for ServerInstance parameter';
        }
        else 
        {
        
            $errorFile = "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo\$($ServerInstance -replace '\\','__').txt";
        
            Push-Location;
            try 
            {
                # Get Database properties
                [String] $IsLoaded = Get-PSProvider |
                         Select-Object Name |
                         Where-Object { $_ -match "Sql*" }

                if ($IsLoaded.Length -eq 0) { [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null; }
                $s = New-Object ('Microsoft.SqlServer.Management.Smo.Server') "$ServerInstance";

                $s.Databases | Where-Object {$_.Name -ne 'tempdb'; $_.Refresh()} |  
                Select-Object @{Label="ServerName"; Expression={ $_.Parent -replace '[[\]]',''}}, 
                            @{l='DatabaseName';e={$_.Name}}, 
                            @{l='DatabaseCreationDate';e={IF ($_.CreateDate -eq "01/01/0001 00:00:00") {$null} else {($_.CreateDate).ToString("yyyy-MM-dd HH:mm:ss")}}}, 
                            RecoveryModel, 
                            @{l='LastFullBackupDate';e={IF ($_.LastBackupDate -eq "01/01/0001 00:00:00") {$null} else {($_.LastBackupDate).ToString("yyyy-MM-dd HH:mm:ss")}}}, 
                            @{l='LastDifferentialBackupDate';e={IF ($_.LastDifferentialBackupDate -eq "01/01/0001 00:00:00") {$null} else {($_.LastDifferentialBackupDate).ToString("yyyy-MM-dd HH:mm:ss")}}},  
                            @{l='LastLogBackupDate';e={IF ($_.LastLogBackupDate -eq "01/01/0001 00:00:00") {$null} else {($_.LastLogBackupDate).ToString("yyyy-MM-dd HH:mm:ss")}}},
                            @{l='CollectionTime';e={(Get-Date).ToString("yyyy-MM-dd HH:mm:ss")}}
            }
            catch 
            {
                $ErrorMessage = $_.Exception.Message;
                $FailedItem = $_.Exception.ItemName;
            
                # Create if Error Log path does not exist
                if ( (Test-Path "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo") -eq $false) 
                {
                    New-Item "$SQLDBATools_ResultsDirectory\Logs\Get-DatabaseBackupInfo" -ItemType directory;
                }

                # Drop old error log file
                if (Test-Path $errorFile) 
                {
                    Remove-Item $errorFile;
                }

                $ErrorMessage | Out-File $errorFile;
                Write-Verbose "Error occurred while trying to get BackupInfo for server [$ServerInstance]. Kindly check logs at $errorFile";
            }
               
            Pop-Location;
        }
    }
}