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
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('SqlInstance')]
        [String]$ServerInstance
    )

    $mailProfileTSQLScriptFile = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\DatabaseMailProfile.sql";
    Write-Verbose "Server name: $ServerInstance";
    Write-Verbose $mailProfileTSQLScriptFile;
    try 
    {
        Invoke-DbaQuery -ServerInstance $ServerInstance -Database msdb -InputFile $mailProfileTSQLScriptFile -ErrorAction Stop;

        $srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server("$ServerInstance");
        $sm = $srv.Mail.Profiles | Where-Object {$_.Name -eq $ServerInstance};
        $srv.JobServer.AgentMailType = 'DatabaseMail';
        $srv.JobServer.DatabaseMailProfile = $sm.Name;
        $srv.JobServer.Alter();

        Write-Host "Success($ServerInstance): Mail profile script successfully executed. Pls check for test mail" -ForegroundColor Green;
    }
    catch
    {
        Write-Host "Error($ServerInstance): Failure while executing SQL code from file $mailProfileTSQLScriptFile" -ForegroundColor Red;
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName

        @"

$FailedItem => 
    $ErrorMessage
====================================
"@
    }
}