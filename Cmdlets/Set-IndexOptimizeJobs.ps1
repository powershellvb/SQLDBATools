function Set-IndexOptimizeJobs {
<#
.SYNOPSIS
This function creates four IndexOptimize jobs.
.DESCRIPTION
This function creates 3 parallel jobs for all databases except Staging/IDS using ola IndexOptimize procedure.
Also creates 1 job for Staging/IDS databases that are to be run in Serial manner using IndexOptimize_Modified procedure.
.PARAMETER SqlInstance
Sql Server Instance against which IndexOptimize jobs are to be created    
.EXAMPLE
Set-IndexOptimizeJobs -SqlInstance 'testvm'
The command creates 3 parallel IndexOptimize & 1 IndexOptimize_Modified jobs on server 'testvm'.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('Instance')]
        [String]$SqlInstance
    )

    $conn = Connect-DbaInstance -SqlInstance $SqlInstance -Database DBA;
    $IndexOptimize_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\ola.hallengren.Job.IndexOptimize.sql";
    $IndexOptimize_Modified_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\ola.hallengren.Job.IndexOptimize_Modified.sql";
    Invoke-DbaQuery -SqlInstance $conn -File @($IndexOptimize_File,$IndexOptimize_Modified_File) -ErrorAction Continue;

    Write-Host "Files '$IndexOptimize_File' & '$IndexOptimize_Modified_File' are executed successfully.";
}