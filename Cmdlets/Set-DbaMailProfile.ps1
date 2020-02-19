Function Set-DbaMailProfile
{
<#
.SYNOPSIS
This function creates database mail account & Mail profile
.DESCRIPTION
This function creates a database mail account/Profile with below details:-
    Display name like 'SQL Alerts - @@serverName'
    Email id: 'SQLAlerts@tivo.com'
    Profile Name: @@serverName
.PARAMETER ServerInstance
Sql Server Instance on which database mail and profile are to be created
.EXAMPLE
Set-DbaMailProfile -ServerInstance 'testvm'
This command creates database mail account 'sqlalerts@tivo.com' for profile 'TESTVM' on server 'testvm'
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('ServerInstance')]
        [String]$SqlInstance
    )

    $mailProfileTSQLScriptFile = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\DatabaseMailProfile.sql";
    #Write-Verbose $mailProfileTSQLScriptFile;
    try 
    {
        if($PSCmdlet.ShouldProcess("$SqlInstance")) {
            Invoke-DbaQuery -SqlInstance $SqlInstance -Database msdb -File $mailProfileTSQLScriptFile -ErrorAction Stop;

            $srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server("$SqlInstance");
            $sm = $srv.Mail.Profiles | Where-Object {$_.Name -eq $SqlInstance};
            $srv.JobServer.AgentMailType = 'DatabaseMail';
            $srv.JobServer.DatabaseMailProfile = $sm.Name;
            $srv.JobServer.Alter();


            Write-Verbose "Success($SqlInstance): Mail profile script successfully executed. Pls check for test mail";
        }
    }
    catch
    {
        Write-Error "Error($SqlInstance): Failure while executing SQL code from file $mailProfileTSQLScriptFile";
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $ReturnMessage = @"

$FailedItem => 
    $ErrorMessage
====================================
"@
        Write-Error $ReturnMessage;
    }
}