Function Run-sp_WhoIsActive
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
            Write-Verbose "Running sp_WhoIsActive against $Computer.. Please wait..";
            $sessions = Invoke-Sqlcmd -ServerInstance $Computer -Database tempdb -Query 'EXEC dbo.sp_WhoIsActive @get_plans=1, @get_full_inner_text=1, @get_transaction_info=1, @get_task_info=2, @get_locks=1, @get_avg_time=1, @get_additional_info=1,@find_block_leaders=1'
        }
    }
    END {
        Write-Output $sessions;
    }
}