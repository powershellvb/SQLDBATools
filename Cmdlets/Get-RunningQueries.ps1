Function Get-RunningQueries
{
    Param (
            [Alias('ServerName','MachineName')]
            [String[]]$ComputerName = $env:COMPUTERNAME
          )

    BEGIN {
    $sessions = @();
    }
    PROCESS {
        if ($_ -ne $null)
        {
            $ComputerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }
        foreach ($Computer in $ComputerName)
        {
            #cd $PSScriptRoot;
            Write-Verbose "Running $PSScriptRoot\WhatIsRunning.sql against $Computer.. Please wait..";
            $sessions = Invoke-Sqlcmd -ServerInstance $Computer -Database master -InputFile "$PSScriptRoot\WhatIsRunning.sql"
        }
    }
    END {
        Write-Output $sessions;
    }
}