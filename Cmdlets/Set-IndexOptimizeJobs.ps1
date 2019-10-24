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
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('Instance')]
        [String]$SqlInstance
    )

    $conn = Connect-DbaInstance -SqlInstance $SqlInstance -Database DBA;

    Write-Verbose "Scanning TSQL Script files that IndexOptimize Job creation code";
    $IndexOptimize_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\ola.hallengren.Job.IndexOptimize.sql";
    $IndexOptimize_Modified_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\ola.hallengren.Job.IndexOptimize_Modified.sql";

    if($PSCmdlet.ShouldProcess($SqlInstance)) {
        Invoke-DbaQuery -SqlInstance $conn -File @($IndexOptimize_File,$IndexOptimize_Modified_File) -ErrorAction Continue -WarningAction SilentlyContinue;
        Write-Verbose "Files '$IndexOptimize_File' & '$IndexOptimize_Modified_File' are executed successfully.";
        return 0;
    }
}