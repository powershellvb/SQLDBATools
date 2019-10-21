function Set-ServerState {
<#
    .SYNOPSIS
    This function provides options to LogOff, Reboot & Shutdown local or remote Server.
    .DESCRIPTION
    This function helps to LogOff, ShutDown, Reboot local or remote Server. Support Force option to skip the notification for application/users.
    .PARAMETER ServerName
    Accepts ComputerName to perform action on.
    .PARAMETER Reboot
    Perform Reboot of Server
    .PARAMETER Shutdown
    Perform Shutdown action on Server
    .PARAMETER LogOff
    Perform LogOff for current user on Server
    .PARAMETER Force
    Perform action with Force option to skip notification to application & users.
    .EXAMPLE
    Set-ServerState -ServerName 'testserver' -Reboot -Force -Confirm:$false
    Perform reboot on server 'testserver' skipping notification for applications & users. Also, don't ask for confirmation.
    .EXAMPLE
    Set-ServerState -ServerName 'testserver' -Shutdown -Force
    Perform shutdown on server 'testserver' skipping notification for applications & users
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$True, ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias("ComputerName","MachineName")]
        [string]$ServerName,

        [Parameter(Mandatory=$false, ParameterSetName="Reboot")]
        [Switch]$Reboot,

        [Parameter(Mandatory=$false, ParameterSetName="Shutdown")]
        [Switch]$Shutdown,

        [Parameter(Mandatory=$false, ParameterSetName="LogOff")]
        [Switch]$LogOff,

        [Parameter(Mandatory=$false)]
        [Switch]$Force
    )

    $ActionVal = 0;
    $Action = $null;
    if($LogOff) {$ActionVal = 0; $Action = 'LogOff'}    
    if($Shutdown) {$ActionVal = 1; $Action = 'Shutdown'}
    if($Reboot) {$ActionVal = 2; $Action = 'Reboot'}
    if($Force) {$ActionVal += 4; $Action = "Forced $Action"}

    $win32OS = get-wmiobject win32_operatingsystem -computername $ServerName -EnableAllPrivileges;
    if($PSCmdlet.ShouldProcess("[$ServerName] with '$Action' action")) {
        $win32OS.win32shutdown($ActionVal) | Out-Null;
    }
}