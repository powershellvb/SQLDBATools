Function Setup-DbaMailProfile
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('SqlInstance')]
        [String]$ServerInstance
    )

    $mailProfileTSQLScriptFile = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\DatabaseMailProfile.sql";
    try 
    {
        $instanceInfo = Fetch-ServerInfo -ComputerName $ServerInstance;
        if([String]::IsNullOrEmpty($instanceInfo))
        {
            Write-Host "Error($ServerInstance): Mentioned serverInstance is not found in Inventory." -ForegroundColor Red;
        }
        else
        {
            Invoke-Sqlcmd -ServerInstance $ServerInstance -Database msdb -InputFile $mailProfileTSQLScriptFile -ErrorAction SilentlyContinue;

            $srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server("$ServerInstance");
            $sm = $srv.Mail.Profiles | Where-Object {$_.Name -eq $ServerInstance};
            $srv.JobServer.AgentMailType = 'DatabaseMail';
            $srv.JobServer.DatabaseMailProfile = $sm.Name;
            $srv.JobServer.Alter();

            Write-Host "Success($ServerInstance): Mail profile script successfully executed. Pls check for test mail" -ForegroundColor Green;
        }
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