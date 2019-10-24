function Set-DatabaseBackupJobs {
<#
.SYNOPSIS
This function creates Full & Log DatabaseBackup jobs using Ola.
.DESCRIPTION
This function creates one Full backup job for all databases and one Log Backup job for User Databases using Ola Hallengren Maintenance solution.
.PARAMETER SqlInstance
Sql Server Instance against which DatabaseBackup jobs are to be created    
.EXAMPLE
Set-DatabaseBackupJobs -SqlInstance 'testvm'
The command creates Full & Log DatabaseBackup jobs on server 'testvm'.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('Instance')]
        [String]$SqlInstance
    )

    $conn = Connect-DbaInstance -SqlInstance $SqlInstance;
    $ServerName = $SqlInstance.Split('\')[0];

    Write-Verbose "Scanning TSQL Script files that DatabaseBackup Job creation code";
    $DatabaseBackupFull_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\ola.hallengren.Job.DatabaseBackup.FULL.sql";
    $DatabaseBackupLog_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\ola.hallengren.Job.DatabaseBackup.LOG.sql";

    $BackupPath = $conn.BackupDirectory;

    $DatabaseBackupFull_Query = (Get-Content $DatabaseBackupFull_File | Out-String).Replace("SqlInstanceDefaultBackupDirectory","$BackupPath\FULL");
    $DatabaseBackupLog_Query = (Get-Content $DatabaseBackupLog_File | Out-String).Replace("SqlInstanceDefaultBackupDirectory","$BackupPath\LOG");

    if($PSCmdlet.ShouldProcess($SqlInstance)) {
        Invoke-Command -ComputerName $ServerName -ScriptBlock {
                            New-Item -Path $Using:BackupPath -Name "FULL" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null;
                            New-Item -Path $Using:BackupPath -Name "LOG" -ItemType "directory" -ErrorAction SilentlyContinue | Out-Null;
                        }
        Invoke-DbaQuery -SqlInstance $conn -Query $DatabaseBackupFull_Query -Database msdb -ErrorAction Continue #-WarningAction SilentlyContinue;
        Invoke-DbaQuery -SqlInstance $conn -Query $DatabaseBackupLog_Query -Database msdb -ErrorAction Continue #-WarningAction SilentlyContinue;
        Write-Verbose "Jobs [DBA DatabaseBackup - ALL_DATABASES - FULL] and [DBA DatabaseBackup - USER_DATABASES - LOG] are created successfully.";
        return 0;
    }
}