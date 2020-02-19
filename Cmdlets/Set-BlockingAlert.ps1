function Set-BlockingAlert {
<#
.SYNOPSIS
This function creates Blocking Alert job.
.DESCRIPTION
This function creates procedure [DBA]..[usp_GetConsistentBlocking] & agent job [DBA - Blocking Alert].
.PARAMETER SqlInstance
Sql Server Instance against which Blocking alert job is to be created
.PARAMETER MailRecepients
Email ids of individuals/groups to whom notification mail should be sent. Default is 'IT-Ops-DBA@tivo.com;DSG-ProductionSupport@tivo.com'.
.PARAMETER BlockingThresholdTime_Minutes
Time in minutes for which consistant blocking is to be observed
.EXAMPLE 
Set-BlockingAlert -SqlInstance 'testvm'
The command creates job named [DBA - Blocking Alert] with default values of MailRecepients & BlockingThresholdTime_Minutes.
.EXAMPLE 
Set-BlockingAlert -SqlInstance 'testvm' -BlockingThresholdTime_Minutes 20
The command creates job named [DBA - Blocking Alert] with default values of MailRecepients & BlockingThresholdTime_Minutes.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)][Alias('Instance')]
        [String]$SqlInstance,
        
        [Parameter(Mandatory=$false)][Alias('Recepients')]
        [String]$MailRecepients = 'IT-Ops-DBA@tivo.com;DSG-ProductionSupport@tivo.com',

        [Parameter(Mandatory=$false)]
        [int]$BlockingThresholdTime_Minutes = 20
    )

    $conn = Connect-DbaInstance -SqlInstance $SqlInstance -Database DBA;

    Write-Verbose "Scanning TSQL Script files for [DBA - Blocking Alert] Job creation code";
    $BlockingAlertProcedure_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\Job.DBA.Blocking.Alert.usp_GetConsistentBlocking.sql";
    $BlockingAlertJob_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\Job.DBA.Blocking.Alert.sql";

    if($PSCmdlet.ShouldProcess($SqlInstance)) {
        Invoke-DbaQuery -SqlInstance $conn -File @($BlockingAlertProcedure_File,$BlockingAlertJob_File) -ErrorAction Continue -WarningAction SilentlyContinue;
        Write-Verbose "Files '$BlockingAlertProcedure_File' & '$BlockingAlertJob_File' are executed successfully.";
        return 0;
    }
}