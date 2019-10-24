function Install-OlaHallengrenMaintenanceScripts {
<#
    .SYNOPSIS
        This function compiles all scripts/objects required for Ola Hallengren Maintenance solution

    .DESCRIPTION
        This function compiles all scripts/objects like DatabaseBackup, DatabaseIntegrityCheck, IndexOptimize procedures required for Ola Hallengren Maintenance solution. 
        Also, we are putting updated scripts for DatabaseBackup & IndexOptimize_Modified procedures.

    .PARAMETER SqlInstance
        Sql Server Instance on which all scripts/objects of Ola Hallengren Maintenance solution are to be created

    .EXMAPLE
        Install-OlaHallengrenMaintenanceScripts -SqlInstance 'testvm'

        This command creates all scripts/objects of Ola Hallengren Maintenance solution on server 'testvm'

    .LINK
        https://github.com/imajaydwivedi/SQLDBATools

#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias('ServerInstance')]
        [string]$SqlInstance
    )
    $srv = Connect-DbaInstance -SqlInstance $SqlInstance -Database DBA

    if($PSCmdlet.ShouldProcess($SqlInstance)) {
        Write-Verbose "Scanning required Ola Hallengren Maintenance Solution scripts on disk";
        $All_Scripts = (Get-Module -Name SQLDBATools -ListAvailable).ModuleBase + "\SQLQueries\ola.hallengren.MaintenanceSolution.sql";
        Invoke-DbaQuery -SqlInstance $srv -File $All_Scripts -Database 'DBA'; 
    
        $Modified_Scripts = (Get-Module -Name SQLDBATools -ListAvailable).ModuleBase + "\SQLQueries\ola.hallengren.IndexOptimize_Modified.sql";
        Invoke-DbaQuery -SqlInstance $srv -File $Modified_Scripts -Database 'DBA';

        Write-Verbose "Ola Hallengren Scripts compiled successfully on [DBA] database";
        return 0;
    }
}
